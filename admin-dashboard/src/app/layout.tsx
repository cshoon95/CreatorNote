import type { Metadata } from 'next'
import './globals.css'
import { cookies } from 'next/headers'
import { Sidebar } from '@/components/sidebar'

export const metadata: Metadata = {
  title: 'Influe Admin Dashboard',
  description: 'Influe 앱 모니터링 대시보드',
  manifest: '/manifest.json',
  themeColor: '#6366f1',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'default',
    title: 'Influe Admin',
  },
  viewport: 'width=device-width, initial-scale=1, maximum-scale=1',
}

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const cookieStore = await cookies()
  const isLoggedIn = !!cookieStore.get('admin_session')?.value

  return (
    <html lang="ko">
      <head>
        <link rel="apple-touch-icon" href="/icon-192.png" />
      </head>
      <body className="min-h-screen">
        <script
          dangerouslySetInnerHTML={{
            __html: `if('serviceWorker' in navigator){navigator.serviceWorker.register('/sw.js')}`,
          }}
        />
        {/* Splash screen */}
        <div id="splash" style={{
          position: 'fixed', inset: 0, zIndex: 9999,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          backgroundColor: '#1a1a1a',
          transition: 'opacity 0.3s ease',
        }}>
          <img src="/icon-512.png" alt="" width={120} height={120} style={{ borderRadius: 24 }} />
        </div>
        <script
          dangerouslySetInnerHTML={{
            __html: `setTimeout(function(){var s=document.getElementById('splash');if(s){s.style.opacity='0';setTimeout(function(){s.remove()},300)}},500)`,
          }}
        />
        {isLoggedIn && <Sidebar />}
        <main className={isLoggedIn ? 'pt-14 lg:pt-0 lg:ml-64 p-4 lg:p-8' : ''}>
          {children}
        </main>
      </body>
    </html>
  )
}
