import SwiftUI
import SDWebImageSwiftUI

// MARK: - Full-screen image viewer

struct FullScreenImageViewer: View {
    let url: String
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let imageURL = URL(string: url) {
                WebImage(url: imageURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView().tint(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(.top, 60)
            .padding(.trailing, 16)
        }
    }
}

// MARK: - Circular profile image (matches Android AsyncImage with Coil + CircleShape)

struct ProfileImageView: View {
    let url: String?
    var size: CGFloat = 48
    var borderWidth: CGFloat = 1.5
    var borderColor: Color = .bordeTuProfe
    var isViewable: Bool = false

    @State private var showViewer = false

    var body: some View {
        // Only add tap gesture when explicitly viewable — otherwise the outer Button
        // (e.g. professor redirect in ReviewCardView) would be silently blocked.
        if isViewable, let urlString = url, !urlString.isEmpty {
            baseImage
                .onTapGesture { showViewer = true }
                .fullScreenCover(isPresented: $showViewer) {
                    FullScreenImageViewer(url: urlString) { showViewer = false }
                }
        } else {
            baseImage
        }
    }

    @ViewBuilder
    private var baseImage: some View {
        Group {
            if let urlString = url, !urlString.isEmpty, let imageURL = URL(string: urlString) {
                WebImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    avatarPlaceholder
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.3))
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(borderColor, lineWidth: borderWidth))
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFill()
            .foregroundColor(.secondary)
            .background(Color.tpSurfaceVariantLight)
    }
}

// MARK: - Large professor image card (matches Android ProfessorInfoCard image)

struct ProfessorImageView: View {
    let url: String?
    var size: CGFloat = 110
    var isViewable: Bool = false

    @State private var showViewer = false

    var body: some View {
        if isViewable, let urlString = url, !urlString.isEmpty {
            baseImage
                .onTapGesture { showViewer = true }
                .fullScreenCover(isPresented: $showViewer) {
                    FullScreenImageViewer(url: urlString) { showViewer = false }
                }
        } else {
            baseImage
        }
    }

    @ViewBuilder
    private var baseImage: some View {
        Group {
            if let urlString = url, !urlString.isEmpty, let imageURL = URL(string: urlString) {
                WebImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.secondary)
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.3))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.bordeTuProfe.opacity(0.4), lineWidth: 2))
        .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Shimmer skeleton for profile image

struct ProfileImageSkeleton: View {
    var size: CGFloat = 48

    var body: some View {
        Circle()
            .fill(Color.tpSurfaceVariantLight)
            .frame(width: size, height: size)
            .shimmerEffect()
    }
}
