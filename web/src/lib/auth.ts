import { createClient } from "@/lib/supabase/server";
import type { Profile, Workspace, MemberStatus } from "@/lib/types";

export interface AuthContext {
  userId: string;
  email: string | null;
  profile: Profile | null;
  workspace: Workspace | null;
  pendingWorkspace: Workspace | null;
}

/**
 * Resolve the current request's auth + active workspace.
 *
 * - userId: required (middleware blocks unauthenticated traffic to /(app))
 * - workspace: approved membership the user owns/joined (may be null → onboarding)
 * - pendingWorkspace: user has applied via invite but not yet approved
 */
export async function getAuthContext(): Promise<AuthContext | null> {
  const supabase = await createClient();
  const { data: userData } = await supabase.auth.getUser();
  const user = userData.user;
  if (!user) return null;

  const [{ data: profile }, { data: memberships }] = await Promise.all([
    supabase.from("profiles").select("*").eq("id", user.id).maybeSingle(),
    supabase
      .from("workspace_members")
      .select("workspace_id, status")
      .eq("user_id", user.id),
  ]);

  const rows = (memberships ?? []) as { workspace_id: string; status: MemberStatus }[];
  const approved = rows.find((r) => r.status === "approved");
  const pending = rows.find((r) => r.status === "pending");

  let workspace: Workspace | null = null;
  let pendingWorkspace: Workspace | null = null;

  if (approved) {
    const { data } = await supabase
      .from("workspaces")
      .select("*")
      .eq("id", approved.workspace_id)
      .maybeSingle();
    workspace = (data as Workspace | null) ?? null;
  }
  if (pending) {
    const { data } = await supabase
      .from("workspaces")
      .select("*")
      .eq("id", pending.workspace_id)
      .maybeSingle();
    pendingWorkspace = (data as Workspace | null) ?? null;
  }

  return {
    userId: user.id,
    email: user.email ?? null,
    profile: (profile as Profile | null) ?? null,
    workspace,
    pendingWorkspace,
  };
}
