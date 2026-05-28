"use client";

import { useState, type KeyboardEvent } from "react";

interface TagInputProps {
  tags: string[];
  onChange: (next: string[]) => void;
  placeholder?: string;
}

export function TagInput({ tags, onChange, placeholder = "태그 입력 후 Enter" }: TagInputProps) {
  const [draft, setDraft] = useState("");

  const add = (raw: string) => {
    const v = raw.trim().replace(/^#/, "");
    if (!v) return;
    if (tags.includes(v)) return;
    onChange([...tags, v]);
  };

  const onKey = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter" || e.key === ",") {
      e.preventDefault();
      add(draft);
      setDraft("");
    } else if (e.key === "Backspace" && !draft && tags.length > 0) {
      onChange(tags.slice(0, -1));
    }
  };

  return (
    <div
      className="flex flex-wrap items-center gap-1.5 px-2 py-2 rounded-xl"
      style={{ background: "var(--card)", border: "1px solid var(--border)" }}
    >
      {tags.map((t) => (
        <span
          key={t}
          className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold"
          style={{ background: "var(--primary-soft)", color: "var(--primary)" }}
        >
          #{t}
          <button
            type="button"
            onClick={() => onChange(tags.filter((x) => x !== t))}
            aria-label={`${t} 제거`}
            className="opacity-70 hover:opacity-100"
          >
            ✕
          </button>
        </span>
      ))}
      <input
        className="flex-1 min-w-[120px] bg-transparent outline-none text-sm py-1 px-1"
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={onKey}
        placeholder={tags.length === 0 ? placeholder : ""}
      />
    </div>
  );
}
