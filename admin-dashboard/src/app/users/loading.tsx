import { KPISkeleton, TableSkeleton } from '@/components/skeleton'

export default function UsersLoading() {
  return (
    <div>
      <div className="h-8 w-36 animate-pulse bg-slate-200 rounded-xl mb-6" />
      <div className="h-12 w-full max-w-md animate-pulse bg-slate-200 rounded-xl mb-6" />
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <KPISkeleton />
        <KPISkeleton />
        <KPISkeleton />
        <KPISkeleton />
      </div>
      <TableSkeleton rows={8} cols={6} />
    </div>
  )
}
