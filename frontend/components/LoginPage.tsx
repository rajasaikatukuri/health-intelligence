'use client'

import { useState } from 'react'
import axios from 'axios'

interface LoginPageProps {
  onLogin: (token: string, tenantId: string) => void
}

export default function LoginPage({ onLogin }: LoginPageProps) {
  const [username, setUsername] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      const response = await axios.post(`${API_URL}/api/auth/login`, {
        username: username.trim()
      })

      onLogin(response.data.access_token, response.data.tenant_id)
    } catch (err: any) {
      console.error('Login error:', err)
      if (err.code === 'ECONNREFUSED' || err.message?.includes('Network Error')) {
        setError('Cannot connect to backend. Is the server running on http://localhost:8000?')
      } else if (err.response) {
        setError(err.response?.data?.detail || `Login failed: ${err.response?.status} ${err.response?.statusText}`)
      } else {
        setError(`Login failed: ${err.message || 'Unknown error'}`)
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="bg-white p-8 rounded-lg shadow-xl w-full max-w-md">
        <h1 className="text-3xl font-bold text-center mb-6 text-gray-800">
          Health Intelligence Platform
        </h1>
        <p className="text-center text-gray-600 mb-8">
          Enter your username to get started
        </p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="username" className="block text-sm font-medium text-gray-700 mb-2">
              Username (tenant_id)
            </label>
            <input
              id="username"
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="rajasaikatukuri"
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <p className="mt-2 text-xs text-gray-500">
              For dev: username = tenant_id
            </p>
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading || !username.trim()}
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
          >
            {loading ? 'Logging in...' : 'Login'}
          </button>
        </form>
      </div>
    </div>
  )
}

