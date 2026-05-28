import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

export default function SponsorshipsLoading() {
  return (
    <div>
      <Skeleton width={120} height={32} rounded={8} />
      <div className="mt-6 mb-4">
        <Skeleton width="100%" height={44} rounded={12} />
      </div>
      <div className="space-y-2 mt-4">
        {[0, 1, 2, 3, 4].map((i) => (
          <Card key={i} padding="md" className="flex items-center gap-3">
            <Skeleton width={44} height={44} rounded={999} />
            <div className="flex-1 space-y-2">
              <Skeleton width="60%" height={14} rounded={4} />
              <Skeleton width="40%" height={12} rounded={4} />
            </div>
            <Skeleton width={80} height={20} rounded={6} />
          </Card>
        ))}
      </div>
    </div>
  );
}
