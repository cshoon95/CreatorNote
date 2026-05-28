import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

export default function SettlementsLoading() {
  return (
    <div>
      <Skeleton width={100} height={32} rounded={8} />
      <div className="grid grid-cols-2 gap-3 mt-6 mb-6">
        <Card padding="md">
          <Skeleton width={120} height={12} rounded={4} />
          <div className="mt-2">
            <Skeleton width={140} height={20} rounded={4} />
          </div>
        </Card>
        <Card padding="md">
          <Skeleton width={120} height={12} rounded={4} />
          <div className="mt-2">
            <Skeleton width={140} height={20} rounded={4} />
          </div>
        </Card>
      </div>
      <div className="space-y-2">
        {[0, 1, 2, 3].map((i) => (
          <Card key={i} padding="md" className="flex items-center gap-3">
            <Skeleton width={28} height={28} rounded={8} />
            <div className="flex-1 space-y-2">
              <Skeleton width="50%" height={14} rounded={4} />
              <Skeleton width="35%" height={12} rounded={4} />
            </div>
            <Skeleton width={80} height={20} rounded={6} />
          </Card>
        ))}
      </div>
    </div>
  );
}
