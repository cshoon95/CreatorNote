import { redirect } from "next/navigation";
import { getAuthContext } from "@/lib/auth";
import { Sidebar } from "@/components/shell/sidebar";
import { BottomNav } from "@/components/shell/bottom-nav";
import { MobileHeader } from "@/components/shell/mobile-header";
import { Fab } from "@/components/shell/fab";
import { WorkspaceProvider } from "@/components/workspace-context";
import { CommandPalette } from "@/components/command-palette";
import { KeyboardShortcuts } from "@/components/keyboard-shortcuts";

export const dynamic = "force-dynamic";

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const ctx = await getAuthContext();
  if (!ctx) redirect("/login");
  if (ctx.pendingWorkspace && !ctx.workspace) redirect("/pending");
  if (!ctx.workspace) redirect("/onboarding");

  const displayName = ctx.profile?.display_name ?? "사용자";

  return (
    <WorkspaceProvider
      value={{
        userId: ctx.userId,
        workspaceId: ctx.workspace.id,
        workspaceName: ctx.workspace.name,
        ownerId: ctx.workspace.owner_id,
        displayName,
        avatarUrl: ctx.profile?.avatar_url ?? null,
      }}
    >
      <Sidebar
        workspaceName={ctx.workspace.name}
        displayName={displayName}
        email={ctx.email}
        avatarUrl={ctx.profile?.avatar_url ?? null}
      />
      <MobileHeader />
      <main className="lg:ml-64 pb-24 lg:pb-12">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-10 py-5 lg:py-10 fadein">
          {children}
        </div>
      </main>
      <BottomNav />
      <Fab />
      <CommandPalette />
      <KeyboardShortcuts />
    </WorkspaceProvider>
  );
}
