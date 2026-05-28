import type { HTMLAttributes } from "react";

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  hover?: boolean;
  padding?: "none" | "sm" | "md" | "lg";
}

const PAD = {
  none: "",
  sm: "p-3",
  md: "p-5",
  lg: "p-6",
};

export function Card({ hover, padding = "md", className = "", ...rest }: CardProps) {
  const cls = ["card", hover ? "card-hover" : "", PAD[padding], className].filter(Boolean).join(" ");
  return <div className={cls} {...rest} />;
}
