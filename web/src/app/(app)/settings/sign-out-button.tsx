"use client";

import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";

export function SignOutButton() {
  const router = useRouter();
  const signOut = async () => {
    if (!confirm("로그아웃하시겠어요?")) return;
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  };
  return (
    <Button variant="danger" size="md" onClick={signOut}>
      로그아웃
    </Button>
  );
}
