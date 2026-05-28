import { redirect } from "next/navigation";
import { getAuthContext } from "@/lib/auth";
import { OnboardingForm } from "./onboarding-form";

export const dynamic = "force-dynamic";

export default async function OnboardingPage() {
  const ctx = await getAuthContext();
  if (!ctx) redirect("/login");
  if (ctx.workspace) redirect("/dashboard");
  if (ctx.pendingWorkspace) redirect("/pending");

  return (
    <main
      className="min-h-screen flex items-center justify-center px-6 py-12 relative overflow-hidden"
      style={{ background: "var(--bg)" }}
    >
      <div className="absolute inset-0 -z-10 mesh-bg" />
      <div className="w-full max-w-md fadein">
        <div className="text-center mb-8">
          <div className="text-5xl mb-3">👋</div>
          <h1 className="text-3xl font-bold tracking-tight">
            <span className="text-gradient">환영합니다!</span>
          </h1>
          <p className="text-sm mt-2" style={{ color: "var(--text-secondary)" }}>
            워크스페이스를 만들거나 초대 코드로 참여하세요
          </p>
        </div>
        <OnboardingForm displayName={ctx.profile?.display_name ?? null} />
      </div>
    </main>
  );
}
