'use client'

import { ScreenPieChart, HourlyChart, DailyTrendChart, ErrorTrendChart } from '@/components/charts'

interface Props {
  screenPieData: { name: string; value: number; color: string }[]
  hourlyData: { hour: string; count: number }[]
  dailyTrend: { date: string; users: number; events: number }[]
  errorTrend: { date: string; count: number }[]
}

export function DashboardCharts({ screenPieData, hourlyData, dailyTrend, errorTrend }: Props) {
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ScreenPieChart data={screenPieData} />
        <HourlyChart data={hourlyData} />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <DailyTrendChart data={dailyTrend} />
        <ErrorTrendChart data={errorTrend} />
      </div>
    </div>
  )
}
