"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { toast } from "@/components/toast";

export function DetailActions({ id, brandName }: { id: string; brandName: string }) {
  const router = useRouter();
  const remove = async () => {
    if (!confirm(`${brandName} 정산을 삭제할까요?`)) return;
    const supabase = createClient();
    const { error } = await supabase.from("settlements").delete().eq("id", id);
    if (error) {
      toast("삭제에 실패했습니다", "danger");
    } else {
      toast("삭제되었어요", "success");
      router.push("/settlements");
      router.refresh();
    }
  };
  return (
    <div className="flex gap-2 mt-4">
      <Link href={`/settlements/${id}/edit`} className="btn btn-primary flex-1 text-center">
        수정하기
      </Link>
      <Button variant="danger" onClick={remove} fullWidth>
        삭제
      </Button>
    </div>
  );
}
