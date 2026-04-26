import SwiftUI

@MainActor @Observable
final class ToastManager {
    static let shared = ToastManager()

    var message: String = ""
    var icon: String = "checkmark.circle.fill"
    var isShowing: Bool = false

    private var dismissTask: Task<Void, Never>?
    private init() {}

    func show(_ message: String, icon: String = "checkmark.circle.fill") {
        dismissTask?.cancel()
        self.message = message
        self.icon = icon

        withAnimation(.spring(duration: 0.3)) {
            isShowing = true
        }

        dismissTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                isShowing = false
            }
        }
    }
}

struct ToastOverlay: ViewModifier {
    let toast = ToastManager.shared

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if toast.isShowing {
                HStack(spacing: 8) {
                    Image(systemName: toast.icon)
                        .font(.system(size: 16, weight: .semibold))
                    Text(toast.message)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.black.opacity(0.75))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                .padding(.bottom, 60)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

extension View {
    func withToast() -> some View {
        modifier(ToastOverlay())
    }
}
