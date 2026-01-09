'use client'

import { useState, useRef, useEffect } from 'react'
import axios from 'axios'
import ChartRenderer from './ChartRenderer'

interface Message {
  role: 'user' | 'assistant'
  content: string
  charts?: any[]
  sql_used?: string
}

interface ChatPageProps {
  token: string
  tenantId: string
  onLogout: () => void
}

const SUGGESTED_QUESTIONS = [
  "Summarize my last 30 days",
  "Show steps trend and explain spikes",
  "Compare last 7 days vs previous 7 days",
  "What day had the best activity?",
  "Create a dashboard for cardio fitness",
  "Am I improving this month?",
  "Give me a weekly health briefing",
  "Detect anomalies in heart rate"
]

export default function ChatPage({ token, tenantId, onLogout }: ChatPageProps) {
  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const [explainingChart, setExplainingChart] = useState<string | null>(null)

  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const handleSend = async (question?: string) => {
    const messageText = question || input.trim()
    if (!messageText) return

    setInput('')
    setLoading(true)

    // Add user message
    const userMessage: Message = { role: 'user', content: messageText }
    setMessages(prev => [...prev, userMessage])

    try {
      const response = await axios.post(
        `${API_URL}/api/chat`,
        { message: messageText },
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        }
      )

      const assistantMessage: Message = {
        role: 'assistant',
        content: response.data.answer,
        charts: response.data.charts,
        sql_used: response.data.sql_used
      }

      setMessages(prev => [...prev, assistantMessage])
    } catch (error: any) {
      const errorMessage: Message = {
        role: 'assistant',
        content: `Error: ${error.response?.data?.detail || error.message}`
      }
      setMessages(prev => [...prev, errorMessage])
    } finally {
      setLoading(false)
    }
  }

  const handleExplainChart = async (chartSpec: any, summary: string) => {
    setExplainingChart(summary)
    
    try {
      const response = await axios.post(
        `${API_URL}/api/chat/explain-chart`,
        {
          chart_spec: chartSpec,
          summary: summary
        },
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        }
      )

      const explanationMessage: Message = {
        role: 'assistant',
        content: `Chart Explanation:\n\n${response.data.explanation}`
      }

      setMessages(prev => [...prev, explanationMessage])
    } catch (error: any) {
      alert(`Error explaining chart: ${error.response?.data?.detail || error.message}`)
    } finally {
      setExplainingChart(null)
    }
  }

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <div className="w-64 bg-white border-r border-gray-200 flex flex-col">
        <div className="p-4 border-b border-gray-200">
          <h2 className="text-lg font-semibold text-gray-800">Health Intelligence</h2>
          <p className="text-sm text-gray-500 mt-1">Tenant: {tenantId}</p>
        </div>

        <div className="flex-1 overflow-y-auto p-4">
          <h3 className="text-sm font-medium text-gray-700 mb-3">Suggested Questions</h3>
          <div className="space-y-2">
            {SUGGESTED_QUESTIONS.map((q, i) => (
              <button
                key={i}
                onClick={() => handleSend(q)}
                className="w-full text-left px-3 py-2 text-sm bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors"
              >
                {q}
              </button>
            ))}
          </div>
        </div>

        <div className="p-4 border-t border-gray-200">
          <button
            onClick={onLogout}
            className="w-full px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
          >
            Logout
          </button>
        </div>
      </div>

      {/* Main Chat Area */}
      <div className="flex-1 flex flex-col">
        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {messages.map((msg, idx) => (
            <div
              key={idx}
              className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-3xl rounded-lg px-4 py-2 ${
                  msg.role === 'user'
                    ? 'bg-blue-600 text-white'
                    : 'bg-white border border-gray-200 text-gray-800'
                }`}
              >
                <div className="whitespace-pre-wrap">{msg.content}</div>
                
                {msg.charts && msg.charts.map((chart, chartIdx) => (
                  <div key={chartIdx} className="mt-4">
                    <ChartRenderer spec={chart.spec} />
                    <button
                      onClick={() => handleExplainChart(chart.spec, msg.content)}
                      className="mt-2 text-sm text-blue-600 hover:text-blue-800"
                      disabled={explainingChart !== null}
                    >
                      {explainingChart === msg.content ? 'Explaining...' : 'Explain this chart'}
                    </button>
                  </div>
                ))}

                {msg.sql_used && (
                  <details className="mt-2 text-xs">
                    <summary className="cursor-pointer text-gray-500 hover:text-gray-700">
                      Show SQL
                    </summary>
                    <pre className="mt-2 p-2 bg-gray-100 rounded overflow-x-auto">
                      {msg.sql_used}
                    </pre>
                  </details>
                )}
              </div>
            </div>
          ))}

          {loading && (
            <div className="flex justify-start">
              <div className="bg-white border border-gray-200 rounded-lg px-4 py-2">
                <div className="flex space-x-2">
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }}></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
                </div>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        {/* Input */}
        <div className="border-t border-gray-200 p-4 bg-white">
          <form
            onSubmit={(e) => {
              e.preventDefault()
              handleSend()
            }}
            className="flex space-x-4"
          >
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Ask about your health data..."
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              disabled={loading}
            />
            <button
              type="submit"
              disabled={loading || !input.trim()}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
            >
              Send
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}





