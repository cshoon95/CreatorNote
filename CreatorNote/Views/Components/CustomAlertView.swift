import SwiftUI

@MainActor @Observable
final class AlertManager {
    static let shared = AlertManager()

    var isShowing = false
    var title = ""
    var message = ""
    var buttons: [AlertButton] = []

    private init() {}

    struct AlertButton {
        let title: String
        let role: ButtonRole?
        let action: () -> Void

        init(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void = {}) {
            self.title = title
            self.role = role
            self.action = action
        }
    }

    func show(
        title: String,
        message: String = "",
        buttons: [AlertButton] = [AlertButton("확인")]
    ) {
        self.title = title
        self.message = message
        self.buttons = buttons
        withAnimation(.spring(duration: 0.3)) {
            isShowing = true
        }
    }

    func confirm(
        title: String,
        message: String = "",
        confirmTitle: String = "삭제",
        confirmRole: ButtonRole? = .destructive,
        onConfirm: @escaping () -> Void
    ) {
        show(
            title: title,
            message: message,
            buttons: [
                AlertButton("취소", role: .cancel, action: {}),
                AlertButton(confirmTitle, role: confirmRole, action: onConfirm)
            ]
        )
    }

    func dismiss() {
        withAnimation(.spring(duration: 0.25)) {
            isShowing = false
        }
    }
}

struct CustomAlertOverlay: ViewModifier {
    let alert = AlertManager.shared

    private let skyBlue = Color(hex: "4A9FF5")

    func body(content: Content) -> some View {
        content.overlay {
            if alert.isShowing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        alert.dismiss()
                    }

                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text(alert.title)
                            .font(.headline)
                            .foregroundStyle(Color(hex: "1A1A2E"))
                            .multilineTextAlignment(.center)

                        if !alert.message.isEmpty {
                            Text(alert.message)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "6B6B8D"))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                    Divider().opacity(0.3)

                    if alert.buttons.count == 2 {
                        HStack(spacing: 0) {
                            ForEach(alert.buttons.indices, id: \.self) { i in
                                let btn = alert.buttons[i]
                                Button {
                                    alert.dismiss()
                                    btn.action()
                                } label: {
                                    Text(btn.title)
                                        .font(.system(.body, weight: btn.role == .cancel ? .regular : .semibold))
                                        .foregroundStyle(
                                            btn.role == .destructive ? Color(hex: "FF4757") : skyBlue
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                                if i == 0 {
                                    Divider().frame(height: 44).opacity(0.3)
                                }
                            }
                        }
                    } else {
                        ForEach(alert.buttons.indices, id: \.self) { i in
                            let btn = alert.buttons[i]
                            if i > 0 { Divider().opacity(0.3) }
                            Button {
                                alert.dismiss()
                                btn.action()
                            } label: {
                                Text(btn.title)
                                    .font(.system(.body, weight: .semibold))
                                    .foregroundStyle(skyBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                    }
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
                .padding(.horizontal, 48)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: alert.isShowing)
    }
}

extension View {
    func withCustomAlert() -> some View {
        modifier(CustomAlertOverlay())
    }
}
