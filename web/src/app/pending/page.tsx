import { redirect } from "next/navigation";
import { getAuthContext } from "@/lib/auth";
import { Card } from "@/components/ui/card";
import { PendingClient } from "./pending-client";

export const dynamic = "force-dynamic";

export default async function PendingPage() {
  const ctx = await getAuthContext();
  if (!ctx) redirect("/login");
  if (ctx.workspace) redirect("/dashboard");
  if (!ctx.pendingWorkspace) redirect("/onboarding");

  return (
    <main
      className="min-h-screen flex items-center justify-center px-6 relative overflow-hidden"
      style={{ background: "var(--bg)" }}
    >
      <div className="absolute inset-0 -z-10 mesh-bg" />
      <Card padding="lg" className="w-full max-w-sm text-center fadein">
        <div className="text-5xl mb-4">⏳</div>
        <h1 className="text-xl font-bold mb-2">승인 대기 중</h1>
        <p
          className="text-sm mb-6 leading-relaxed"
          style={{ color: "var(--text-secondary)" }}
        >
          <strong style={{ color: "var(--text)" }}>
            {ctx.pendingWorkspace.name}
          </strong>
          <br /> 방장의 승인을 기다리고 있어요
        </p>
        <PendingClient workspaceId={ctx.pendingWorkspace.id} />
      </Card>
    </main>
  );
}
