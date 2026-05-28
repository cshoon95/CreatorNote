"use client";

import { useState } from "react";
import { Modal } from "@/components/ui/modal";
import { Badge } from "@/components/ui/badge";
import { MembersClient } from "./members/members-client";
import { InvitesClient } from "./invites/invites-client";
import type { MemberRole, MemberStatus, Profile, InviteCode } from "@/lib/types";

interface MemberEntry {
  user_id: string;
  role: MemberRole;
  status: MemberStatus;
  profile: Profile | null;
}

interface SettingsClientProps {
  workspaceId: string;
  ownerId: string;
  currentUserId: string;
  isOwner: boolean;
  approvedMembers: MemberEntry[];
  pendingMembers: MemberEntry[];
  inviteCodes: InviteCode[];
}

export function SettingsClient({
  workspaceId,
  ownerId,
  currentUserId,
  isOwner,
  approvedMembers,
  pendingMembers,
  inviteCodes,
}: SettingsClientProps) {
  const [showMembers, setShowMembers] = useState(false);
  const [showInvites, setShowInvites] = useState(false);

  return (
    <>
      <div className="mt-5 flex flex-wrap gap-2">
        <button onClick={() => setShowMembers(true)} className="btn btn-secondary text-sm relative">
          멤버 관리
          {isOwner && pendingMembers.length > 0 && (
            <span
              className="absolute -top-1.5 -right-1.5 min-w-[18px] h-[18px] rounded-full text-[10px] font-bold flex items-center justify-center text-white px-1"
              style={{ background: "var(--danger)" }}
            >
              {pendingMembers.length}
            </span>
          )}
        </button>
        {isOwner && (
          <button onClick={() => setShowInvites(true)} className="btn btn-secondary text-sm">
            초대 코드
          </button>
        )}
      </div>

      <Modal open={showMembers} onClose={() => setShowMembers(false)} title="멤버" size="lg">
        <MembersClient
          workspaceId={workspaceId}
          ownerId={ownerId}
          currentUserId={currentUserId}
          isOwner={isOwner}
          approved={approvedMembers}
          pending={pendingMembers}
        />
      </Modal>

      {isOwner && (
        <Modal open={showInvites} onClose={() => setShowInvites(false)} title="초대 코드" size="lg">
          <InvitesClient workspaceId={workspaceId} userId={currentUserId} initialCodes={inviteCodes} />
        </Modal>
      )}
    </>
  );
}
