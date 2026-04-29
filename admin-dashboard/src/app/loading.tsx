import { KPISkeleton, ChartSkeleton, ListSkeleton } from '@/components/skeleton'

export default function DashboardLoading() {
  return (
    <div>
      <div className="h-8 w-48 animate-pulse bg-slate-200 rounded-xl mb-6" />
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <KPISkeleton />
        <KPISkeleton />
        <KPISkeleton />
        <KPISkeleton />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        <ChartSkeleton />
        <ChartSkeleton />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        <ChartSkeleton />
        <ChartSkeleton />
      </div>
      <ListSkeleton rows={5} />
    </div>
  )
}
