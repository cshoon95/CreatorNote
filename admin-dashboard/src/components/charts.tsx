'use client'

import { PieChart, Pie, Cell, ResponsiveContainer, LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid, BarChart, Bar } from 'recharts'

interface PieData {
  name: string
  value: number
  color: string
}

export function ScreenPieChart({ data }: { data: PieData[] }) {
  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)]">
      <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-4">화면별 방문 비율</h3>
      <div className="flex items-center gap-6">
        <ResponsiveContainer width={160} height={160}>
          <PieChart>
            <Pie data={data} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={70} innerRadius={40}>
              {data.map((entry, i) => (
                <Cell key={i} fill={entry.color} />
              ))}
            </Pie>
          </PieChart>
        </ResponsiveContainer>
        <div className="space-y-2">
          {data.map((item, i) => (
            <div key={i} className="flex items-center gap-2 text-sm">
              <span className="w-3 h-3 rounded-full" style={{ backgroundColor: item.color }} />
              <span className="text-[var(--text-secondary)]">{item.name}</span>
              <span className="font-semibold ml-auto">{item.value}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export function HourlyChart({ data }: { data: { hour: string; count: number }[] }) {
  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)]">
      <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-4">시간대별 접속량</h3>
      <ResponsiveContainer width="100%" height={200}>
        <BarChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
          <XAxis dataKey="hour" tick={{ fontSize: 11 }} stroke="var(--text-secondary)" />
          <YAxis tick={{ fontSize: 12 }} stroke="var(--text-secondary)" allowDecimals={false} />
          <Tooltip />
          <Bar dataKey="count" fill="var(--primary)" radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}

export function DailyTrendChart({ data }: { data: { date: string; users: number; events: number }[] }) {
  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)]">
      <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-4">일별 활동 추이</h3>
      <ResponsiveContainer width="100%" height={200}>
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
          <XAxis dataKey="date" tick={{ fontSize: 12 }} stroke="var(--text-secondary)" />
          <YAxis tick={{ fontSize: 12 }} stroke="var(--text-secondary)" allowDecimals={false} />
          <Tooltip />
          <Line type="monotone" dataKey="users" stroke="var(--primary)" strokeWidth={2} name="활성 사용자" dot={{ fill: 'var(--primary)' }} />
          <Line type="monotone" dataKey="events" stroke="var(--success)" strokeWidth={2} name="이벤트" dot={{ fill: 'var(--success)' }} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}

export function ErrorTrendChart({ data }: { data: { date: string; count: number }[] }) {
  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)]">
      <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-4">일별 에러 추이</h3>
      <ResponsiveContainer width="100%" height={200}>
        <BarChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
          <XAxis dataKey="date" tick={{ fontSize: 12 }} stroke="var(--text-secondary)" />
          <YAxis tick={{ fontSize: 12 }} stroke="var(--text-secondary)" allowDecimals={false} />
          <Tooltip />
          <Bar dataKey="count" fill="var(--danger)" radius={[4, 4, 0, 0]} name="에러 수" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
