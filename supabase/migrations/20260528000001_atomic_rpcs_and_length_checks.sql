-- ============================================================
-- Atomic RPCs + length constraints (defense-in-depth)
-- Idempotent — safe to re-run.
-- ============================================================

-- 1. redeem_invite — atomic join with used_count increment
CREATE OR REPLACE FUNCTION public.redeem_invite(invite_code text)
RETURNS uuid AS $$
DECLARE
  v_invite public.invite_codes%rowtype;
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_invite
  FROM public.invite_codes
  WHERE code = upper(trim(invite_code))
    AND is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or inactive invite code';
  END IF;

  IF v_invite.expires_at IS NOT NULL AND v_invite.expires_at < now() THEN
    RAISE EXCEPTION 'Invite code expired';
  END IF;

  IF v_invite.max_uses > 0 AND v_invite.used_count >= v_invite.max_uses THEN
    RAISE EXCEPTION 'Invite code reached maximum uses';
  END IF;

  -- Already a member? return existing workspace id (no duplicate insert)
  IF EXISTS (
    SELECT 1 FROM public.workspace_members
    WHERE workspace_id = v_invite.workspace_id AND user_id = v_user_id
  ) THEN
    RETURN v_invite.workspace_id;
  END IF;

  INSERT INTO public.workspace_members (workspace_id, user_id, role, status)
  VALUES (v_invite.workspace_id, v_user_id, 'member', 'pending');

  UPDATE public.invite_codes
  SET used_count = used_count + 1
  WHERE id = v_invite.id;

  RETURN v_invite.workspace_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. create_workspace_with_owner — atomic workspace + owner membership
CREATE OR REPLACE FUNCTION public.create_workspace_with_owner(ws_name text)
RETURNS uuid AS $$
DECLARE
  v_ws_id uuid;
  v_user_id uuid := auth.uid();
  v_clean text := trim(ws_name);
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF char_length(v_clean) = 0 OR char_length(v_clean) > 60 THEN
    RAISE EXCEPTION 'Workspace name must be 1-60 chars';
  END IF;

  -- Prevent users from owning > 5 workspaces (light abuse guard)
  IF (SELECT count(*) FROM public.workspaces WHERE owner_id = v_user_id) >= 5 THEN
    RAISE EXCEPTION 'Workspace limit reached (max 5 per owner)';
  END IF;

  INSERT INTO public.workspaces (name, owner_id)
  VALUES (v_clean, v_user_id)
  RETURNING id INTO v_ws_id;

  INSERT INTO public.workspace_members (workspace_id, user_id, role, status)
  VALUES (v_ws_id, v_user_id, 'owner', 'approved');

  RETURN v_ws_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Length CHECK constraints (drop + recreate so this is idempotent)
ALTER TABLE public.workspaces DROP CONSTRAINT IF EXISTS workspaces_name_len;
ALTER TABLE public.workspaces ADD CONSTRAINT workspaces_name_len CHECK (char_length(name) BETWEEN 1 AND 60);

ALTER TABLE public.sponsorships DROP CONSTRAINT IF EXISTS sponsorships_brand_len;
ALTER TABLE public.sponsorships ADD CONSTRAINT sponsorships_brand_len CHECK (char_length(brand_name) BETWEEN 1 AND 80);
ALTER TABLE public.sponsorships DROP CONSTRAINT IF EXISTS sponsorships_product_len;
ALTER TABLE public.sponsorships ADD CONSTRAINT sponsorships_product_len CHECK (product_name IS NULL OR char_length(product_name) <= 200);
ALTER TABLE public.sponsorships DROP CONSTRAINT IF EXISTS sponsorships_details_len;
ALTER TABLE public.sponsorships ADD CONSTRAINT sponsorships_details_len CHECK (details IS NULL OR char_length(details) <= 5000);

ALTER TABLE public.settlements DROP CONSTRAINT IF EXISTS settlements_brand_len;
ALTER TABLE public.settlements ADD CONSTRAINT settlements_brand_len CHECK (char_length(brand_name) BETWEEN 1 AND 80);
ALTER TABLE public.settlements DROP CONSTRAINT IF EXISTS settlements_memo_len;
ALTER TABLE public.settlements ADD CONSTRAINT settlements_memo_len CHECK (memo IS NULL OR char_length(memo) <= 1000);

ALTER TABLE public.reels_notes DROP CONSTRAINT IF EXISTS reels_notes_title_len;
ALTER TABLE public.reels_notes ADD CONSTRAINT reels_notes_title_len CHECK (char_length(title) <= 200);
ALTER TABLE public.reels_notes DROP CONSTRAINT IF EXISTS reels_notes_content_len;
ALTER TABLE public.reels_notes ADD CONSTRAINT reels_notes_content_len CHECK (char_length(plain_content) <= 50000);

ALTER TABLE public.general_notes DROP CONSTRAINT IF EXISTS general_notes_title_len;
ALTER TABLE public.general_notes ADD CONSTRAINT general_notes_title_len CHECK (char_length(title) <= 200);
ALTER TABLE public.general_notes DROP CONSTRAINT IF EXISTS general_notes_content_len;
ALTER TABLE public.general_notes ADD CONSTRAINT general_notes_content_len CHECK (char_length(plain_content) <= 50000);

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_display_name_len;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_display_name_len CHECK (display_name IS NULL OR char_length(display_name) <= 30);

-- 4. Grant execute to authenticated role
GRANT EXECUTE ON FUNCTION public.redeem_invite(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_workspace_with_owner(text) TO authenticated;
