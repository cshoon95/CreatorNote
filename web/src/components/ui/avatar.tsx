interface AvatarProps {
  name?: string | null;
  url?: string | null;
  size?: number;
}

const GRADIENTS = [
  "linear-gradient(135deg, #7c3aed, #ec4899)",
  "linear-gradient(135deg, #2563eb, #06b6d4)",
  "linear-gradient(135deg, #f59e0b, #ec4899)",
  "linear-gradient(135deg, #10b981, #06b6d4)",
  "linear-gradient(135deg, #f43f5e, #f59e0b)",
  "linear-gradient(135deg, #8b5cf6, #3b82f6)",
];

function gradientFor(name?: string | null): string {
  if (!name) return GRADIENTS[0];
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h << 5) - h + name.charCodeAt(i);
  return GRADIENTS[Math.abs(h) % GRADIENTS.length];
}

export function Avatar({ name, url, size = 40 }: AvatarProps) {
  if (url) {
    // eslint-disable-next-line @next/next/no-img-element
    return (
      <img
        src={url}
        alt=""
        width={size}
        height={size}
        className="rounded-full object-cover flex-shrink-0"
        style={{ width: size, height: size }}
      />
    );
  }
  return (
    <div
      className="rounded-full flex items-center justify-center text-white font-bold flex-shrink-0"
      style={{
        width: size,
        height: size,
        background: gradientFor(name),
        fontSize: size * 0.42,
      }}
    >
      {(name ?? "?").slice(0, 1).toUpperCase()}
    </div>
  );
}
