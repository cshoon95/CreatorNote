# CreatorNote Web

iOS 앱(`CreatorNote`)의 사용자용 웹 버전. 모바일웹/PC웹 모두 지원하는 반응형 Next.js 앱.

## 기술 스택

- Next.js 16 (App Router) + React 19
- Tailwind CSS v4
- Supabase JS + `@supabase/ssr` (Google/Apple OAuth)

## 개발

```bash
npm install
cp .env.example .env.local   # 필요 시 수정
npm run dev                  # http://localhost:3000
```

## 디렉터리

```
src/
  app/
    (app)/            보호된 영역 (워크스페이스 필수)
      dashboard
      sponsorships
      settlements
      notes
      calendar
      search
      settings
    login             로그인 화면
    auth/callback     OAuth 콜백
    onboarding        워크스페이스 생성/참여
    pending           승인 대기
  components/         재사용 UI
  lib/
    supabase/         브라우저·서버·미들웨어 클라이언트
    queries/          엔티티별 서버 액션 / RPC
```

## 인증 흐름

1. `/login` → Google/Apple OAuth → Supabase가 세션 쿠키 발급
2. `/auth/callback` 라우트에서 코드 교환 후 `/`로 리다이렉트
3. 미들웨어가 세션·워크스페이스 상태에 따라 라우팅 분기
   - 세션 없음 → `/login`
   - 워크스페이스 없음 → `/onboarding`
   - 승인 대기 → `/pending`
   - 정상 → `/dashboard`

## iOS 앱과의 관계

같은 Supabase 프로젝트를 공유하므로 데이터는 양쪽에서 동기화됩니다. 스키마/RLS는 `supabase_migration.sql` + `supabase/migrations/*` 참조.
