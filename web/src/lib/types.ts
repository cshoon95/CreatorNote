// Mirrors the iOS DTOs and Supabase tables.

export type SponsorshipStatus =
  | "preSubmit"
  | "underReview"
  | "submitted" // legacy, hidden in UI
  | "pendingSettlement"
  | "completed";

export type ReelsNoteStatus = "drafting" | "readyToUpload" | "uploaded";
export type MemberRole = "owner" | "member";
export type MemberStatus = "pending" | "approved";

export interface Profile {
  id: string;
  display_name: string | null;
  avatar_url: string | null;
  provider: string | null;
  created_at: string;
}

export interface Workspace {
  id: string;
  name: string;
  owner_id: string;
  created_at: string;
}

export interface WorkspaceMember {
  workspace_id: string;
  user_id: string;
  role: MemberRole;
  status: MemberStatus;
  joined_at: string;
}

export interface InviteCode {
  id: string;
  workspace_id: string;
  code: string;
  created_by: string;
  expires_at: string | null;
  max_uses: number;
  used_count: number;
  is_active: boolean;
  created_at: string;
}

export interface Sponsorship {
  id: string;
  workspace_id: string;
  created_by: string | null;
  brand_name: string;
  product_name: string | null;
  details: string | null;
  amount: number;
  start_date: string | null;
  end_date: string | null;
  status: SponsorshipStatus;
  is_pinned: boolean;
  created_at: string;
  updated_at: string;
}

export interface Settlement {
  id: string;
  workspace_id: string;
  created_by: string | null;
  sponsorship_id: string | null;
  brand_name: string;
  amount: number;
  fee: number;
  tax: number;
  settlement_date: string | null;
  is_paid: boolean;
  memo: string | null;
  created_at: string;
  updated_at: string;
}

export interface ReelsNote {
  id: string;
  workspace_id: string;
  created_by: string | null;
  title: string;
  attributed_content: string | null;
  plain_content: string;
  status: ReelsNoteStatus;
  sponsorship_id: string | null;
  tags: string[];
  image_urls: string[];
  is_pinned: boolean;
  created_at: string;
  updated_at: string;
}

export interface GeneralNote {
  id: string;
  workspace_id: string;
  created_by: string | null;
  title: string;
  attributed_content: string | null;
  plain_content: string;
  tags: string[];
  image_urls: string[];
  is_pinned: boolean;
  created_at: string;
  updated_at: string;
}

// Database type for @supabase/ssr generic param.
// We declare each public table's row / insert / update shapes so query results
// are properly typed and not collapsed to `never`.

type TableDef<Row, Insert = Partial<Row>, Update = Partial<Row>> = {
  Row: Row;
  Insert: Insert;
  Update: Update;
};

type SponsorshipInsert = {
  workspace_id: string;
  created_by?: string | null;
  brand_name: string;
  product_name?: string | null;
  details?: string | null;
  amount?: number;
  start_date?: string | null;
  end_date?: string | null;
  status?: SponsorshipStatus;
  is_pinned?: boolean;
};

type SettlementInsert = {
  workspace_id: string;
  created_by?: string | null;
  sponsorship_id?: string | null;
  brand_name: string;
  amount?: number;
  fee?: number;
  tax?: number;
  settlement_date?: string | null;
  is_paid?: boolean;
  memo?: string | null;
};

type NoteInsert<S = never> = {
  workspace_id: string;
  created_by?: string | null;
  title?: string;
  attributed_content?: string | null;
  plain_content?: string;
  status?: S;
  sponsorship_id?: string | null;
  tags?: string[];
  image_urls?: string[];
  is_pinned?: boolean;
};

type InviteCodeInsert = {
  workspace_id: string;
  code: string;
  created_by: string;
  expires_at?: string | null;
  max_uses?: number;
  used_count?: number;
  is_active?: boolean;
};

type WorkspaceMemberInsert = {
  workspace_id: string;
  user_id: string;
  role: MemberRole;
  status: MemberStatus;
};

type WorkspaceInsert = {
  name: string;
  owner_id: string;
};

type ProfileInsert = {
  id: string;
  display_name?: string | null;
  avatar_url?: string | null;
  provider?: string | null;
};

export interface Database {
  public: {
    Tables: {
      profiles: TableDef<Profile, ProfileInsert>;
      workspaces: TableDef<Workspace, WorkspaceInsert>;
      workspace_members: TableDef<WorkspaceMember, WorkspaceMemberInsert>;
      invite_codes: TableDef<InviteCode, InviteCodeInsert>;
      sponsorships: TableDef<Sponsorship, SponsorshipInsert>;
      settlements: TableDef<Settlement, SettlementInsert>;
      reels_notes: TableDef<ReelsNote, NoteInsert<ReelsNoteStatus>>;
      general_notes: TableDef<GeneralNote, NoteInsert>;
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
  };
}

// UI helpers — display labels.
export const SPONSORSHIP_STATUS_LABEL: Record<SponsorshipStatus, string> = {
  preSubmit: "제출 전",
  underReview: "검수중",
  submitted: "제출 완료",
  pendingSettlement: "정산 대기",
  completed: "완료",
};

export const SPONSORSHIP_STATUS_COLOR: Record<SponsorshipStatus, string> = {
  preSubmit: "#94a3b8",
  underReview: "#3b82f6",
  submitted: "#22c55e",
  pendingSettlement: "#f59e0b",
  completed: "#22c55e",
};

export const REELS_STATUS_LABEL: Record<ReelsNoteStatus, string> = {
  drafting: "작성중",
  readyToUpload: "업로드 대기",
  uploaded: "업로드 완료",
};

export const REELS_STATUS_COLOR: Record<ReelsNoteStatus, string> = {
  drafting: "#f59e0b",
  readyToUpload: "#3b82f6",
  uploaded: "#22c55e",
};

// Form list values for selection UI (excludes legacy `submitted`)
export const ACTIVE_SPONSORSHIP_STATUSES: SponsorshipStatus[] = [
  "preSubmit",
  "underReview",
  "pendingSettlement",
  "completed",
];
