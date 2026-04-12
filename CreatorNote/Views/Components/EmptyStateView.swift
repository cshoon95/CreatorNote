import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(color.opacity(0.5))
            }
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 80)
    }
}
