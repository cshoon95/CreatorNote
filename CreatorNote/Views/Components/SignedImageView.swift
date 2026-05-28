import SwiftUI

struct SignedImageView: View {
    let path: String
    var size: CGFloat = 100
    var cornerRadius: CGFloat = 12
    var placeholder: Color = .gray.opacity(0.2)

    @State private var url: URL?

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Rectangle().fill(placeholder)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task {
            url = await StorageManager.shared.signedURL(for: path)
        }
    }
}
