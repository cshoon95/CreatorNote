import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

export default function DashboardLoading() {
  return (
    <div className="space-y-5">
      <div>
        <Skeleton width={260} height={32} rounded={8} />
        <div className="mt-2">
          <Skeleton width={200} height={16} rounded={8} />
        </div>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {[0, 1].map((i) => (
          <Card key={i} padding="lg">
            <Skeleton width={140} height={20} rounded={6} />
            <div className="mt-5">
              <Skeleton width="100%" height={40} rounded={8} />
            </div>
            <div className="grid grid-cols-2 gap-2 mt-4">
              <Skeleton width="100%" height={56} rounded={12} />
              <Skeleton width="100%" height={56} rounded={12} />
            </div>
          </Card>
        ))}
      </div>
      <Card padding="lg">
        <Skeleton width={200} height={20} rounded={6} />
        <div className="mt-4">
          <Skeleton width="100%" height={180} rounded={12} />
        </div>
      </Card>
    </div>
  );
}
