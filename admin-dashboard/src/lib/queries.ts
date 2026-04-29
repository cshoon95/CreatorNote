import { supabase } from './supabase'
import type { Profile, AppEvent, ErrorLog, Workspace, WorkspaceMember } from './types'

export async function getProfiles(): Promise<Profile[]> {
  const { data, error } = await supabase.from('profiles').select('*').order('created_at', { ascending: false })
  if (error) throw error
  return data ?? []
}

export async function getAuthUsers(): Promise<{ id: string; email: string }[]> {
  const { data, error } = await supabase.auth.admin.listUsers({ perPage: 1000 })
  if (error) throw error
  return (data?.users ?? []).map(u => ({ id: u.id, email: u.email ?? '' }))
}

export async function getAppEvents(limit = 500): Promise<AppEvent[]> {
  const { data, error } = await supabase.from('app_events').select('*').order('created_at', { ascending: false }).limit(limit)
  if (error) throw error
  return data ?? []
}

export async function getAppEventsByUser(userId: string): Promise<AppEvent[]> {
  const { data, error } = await supabase.from('app_events').select('*').eq('user_id', userId).order('created_at', { ascending: false }).limit(500)
  if (error) throw error
  return data ?? []
}

export async function getErrorLogs(limit = 200): Promise<ErrorLog[]> {
  const { data, error } = await supabase.from('error_logs').select('*').order('created_at', { ascending: false }).limit(limit)
  if (error) throw error
  return data ?? []
}

export async function getErrorLogsByUser(userId: string): Promise<ErrorLog[]> {
  const { data, error } = await supabase.from('error_logs').select('*').eq('user_id', userId).order('created_at', { ascending: false }).limit(200)
  if (error) throw error
  return data ?? []
}

export async function getWorkspaces(): Promise<Workspace[]> {
  const { data, error } = await supabase.from('workspaces').select('*').order('created_at', { ascending: false })
  if (error) throw error
  return data ?? []
}

export async function getWorkspaceMembers(): Promise<WorkspaceMember[]> {
  const { data, error } = await supabase.from('workspace_members').select('*')
  if (error) throw error
  return data ?? []
}

export function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('ko-KR', { year: '2-digit', month: '2-digit', day: '2-digit' })
}

export function formatDateTime(dateStr: string): string {
  return new Date(dateStr).toLocaleString('ko-KR', {
    year: '2-digit', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit'
  })
}

export function formatTime(dateStr: string): string {
  return new Date(dateStr).toLocaleString('ko-KR', {
    hour: '2-digit', minute: '2-digit', second: '2-digit'
  })
}
