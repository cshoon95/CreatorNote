interface SkeletonProps {
  width?: number | string;
  height?: number | string;
  rounded?: number | string;
  className?: string;
}

export function Skeleton({ width = "100%", height = 16, rounded = 8, className = "" }: SkeletonProps) {
  return (
    <div
      className={`shimmer ${className}`}
      style={{ width, height, borderRadius: rounded }}
      aria-hidden
    />
  );
}
