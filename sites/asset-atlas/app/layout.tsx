import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Eclipse Asset Atelier · PROJECT ECLIPSE",
  description: "Thư viện asset, phiên bản, duyệt và checklist xuất cho PROJECT ECLIPSE.",
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi">
      <body className="antialiased">{children}</body>
    </html>
  );
}
