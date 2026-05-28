import type { Metadata, Viewport } from "next";
import "./globals.css";
import { ToastHost } from "@/components/toast";
import { ThemeProvider } from "@/components/theme-provider";

export const metadata: Metadata = {
  title: "Influe — 크리에이터 협찬·정산·노트",
  description: "협찬과 정산, 릴스 기획까지. 크리에이터를 위한 모든 것이 하나에.",
  applicationName: "Influe",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Influe",
  },
  formatDetection: { telephone: false },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#fafaff" },
    { media: "(prefers-color-scheme: dark)", color: "#0b0820" },
  ],
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko" suppressHydrationWarning>
      <body className="min-h-screen antialiased">
        <ThemeProvider>
          {children}
          <ToastHost />
        </ThemeProvider>
      </body>
    </html>
  );
}
