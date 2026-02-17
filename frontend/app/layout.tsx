import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Health Intelligence Platform',
  description: 'Chat-based analytics for health data',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}






