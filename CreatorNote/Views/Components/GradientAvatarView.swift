import SwiftUI

struct GradientAvatarView: View {
    let text: String
    let gradient: [Color]
    var size: CGFloat = 52
    var font: Font = .title3.bold()

    var body: some View {
        ZStack {
            Circle()
                .fill(gradient.first ?? .blue)
                .frame(width: size, height: size)
            Text(String(text.prefix(1)))
                .font(font)
                .foregroundStyle(.white)
        }
    }
}
