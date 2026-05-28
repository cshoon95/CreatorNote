"use client";

import { createContext, useContext } from "react";

export interface WorkspaceCtx {
  userId: string;
  workspaceId: string;
  workspaceName: string;
  ownerId: string;
  displayName: string;
  avatarUrl: string | null;
}

const Ctx = createContext<WorkspaceCtx | null>(null);

export function WorkspaceProvider({
  value,
  children,
}: {
  value: WorkspaceCtx;
  children: React.ReactNode;
}) {
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useWorkspace(): WorkspaceCtx {
  const v = useContext(Ctx);
  if (!v) throw new Error("useWorkspace must be used inside (app)/layout");
  return v;
}
