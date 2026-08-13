/**
 * Template HTML A4 da Factura SaaS da Central.
 * Layout alinhado ao padrão institucional (cabeçalho, cliente, tabela, totais, pagamentos).
 */

export type CentralInvoiceLineItem = {
  item: number | string;
  description: string;
  qty: string;
  unitPrice: string;
  amount: string;
};

export type CentralInvoicePdfView = {
  issuer: {
    companyName: string;
    companyNuit: string;
    companyEmail: string;
    companyPhone: string;
    companyAddress: string;
    companyCity?: string | null;
    companyProvince?: string | null;
    companyCountry?: string | null;
    companyLogo?: string | null;
    mpesaAccountName?: string | null;
    mpesaAccountNumber?: string | null;
    emolaAccountName?: string | null;
    emolaAccountNumber?: string | null;
    bankName?: string | null;
    bankAccountName?: string | null;
    bankAccountNumber?: string | null;
    bankAccountNib?: string | null;
    bankAccountSwift?: string | null;
    bankTransferInstructions?: string | null;
    invoiceFooter?: string | null;
    defaultMessage?: string | null;
  };
  customer: {
    companyName: string;
    nuit?: string | null;
    contact?: string | null;
    address?: string | null;
  };
  invoice: {
    number: string;
    date: string;
    dueDate: string;
    status: string;
    period: string;
    currency: string;
    terms: string;
    description?: string | null;
  };
  items: CentralInvoiceLineItem[];
    totals: {
      subtotal: string;
      discount: string;
      paid: string;
      remaining: string;
      total: string;
    };
  payments: Array<{
    reference: string;
    method: string;
    amount: string;
    status: string;
    date: string;
  }>;
};

