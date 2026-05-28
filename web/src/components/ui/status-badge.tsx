import { Badge } from "./badge";
import {
  SPONSORSHIP_STATUS_LABEL,
  REELS_STATUS_LABEL,
  type SponsorshipStatus,
  type ReelsNoteStatus,
} from "@/lib/types";

const SPONSOR_TONE: Record<SponsorshipStatus, "default" | "info" | "warning" | "success"> = {
  preSubmit: "default",
  underReview: "info",
  submitted: "success",
  pendingSettlement: "warning",
  completed: "success",
};

const REELS_TONE: Record<ReelsNoteStatus, "warning" | "info" | "success"> = {
  drafting: "warning",
  readyToUpload: "info",
  uploaded: "success",
};

export function SponsorshipBadge({ status }: { status: SponsorshipStatus }) {
  return <Badge tone={SPONSOR_TONE[status]}>{SPONSORSHIP_STATUS_LABEL[status]}</Badge>;
}

export function ReelsBadge({ status }: { status: ReelsNoteStatus }) {
  return <Badge tone={REELS_TONE[status]}>{REELS_STATUS_LABEL[status]}</Badge>;
}
