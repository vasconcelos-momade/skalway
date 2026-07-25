# Billing Service

Pacote partilhado `@skalway/billing`.

## Responsabilidades (extractadas)

- Integridade fatura ↔ pagamentos
- Mapping de campos financeiros para API
- Money (cents), períodos UTC, pricing de planos
- Numeração fiscal `INV-YYYY-NNNNNN`
- Textos de fatura (mensal / trial)

## Ainda no PhRx

- Use-cases Prisma (subscription, invoices, payments, webhooks)
- Controllers / rotas HTTP
- Email e worker de jobs

## Uso

```ts
import {
  assertInvoiceAmounts,
  calculatePlanTotals,
  formatInvoiceNumber,
} from "@skalway/billing";
```
