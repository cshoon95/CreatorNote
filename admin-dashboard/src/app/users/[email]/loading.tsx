import { KPISkeleton, ChartSkeleton, ListSkeleton, Skeleton } from '@/components/skeleton'

export default function UserDetailLoading() {
  return (
    <div>
      <Skeleton className="h-4 w-24 mb-4" />
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)] mb-6">
        <div className="flex items-center gap-4">
          <Skeleton className="w-16 h-16 rounded-full" />
          <div className="space-y-2">
            <Skeleton className="h-6 w-32" />
            <Skeleton className="h-4 w-48" />
            <Skeleton className="h-3 w-64" />
          </div>
        </div>
      </div>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <KPISkeleton />
        <KPISkeleton />
        <KPISkeleton />
        <KPISkeleton />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        <ChartSkeleton />
        <ChartSkeleton />
      </div>
      <ListSkeleton rows={8} />
    </div>
  )
}
