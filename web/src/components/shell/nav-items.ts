export interface NavItem {
  href: string;
  label: string;
  icon: string;
}

export const NAV_ITEMS: NavItem[] = [
  { href: "/dashboard", label: "홈", icon: "✨" },
  { href: "/sponsorships", label: "협찬", icon: "🤝" },
  { href: "/settlements", label: "정산", icon: "💰" },
  { href: "/notes", label: "노트", icon: "📝" },
  { href: "/calendar", label: "캘린더", icon: "📅" },
];
