"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { toast } from "@/components/toast";

export function PendingClient({ workspaceId }: { workspaceId: string }) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  const refresh = async () => {
    setLoading(true);
    const supabase = createClient();
    const { data: userData } = await supabase.auth.getUser();
    const userId = userData.user?.id;
    if (!userId) {
      router.push("/login");
      return;
    }
    const { data } = await supabase
      .from("workspace_members")
      .select("status")
      .eq("workspace_id", workspaceId)
      .eq("user_id", userId)
      .maybeSingle();
    if (!data) {
      toast("참여 요청이 거절되었습니다", "danger");
      router.push("/onboarding");
      router.refresh();
    } else if (data.status === "approved") {
      toast("🎉 환영합니다!", "success");
      router.push("/dashboard");
      router.refresh();
    } else {
      toast("아직 승인 대기 중이에요", "info");
    }
    setLoading(false);
  };

  const cancel = async () => {
    if (!confirm("참여 요청을 취소하시겠어요?")) return;
    setLoading(true);
    const supabase = createClient();
    const { data: userData } = await supabase.auth.getUser();
    const userId = userData.user?.id;
    if (!userId) return;
    await supabase
      .from("workspace_members")
      .delete()
      .eq("workspace_id", workspaceId)
      .eq("user_id", userId);
    router.push("/onboarding");
    router.refresh();
  };

  const signOut = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  };

  return (
    <div className="space-y-3">
      <Button variant="primary" fullWidth onClick={refresh} loading={loading}>
        승인 여부 새로고침
      </Button>
      <Button variant="secondary" fullWidth onClick={cancel} disabled={loading}>
        참여 요청 취소
      </Button>
      <button
        onClick={signOut}
        className="text-xs mt-4"
        style={{ color: "var(--text-tertiary)" }}
      >
        로그아웃
      </button>
    </div>
  );
}
