import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

export default function NotesLoading() {
  return (
    <div>
      <Skeleton width={120} height={32} rounded={8} />
      <div className="mt-6 mb-4">
        <Skeleton width="100%" height={48} rounded={16} />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-2">
        {[0, 1, 2, 3].map((i) => (
          <Card key={i} padding="md" className="flex items-start gap-3">
            <Skeleton width={48} height={48} rounded={12} />
            <div className="flex-1 space-y-2">
              <Skeleton width="70%" height={14} rounded={4} />
              <Skeleton width="90%" height={12} rounded={4} />
              <Skeleton width="40%" height={10} rounded={4} />
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
