import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Skalway",
  description: "Plataforma de ERPs para farmácia, restauração e retalho.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt">
      <body>{children}</body>
    </html>
  );
}
