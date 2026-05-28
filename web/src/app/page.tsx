import { redirect } from "next/navigation";
import { getAuthContext } from "@/lib/auth";

export const dynamic = "force-dynamic";

export default async function RootPage() {
  const ctx = await getAuthContext();
  if (!ctx) redirect("/login");
  if (ctx.pendingWorkspace && !ctx.workspace) redirect("/pending");
  if (!ctx.workspace) redirect("/onboarding");
  redirect("/dashboard");
}
