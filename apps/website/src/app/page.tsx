import { ProductCard } from "@/components/ProductCard";
import { phrxProduct } from "@/products/phrx";
import { gastroProduct } from "@/products/gastro";
import { retailProduct } from "@/products/retail";

export default function HomePage() {
  return (
    <main style={{ maxWidth: 960, margin: "0 auto", padding: "4rem 1.5rem" }}>
      <p style={{ letterSpacing: "0.2em", textTransform: "uppercase", color: "var(--muted)", fontSize: 12 }}>
        Skalway
      </p>
      <h1 style={{ fontSize: "clamp(2.5rem, 6vw, 4rem)", marginTop: 12, lineHeight: 1.05 }}>
        ERPs para o negócio real
      </h1>
      <p style={{ marginTop: 16, maxWidth: 520, color: "var(--muted)", fontSize: 18 }}>
        Farmácia, restauração e retalho — uma plataforma, produtos especializados.
      </p>

      <section style={{ display: "grid", gap: 20, marginTop: 48 }}>
        <ProductCard product={phrxProduct} />
        <ProductCard product={gastroProduct} />
        <ProductCard product={retailProduct} />
      </section>
    </main>
  );
}