function escapeHtml(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function issuerAddress(issuer: CentralInvoicePdfView["issuer"]): string {
  return [
    issuer.companyAddress,
    issuer.companyCity,
    issuer.companyProvince,
    issuer.companyCountry,
  ]
    .map((part) => String(part ?? "").trim())
    .filter(Boolean)
    .join(", ");
}

export function renderCentralInvoiceHtml(view: CentralInvoicePdfView): string {
  const { issuer, customer, invoice, items, totals, payments } = view;
  const logo = issuer.companyLogo
    ? `<img class="logo" src="${escapeHtml(issuer.companyLogo)}" alt="Logo" />`
    : "";

  const itemRows =
    items.length > 0
      ? items
          .map((row) => {
            const [main, periodLine] = String(row.description).split("\n");
            const periodHtml = periodLine
              ? `<span class="contract-period">${escapeHtml(periodLine)}</span>`
              : "";
            return `
        <tr>
          <td class="c-item">${escapeHtml(row.item)}</td>
          <td class="c-desc">${escapeHtml(main)}${periodHtml}</td>
          <td class="c-qty">${escapeHtml(row.qty)}</td>
          <td class="c-num">${escapeHtml(row.unitPrice)}</td>
          <td class="c-num">${escapeHtml(row.amount)}</td>
        </tr>`;
          })
          .join("")
      : `<tr><td colspan="5" class="empty">Sem linhas de facturação.</td></tr>`;

  const paymentRows =
    payments.length > 0
      ? payments
          .map(
            (p) => `
        <tr>
          <td>${escapeHtml(p.date)}</td>
          <td>${escapeHtml(p.reference)}</td>
          <td>${escapeHtml(p.method)}</td>
          <td class="c-num">${escapeHtml(p.amount)}</td>
          <td>${escapeHtml(p.status)}</td>
        </tr>`,
          )
          .join("")
      : `<tr><td colspan="5" class="empty">Nenhum pagamento registado.</td></tr>`;

  const mpesa =
    issuer.mpesaAccountNumber
      ? `<div><strong>M-Pesa</strong> — ${escapeHtml(issuer.mpesaAccountName ?? "")} ${escapeHtml(issuer.mpesaAccountNumber)}</div>`
      : "";
  const emola =
    issuer.emolaAccountNumber
      ? `<div><strong>E-Mola</strong> — ${escapeHtml(issuer.emolaAccountName ?? "")} ${escapeHtml(issuer.emolaAccountNumber)}</div>`
      : "";
  const bankBits = [
    issuer.bankName ? `Banco: ${issuer.bankName}` : null,
    issuer.bankAccountName ? `Titular: ${issuer.bankAccountName}` : null,
    issuer.bankAccountNumber ? `Conta: ${issuer.bankAccountNumber}` : null,
    issuer.bankAccountNib ? `NIB: ${issuer.bankAccountNib}` : null,
    issuer.bankAccountSwift ? `SWIFT: ${issuer.bankAccountSwift}` : null,
  ].filter(Boolean);
  const bank =
    bankBits.length > 0
      ? `<div><strong>Transferência Bancária</strong><br/>${bankBits.map(escapeHtml).join("<br/>")}</div>`
      : "";

  return `<!DOCTYPE html>
<html lang="pt">
<head>
  <meta charset="utf-8" />
  <title>Factura ${escapeHtml(invoice.number)}</title>
  <style>
    @page { size: A4 portrait; margin: 12mm 12mm 14mm 12mm; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 0;
      font-family: Arial, Helvetica, sans-serif;
      font-size: 11px;
      color: #222;
      line-height: 1.4;
      background: #fff;
    }
    .sheet { width: 100%; }
    .top {
      display: flex;
      justify-content: space-between;
      gap: 24px;
      border-bottom: 2px solid #184a80;
      padding-bottom: 12px;
      margin-bottom: 14px;
    }
    .brand { flex: 1; min-width: 0; }
    .brand h1 {
      margin: 0 0 6px;
      font-size: 20px;
      color: #184a80;
      letter-spacing: 0.02em;
      text-transform: uppercase;
    }
    .brand .meta { color: #555; }
    .brand .meta div { margin: 1px 0; }
    .logo { max-height: 52px; max-width: 160px; margin-bottom: 8px; display: block; }
    .invoice-meta {
      width: 220px;
      border: 1px solid #cfd8e3;
      background: #f5f8fb;
      padding: 10px 12px;
    }
    .invoice-meta .title {
      font-size: 13px;
      font-weight: 700;
      color: #184a80;
      margin-bottom: 8px;
      text-transform: uppercase;
    }
    .invoice-meta table { width: 100%; border-collapse: collapse; }
    .invoice-meta td { padding: 2px 0; vertical-align: top; }
    .invoice-meta td.k { width: 42%; color: #666; }
    .invoice-meta td.v { font-weight: 600; text-align: right; }
    .parties {
      display: flex;
      gap: 12px;
      margin-bottom: 14px;
    }
    .box {
      flex: 1;
      border: 1px solid #d0d7de;
      padding: 10px 12px;
      min-height: 88px;
    }
    .box .label {
      font-size: 10px;
      font-weight: 700;
      color: #184a80;
      text-transform: uppercase;
      margin-bottom: 6px;
      letter-spacing: 0.04em;
    }
    .box .name { font-size: 13px; font-weight: 700; margin-bottom: 4px; }
    table.items {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 12px;
      table-layout: fixed;
    }
    table.items thead th {
      background: #184a80;
      color: #fff;
      text-align: left;
      padding: 8px 8px;
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: 0.03em;
    }
    table.items tbody td {
      border-bottom: 1px solid #e3e8ee;
      padding: 8px;
      vertical-align: top;
      word-wrap: break-word;
      overflow-wrap: break-word;
    }
    table.items tbody tr:nth-child(even) td { background: #f8fafc; }
    .c-item { width: 8%; text-align: center; }
    .c-desc { width: 44%; white-space: pre-line; }
    .c-desc .contract-period { display: block; margin-top: 4px; color: #555; font-size: 10px; font-weight: 600; }
    .c-qty { width: 12%; text-align: center; }
    .c-num { width: 18%; text-align: right; white-space: nowrap; }
    .empty { text-align: center; color: #777; padding: 16px !important; }
    .bottom {
      display: flex;
      justify-content: space-between;
      gap: 18px;
      margin-top: 8px;
    }
    .notes {
      flex: 1;
      font-size: 10px;
      color: #555;
    }
    .notes .label {
      font-weight: 700;
      color: #184a80;
      text-transform: uppercase;
      margin-bottom: 4px;
    }
    .totals {
      width: 240px;
      border: 1px solid #d0d7de;
    }
    .totals table { width: 100%; border-collapse: collapse; }
    .totals td { padding: 7px 10px; }
    .totals td.k { color: #555; }
    .totals td.v { text-align: right; font-weight: 600; }
    .totals tr.grand td {
      background: #184a80;
      color: #fff;
      font-size: 13px;
      font-weight: 700;
    }
    .pay-methods {
      margin-top: 16px;
      border-top: 1px solid #d0d7de;
      padding-top: 10px;
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px 18px;
      font-size: 10px;
      color: #444;
    }
    .pay-methods h3 {
      grid-column: 1 / -1;
      margin: 0 0 4px;
      font-size: 11px;
      color: #184a80;
      text-transform: uppercase;
    }
    .payments-block { margin-top: 16px; }
    .payments-block h3 {
      margin: 0 0 6px;
      font-size: 11px;
      color: #184a80;
      text-transform: uppercase;
    }
    table.payments {
      width: 100%;
      border-collapse: collapse;
      font-size: 10px;
    }
    table.payments th {
      background: #eef3f8;
      text-align: left;
      padding: 6px 8px;
      border-bottom: 1px solid #d0d7de;
    }
    table.payments td {
      padding: 6px 8px;
      border-bottom: 1px solid #eef1f4;
    }
    .sign {
      margin-top: 28px;
      display: flex;
      justify-content: flex-end;
    }
    .sign-box {
      width: 220px;
      text-align: center;
    }
    .sign-line {
      border-top: 1px solid #333;
      margin-top: 48px;
      padding-top: 6px;
      font-size: 10px;
      color: #555;
    }
    .footer {
      margin-top: 18px;
      padding-top: 8px;
      border-top: 1px solid #d0d7de;
      text-align: center;
      color: #666;
      font-size: 10px;
    }
  </style>
</head>
<body>
  <div class="sheet">
    <div class="top">
      <div class="brand">
        ${logo}
        <h1>${escapeHtml(issuer.companyName)}</h1>
        <div class="meta">
          <div>NUIT: ${escapeHtml(issuer.companyNuit)}</div>
          <div>${escapeHtml(issuerAddress(issuer))}</div>
          <div>Tel.: ${escapeHtml(issuer.companyPhone)}</div>
          <div>Email: ${escapeHtml(issuer.companyEmail)}</div>
        </div>
      </div>
      <div class="invoice-meta">
        <div class="title">Factura SaaS</div>
        <table>
          <tr><td class="k">Nº</td><td class="v">${escapeHtml(invoice.number)}</td></tr>
          <tr><td class="k">Data</td><td class="v">${escapeHtml(invoice.date)}</td></tr>
          <tr><td class="k">Vencimento</td><td class="v">${escapeHtml(invoice.dueDate)}</td></tr>
          <tr><td class="k">Estado</td><td class="v">${escapeHtml(invoice.status)}</td></tr>
          <tr><td class="k">Período</td><td class="v">${escapeHtml(invoice.period)}</td></tr>
          <tr><td class="k">Condições</td><td class="v">${escapeHtml(invoice.terms)}</td></tr>
        </table>
      </div>
    </div>

    <div class="parties">
      <div class="box">
        <div class="label">Facturado a</div>
        <div class="name">${escapeHtml(customer.companyName)}</div>
        <div>NUIT: ${escapeHtml(customer.nuit || "—")}</div>
        <div>${escapeHtml(customer.address || "—")}</div>
        <div>${escapeHtml(customer.contact || "—")}</div>
      </div>
      <div class="box">
        <div class="label">Descrição do serviço</div>
        <div>${escapeHtml(invoice.description || "Subscrição PhRx — facturação SaaS")}</div>
      </div>
    </div>

    <table class="items">
      <thead>
        <tr>
          <th class="c-item">Item</th>
          <th class="c-desc">Descrição</th>
          <th class="c-qty">Qtd</th>
          <th class="c-num">Preço Unit.</th>
          <th class="c-num">Valor</th>
        </tr>
      </thead>
      <tbody>
        ${itemRows}
      </tbody>
    </table>

    <div class="bottom">
      <div class="notes">
        <div class="label">Notas importantes</div>
        <div>${escapeHtml(issuer.bankTransferInstructions || "Indique o número da factura na descrição do pagamento.")}</div>
        <div style="margin-top:8px;">Qualquer discrepância deve ser comunicada no prazo de 7 dias. Pagamentos em atraso podem suspender o acesso ao serviço.</div>
      </div>
      <div class="totals">
        <table>
          <tr><td class="k">Subtotal</td><td class="v">${escapeHtml(totals.subtotal)} ${escapeHtml(invoice.currency)}</td></tr>
          <tr><td class="k">Desconto</td><td class="v">${escapeHtml(totals.discount)} ${escapeHtml(invoice.currency)}</td></tr>
          <tr><td class="k">Pago</td><td class="v">${escapeHtml(totals.paid)} ${escapeHtml(invoice.currency)}</td></tr>
          <tr><td class="k">Em aberto</td><td class="v">${escapeHtml(totals.remaining)} ${escapeHtml(invoice.currency)}</td></tr>
          <tr class="grand"><td class="k">TOTAL</td><td class="v">${escapeHtml(totals.total)} ${escapeHtml(invoice.currency)}</td></tr>
        </table>
      </div>
    </div>

    <div class="pay-methods">
      <h3>Métodos de Pagamento</h3>
      ${mpesa || "<div><strong>M-Pesa</strong> — —</div>"}
      ${emola || "<div><strong>E-Mola</strong> — —</div>"}
      ${bank || "<div><strong>Transferência Bancária</strong> — —</div>"}
    </div>

    <div class="payments-block">
      <h3>Pagamentos Registados</h3>
      <table class="payments">
        <thead>
          <tr>
            <th>Data</th>
            <th>Referência</th>
            <th>Método</th>
            <th class="c-num">Valor</th>
            <th>Estado</th>
          </tr>
        </thead>
        <tbody>${paymentRows}</tbody>
      </table>
    </div>

    <div class="sign">
      <div class="sign-box">
        <div>por ${escapeHtml(issuer.companyName)}</div>
        <div class="sign-line">Assinatura Autorizada</div>
      </div>
    </div>

    <div class="footer">
      ${escapeHtml(issuer.invoiceFooter || issuer.defaultMessage || "")}
    </div>
  </div>
</body>
</html>`;
}
