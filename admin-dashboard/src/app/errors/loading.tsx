import { TableSkeleton, ListSkeleton } from '@/components/skeleton'

export default function ErrorsLoading() {
  return (
    <div>
      <div className="h-8 w-32 animate-pulse bg-slate-200 rounded-xl mb-6" />
      <ListSkeleton rows={5} />
      <div className="mt-6">
        <TableSkeleton rows={8} cols={5} />
      </div>
    </div>
  )
}
