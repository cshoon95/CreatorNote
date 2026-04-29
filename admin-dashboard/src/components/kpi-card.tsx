interface KPICardProps {
  title: string
  value: string | number
  subtitle?: string
  icon: string
  color?: string
}

export function KPICard({ title, value, subtitle, icon, color = 'var(--primary)' }: KPICardProps) {
  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)]">
      <div className="flex items-center justify-between mb-4">
        <span className="text-2xl">{icon}</span>
      </div>
      <p className="text-2xl font-bold" style={{ color }}>{value}</p>
      <p className="text-sm font-medium text-[var(--text)] mt-1">{title}</p>
      {subtitle && <p className="text-xs text-[var(--text-secondary)] mt-1">{subtitle}</p>}
    </div>
  )
}
