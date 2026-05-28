import Link from "next/link";

export const dynamic = "force-dynamic";

export default async function AuthErrorPage({
  searchParams,
}: {
  searchParams: Promise<{ msg?: string }>;
}) {
  const { msg } = await searchParams;

  return (
    <main className="min-h-screen flex items-center justify-center px-6" style={{ background: "var(--bg)" }}>
      <div className="text-center max-w-sm fadein">
        <div className="text-5xl mb-4">⚠️</div>
        <h1 className="text-xl font-bold mb-2">로그인에 실패했어요</h1>
        <p className="text-sm mb-2" style={{ color: "var(--text-secondary)" }}>
          잠시 후 다시 시도해 주세요. 문제가 계속되면 새 매직 링크를 받아 보세요.
        </p>
        {msg && (
          <p className="text-[11px] mb-6 font-mono break-words" style={{ color: "var(--text-tertiary)" }}>
            {msg}
          </p>
        )}
        <Link href="/login" className="btn-primary inline-block">
          로그인으로 돌아가기
        </Link>
      </div>
    </main>
  );
}
