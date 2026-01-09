'use client'

import { useEffect, useRef } from 'react'
import * as vegaEmbed from 'vega-embed'

interface ChartRendererProps {
  spec: any
}

export default function ChartRenderer({ spec }: ChartRendererProps) {
  const chartRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (chartRef.current && spec) {
      // Clear previous chart
      chartRef.current.innerHTML = ''

      // Render Vega-Lite chart
      vegaEmbed.default(chartRef.current, spec, {
        actions: false,
        renderer: 'svg'
      }).catch((error: Error) => {
        console.error('Error rendering chart:', error)
        if (chartRef.current) {
          chartRef.current.innerHTML = `<div class="text-red-600 p-4">Error rendering chart: ${error.message}</div>`
        }
      })
    }
  }, [spec])

  if (!spec) {
    return <div className="text-gray-500 p-4">No chart data available</div>
  }

  return (
    <div className="w-full">
      <div ref={chartRef} className="w-full" />
    </div>
  )
}





