"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { toast } from "@/components/toast";

export function ProfileEditor({
  userId,
  email,
  displayName,
  avatarUrl,
}: {
  userId: string;
  email: string | null;
  displayName: string;
  avatarUrl: string | null;
}) {
  const router = useRouter();
  const [name, setName] = useState(displayName);
  const [saving, setSaving] = useState(false);

  const save = async () => {
    if (!name.trim() || name === displayName) return;
    setSaving(true);
    const supabase = createClient();
    const { error } = await supabase
      .from("profiles")
      .update({ display_name: name.trim() })
      .eq("id", userId);
    if (error) {
      toast("닉네임 변경 실패", "danger");
    } else {
      toast("닉네임이 변경되었어요", "success");
      router.refresh();
    }
    setSaving(false);
  };

  return (
    <div className="flex items-center gap-4">
      <Avatar name={displayName || email || "?"} url={avatarUrl} size={56} />
      <div className="flex-1 min-w-0">
        <input
          className="input"
          value={name}
          onChange={(e) => setName(e.target.value)}
          maxLength={20}
          placeholder="닉네임"
        />
        <p
          className="text-[11px] mt-1.5 truncate"
          style={{ color: "var(--text-tertiary)" }}
        >
          {email}
        </p>
      </div>
      <Button
        size="sm"
        onClick={save}
        loading={saving}
        disabled={!name.trim() || name === displayName}
      >
        저장
      </Button>
    </div>
  );
}
