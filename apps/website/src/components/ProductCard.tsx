export type ProductInfo = {
  slug: string;
  name: string;
  tagline: string;
  href: string;
};

export function ProductCard({ product }: { product: ProductInfo }) {
  return (
    <a
      href={product.href}
      style={{
        display: "block",
        padding: "1.25rem 1.5rem",
        border: "1px solid rgba(255,255,255,0.12)",
        borderRadius: 12,
        background: "rgba(255,255,255,0.03)",
      }}
    >
      <strong style={{ color: "var(--accent)" }}>{product.name}</strong>
      <p style={{ marginTop: 6, color: "var(--muted)" }}>{product.tagline}</p>
    </a>
  );
}
