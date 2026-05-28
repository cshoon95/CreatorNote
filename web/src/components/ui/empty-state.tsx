import Link from "next/link";

interface EmptyStateProps {
  emoji?: string;
  title: string;
  description?: string;
  action?: { label: string; href: string };
}

export function EmptyState({ emoji = "✨", title, description, action }: EmptyStateProps) {
  return (
    <div className="text-center py-16 px-6 fadein">
      <div
        className="w-24 h-24 rounded-3xl flex items-center justify-center mx-auto mb-5 text-4xl"
        style={{ background: "var(--gradient-brand-soft)", boxShadow: "var(--shadow-md)" }}
      >
        {emoji}
      </div>
      <h3 className="text-lg font-bold mb-1.5">{title}</h3>
      {description && (
        <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
          {description}
        </p>
      )}
      {action && (
        <Link href={action.href} className="btn btn-primary mt-6 inline-flex">
          {action.label}
        </Link>
      )}
    </div>
  );
}
