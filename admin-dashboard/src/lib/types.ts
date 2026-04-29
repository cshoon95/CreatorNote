export interface Profile {
  id: string
  display_name: string | null
  avatar_url: string | null
  provider: string | null
  created_at: string
}

export interface AppEvent {
  id: string
  user_id: string | null
  workspace_id: string | null
  event_type: string
  event_name: string
  metadata: Record<string, string>
  created_at: string
}

export interface ErrorLog {
  id: string
  user_id: string | null
  error_type: string
  error_message: string
  stack_trace: string | null
  screen: string | null
  device_info: Record<string, string>
  created_at: string
}

export interface Workspace {
  id: string
  name: string
  owner_id: string
  created_at: string
}

export interface WorkspaceMember {
  workspace_id: string
  user_id: string
  role: 'owner' | 'member'
  joined_at: string
}
