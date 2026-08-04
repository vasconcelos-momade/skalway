# Schema Central — Billing, Pagamentos e SaaS

Documentação das decisões do schema `central/schema.prisma` para faturação multi-tenant.

**API REST implementada:** [api-central-billing.md](./api-central-billing.md)

## O que está sólido

| Área | Decisão |
|------|---------|
| **BillingSnapshot** | Histórico imutável por período; suporta mudança de preços e auditoria. |
| **Invoice ≠ Payment** | Uma fatura pode ter vários pagamentos; pagamentos parciais são suportados. |
| **WalletTransaction** | Ledger de saldo (crédito, débito, reconciliação). |
| **Subscription + Plan** | Modelo SaaS por branches com planos `starter` / `enterprise`. |

## Campos adicionados (pré-produção)

### Plan

- `billingIntervalMonths` — intervalo do plano (1=mensal, 12=anual); prepara planos anuais e promoções.
- `trialDays` — dias de trial ao criar tenant (Starter=30 por defeito).

### Subscription

- `trialEndsAt` — fim do período experimental.
- `lastBillingAt` / `nextBillingAt` — controlo de cobrança recorrente.
- `currentPeriodEnd` — último dia coberto por pagamentos confirmados (pagamento antecipado).
- `autoRenew` — se `false`, o job mensal não gera fatura automaticamente.
- `branchesUsed` — **cache**; fonte de verdade: `COUNT(branches WHERE active=true)` em `GenerateMonthlyBillingService` e `CreateBranchUseCase`.

### Invoice

- `paidAmount` — total já liquidado (default `0`).
- `status` — inclui `parcial` para pagamentos incompletos.
- `remainingAmount` — coluna **GENERATED** no MySQL (`amount - paidAmount`); a API calcula o valor nas respostas HTTP para evitar leituras desactualizadas via Prisma.
- Índice `@@index([subscriptionId, dueDate])`.

### Payment

- `status` default `pendente` (confirmação manual ou webhook).
- `proofUrl` — comprovativo (transferência, recibo M-Pesa/e-Mola).
- `coversFrom` / `coversTo` — período coberto pelo pagamento (preenchido na confirmação a partir da fatura).
- `monthsCovered` — nº de meses cobertos (1, 6, 12…).
- `confirmedAt` / `confirmedBy` — aprovação por utilizador central.
- `reference` — referência da transacção (M-Pesa/e-Mola/transferência).
- `webhookEventId` — idempotência por evento de gateway.
- `deletedAt` — soft delete.

### PaymentWebhook

Fila de eventos de gateways (`MPESA`, `EMOLA`, etc.) para processamento idempotente. Consumida por `ReceivePaymentWebhookUseCase` e `ProcessPaymentWebhookUseCase`.

### Branch

- `dbSslEnabled` — ligação TLS à base tenant em produção.

### TenantStatus

- Valor `trial` alinhado com `SubscriptionStatus.trial`.

### PaymentMethod

- `EMOLA` adicionado ao lado de `MPESA`.

## Regras de negócio (implementadas)

### Trial + fatura na criação

```text
CreateTenant (status=trial)
  → Subscription status=trial, trialEndsAt = now + Plan.trialDays
  → Invoice pendente (amount=monthlyPrice, dueDate=trialEndsAt)
  → periodStart/End = primeiro mês após o trial

ConfirmPayment (invoice pago)
  → Subscription status=ativo
  → Tenant status=ativo
  → currentPeriodEnd / nextBillingAt avançados pelo período pago

Lifecycle (dueDate < now, invoice pendente)
  → Invoice vencido, Subscription expirado, Tenant suspenso
  → NÃO cria nova fatura no fim do trial
```

### Pagamento parcial

```text
paidAmount += payment.amount (quando status → confirmado)
if paidAmount >= invoice.amount → invoice.status = pago
else if paidAmount > 0           → invoice.status = parcial
```

Fatura `vencido` passa a `pago` quando totalmente liquidada. `cancelado` não é alterado.

### branchesUsed

Não confiar apenas no campo cacheado. Sempre recalcular em:

- geração mensal de faturação (`SubscriptionBillingService.countActiveBranchesForPeriod`);
- criação / desactivação de branch (`SubscriptionBranchHistoryService`);
- leituras de billing quando a precisão for crítica.

O campo na `Subscription` é actualizado após essas operações para leitura rápida.

### Filiais extras

```text
CreateBranch (nunca bloqueia por limite)
  → SubscriptionBranchHistory(ADD) + AuditLog
  → actualiza branchesUsed (cache)
  → SEM fatura imediata

GenerateMonthlyBilling / renovação
  → COUNT branches activas no período
  → extras = max(0, used - included)
  → total = monthlyPrice + extras * extraBranchPrice
  → BillingSnapshot (preços congelados) + Invoice

DeactivateBranch
  → active=false + History(REMOVE)
  → próxima factura não inclui a filial
```

### Código de aplicação

| Use case / serviço | Ficheiro |
|--------------------|----------|
| Faturação de período (domínio) | `billing/application/services/subscription-billing.service.ts` |
| Histórico ADD/REMOVE filiais | `billing/application/services/subscription-branch-history.service.ts` |
| Job mensal | `billing/application/services/generate-monthly-billing.service.ts` |
| Fatura trial | `billing/application/services/create-trial-invoice.service.ts` |
| Confirmar pagamento (manual) | `billing/application/use-cases/confirm-payment.use-case.ts` |
| Submeter pagamento | `billing/application/use-cases/submit-payment.use-case.ts` |
| Receber webhook | `billing/application/use-cases/receive-payment-webhook.use-case.ts` |
| Processar webhook | `billing/application/use-cases/process-payment-webhook.use-case.ts` |
| Integridade fatura | `billing/application/services/invoice-financial-integrity.service.ts` |
| Aplicar pagamento à fatura | `billing/application/services/apply-payment-to-invoice.service.ts` |
| Resposta HTTP (`remainingAmount`) | `billing/application/services/invoice-response.mapper.ts` |

## Próximos passos (opcional)

1. Upload de `proofUrl` (S3/local) no endpoint de submissão de pagamento.
2. Validação de assinatura específica por operador M-Pesa/e-Mola (formato oficial do gateway).
3. UI Flutter para criar fatura multi-mês (6/12) com `periodEnd` alargado e `amount = monthly * N` (com desconto opcional).
4. Uso de `TenantWallet` para créditos/saldo residual após overpay.

## Pagamento antecipado (modelo)

Fluxo mínimo sem novas tabelas:

```text
1. Criar Invoice com periodStart..periodEnd a cobrir N meses; amount = monthlyPrice * N
2. Confirmar Payment → preenche coversFrom/coversTo/monthsCovered
3. Subscription.currentPeriodEnd = periodEnd; nextBillingAt = periodEnd + 1 dia
4. GenerateMonthlyBilling salta períodos enquanto nextBillingAt > periodEnd do mês
```

Separação mantida: **Plan** (contrato) ≠ **Invoice** (cobrança do período) ≠ **Payment** (liquidação).

## Aplicar alterações na base

```bash
cd ../../infra/docker/phrx && docker compose -f docker-compose.dev.yml run --rm --no-deps phrx-backend \
  bunx prisma db push \
    --schema=src/infrastructure/prisma/central/schema.prisma \
    --accept-data-loss \
    --skip-generate

cd ../../infra/docker/phrx && docker compose -f docker-compose.dev.yml restart phrx-backend phrx-backend-worker
```
