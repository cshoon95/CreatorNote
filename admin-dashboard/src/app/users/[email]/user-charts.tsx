'use client'

import { ScreenPieChart, HourlyChart } from '@/components/charts'
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip } from 'recharts'

interface Props {
  screenPieData: { name: string; value: number; color: string }[]
  hourlyData: { hour: string; count: number }[]
  dailyActivity: { date: string; events: number }[]
}

export function UserActivityCharts({ screenPieData, hourlyData, dailyActivity }: Props) {
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <ScreenPieChart data={screenPieData} />
        <HourlyChart data={hourlyData} />
      </div>
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)]">
        <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-4">최근 14일 활동량</h3>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={dailyActivity}>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
            <XAxis dataKey="date" tick={{ fontSize: 11 }} stroke="var(--text-secondary)" />
            <YAxis tick={{ fontSize: 12 }} stroke="var(--text-secondary)" allowDecimals={false} />
            <Tooltip />
            <Bar dataKey="events" fill="var(--primary)" radius={[4, 4, 0, 0]} name="활동" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}
