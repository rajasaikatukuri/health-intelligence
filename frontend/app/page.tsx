'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import LoginPage from '@/components/LoginPage'
import ChatPage from '@/components/ChatPage'

export default function Home() {
  const [token, setToken] = useState<string | null>(null)
  const [tenantId, setTenantId] = useState<string | null>(null)
  const router = useRouter()

  useEffect(() => {
    // Check for stored token
    const storedToken = localStorage.getItem('auth_token')
    const storedTenantId = localStorage.getItem('tenant_id')
    
    if (storedToken && storedTenantId) {
      setToken(storedToken)
      setTenantId(storedTenantId)
    }
  }, [])

  const handleLogin = (newToken: string, newTenantId: string) => {
    setToken(newToken)
    setTenantId(newTenantId)
    localStorage.setItem('auth_token', newToken)
    localStorage.setItem('tenant_id', newTenantId)
  }

  const handleLogout = () => {
    setToken(null)
    setTenantId(null)
    localStorage.removeItem('auth_token')
    localStorage.removeItem('tenant_id')
  }

  if (!token) {
    return <LoginPage onLogin={handleLogin} />
  }

  return <ChatPage token={token} tenantId={tenantId} onLogout={handleLogout} />
}





