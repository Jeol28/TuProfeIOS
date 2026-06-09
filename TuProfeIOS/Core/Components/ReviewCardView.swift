import SwiftUI
import UIKit
import SDWebImageSwiftUI

// MARK: - Image mosaic (up to 4 images, Twitter/X style)

struct ReviewImageMosaicView: View {
    let imageUrls: [String]
    @State private var viewerUrl: String? = nil

    private var urls: [String] { Array(imageUrls.prefix(4)) }

    private var totalHeight: CGFloat {
        switch urls.count {
        case 1: return 200
        case 4: return 240
        default: return 160
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Visual layer: images rendered without any hit-testing participation.
            // scaledToFill can make the underlying UIView larger than the SwiftUI
            // frame, but .allowsHitTesting(false) removes it from touch dispatch entirely.
            visualLayer
                .allowsHitTesting(false)

            // Hit-test layer: Color.clear views with exact frame bounds.
            // Color.clear never produces an oversized UIView, so there is zero
            // overflow — the tap area is guaranteed to match the visible cell.
            GeometryReader { geo in
                hitLayer(w: geo.size.width)
            }
        }
        .frame(height: totalHeight)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .fullScreenCover(
            isPresented: Binding(get: { viewerUrl != nil }, set: { if !$0 { viewerUrl = nil } })
        ) {
            if let url = viewerUrl {
                FullScreenImageViewer(url: url) { viewerUrl = nil }
            }
        }
    }

    // MARK: Visual (non-interactive)

    @ViewBuilder
    private var visualLayer: some View {
        if urls.count == 1 {
            imageCell(urls[0]).frame(maxWidth: .infinity).frame(height: 200)
        } else if urls.count == 2 {
            HStack(spacing: 2) {
                imageCell(urls[0])
                imageCell(urls[1])
            }.frame(height: 160)
        } else if urls.count == 3 {
            HStack(spacing: 2) {
                imageCell(urls[0])
                VStack(spacing: 2) {
                    imageCell(urls[1])
                    imageCell(urls[2])
                }
            }.frame(height: 160)
        } else {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    imageCell(urls[0])
                    imageCell(urls[1])
                }
                HStack(spacing: 2) {
                    imageCell(urls[2])
                    imageCell(urls[3])
                }
            }.frame(height: 240)
        }
    }

    @ViewBuilder
    private func imageCell(_ url: String) -> some View {
        if let imageURL = URL(string: url) {
            WebImage(url: imageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: { Color.gray.opacity(0.1) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        } else {
            Color.gray.opacity(0.2)
        }
    }

    // MARK: Hit targets (invisible, exact-frame Color.clear)

    @ViewBuilder
    private func hitLayer(w: CGFloat) -> some View {
        if urls.count == 1 {
            tap(urls[0], w: w, h: 200)
        } else if urls.count == 2 {
            HStack(spacing: 2) {
                tap(urls[0], w: (w - 2) / 2, h: 160)
                tap(urls[1], w: (w - 2) / 2, h: 160)
            }
        } else if urls.count == 3 {
            HStack(spacing: 2) {
                tap(urls[0], w: (w - 2) / 2, h: 160)
                VStack(spacing: 2) {
                    tap(urls[1], w: (w - 2) / 2, h: 79)
                    tap(urls[2], w: (w - 2) / 2, h: 79)
                }
            }
        } else if urls.count >= 4 {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    tap(urls[0], w: (w - 2) / 2, h: 119)
                    tap(urls[1], w: (w - 2) / 2, h: 119)
                }
                HStack(spacing: 2) {
                    tap(urls[2], w: (w - 2) / 2, h: 119)
                    tap(urls[3], w: (w - 2) / 2, h: 119)
                }
            }
        }
    }

    private func tap(_ url: String, w: CGFloat, h: CGFloat) -> some View {
        Color.clear
            .frame(width: w, height: h)
            .contentShape(Rectangle())
            .onTapGesture { viewerUrl = url }
    }
}

// MARK: - Review Card (matches Android ResenaCard + Resena composable)

struct ReviewCardView: View {
    let review: ReviewInfo
    var onTap: (() -> Void)? = nil
    var onProfessorTap: (() -> Void)? = nil
    var onUserTap: (() -> Void)? = nil
    var onLike: (() -> Void)? = nil  // kept for API compatibility, not shown in card

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 8) {
                CardHeaderSection(review: review, onProfessorTap: onProfessorTap, onUserTap: onUserTap)

                StarRatingView(rating: Double(review.rating), starSize: 22)
                    .padding(.leading, 2)

                CardBodySection(review: review)

                CardFooterSection(likes: review.likes, comments: review.commentsCount)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.pastel)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .strokeBorder(Color.bordeTuProfe, lineWidth: 2.5)
            )
            .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 18)
            .padding(.vertical, 5)
        }
        .buttonStyle(CardPressButtonStyle())
    }
}

// MARK: - Card header: photo + professor name + "Por: @user" + materia

struct CardHeaderSection: View {
    let review: ReviewInfo
    var onProfessorTap: (() -> Void)?
    var onUserTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { onProfessorTap?() }) {
                ProfileImageView(url: review.profesor.imageprofeUrl, size: 48)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .center) {
                    Button(action: { onProfessorTap?() }) {
                        Text(review.profesor.nombreProfe)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer(minLength: 8)

                    Button(action: { onUserTap?() }) {
                        Text("Por: @\(review.usuario.perfilAnonimo ? NSLocalizedString("Anónimo", comment: "") : review.usuario.nombreUsu)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Text(review.materia.nombreMateria)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Card body: content + date + editado badge

struct CardBodySection: View {
    let review: ReviewInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(review.content)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            if !review.imageUrls.isEmpty {
                ReviewImageMosaicView(imageUrls: review.imageUrls)
            }

            HStack(spacing: 8) {
                Text(review.time)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                if review.editado {
                    Text("Editado")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.verdetp)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.verdetp.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding(.leading, 2)
    }
}

// MARK: - Card footer: "X Likes  X Comentarios"

struct CardFooterSection: View {
    let likes: Int
    let comments: Int

    var body: some View {
        HStack(spacing: 0) {
            CardFooterItem(count: likes, label: "Likes")
            CardFooterItem(count: comments, label: "Comentarios")
        }
        .padding(.leading, 2)
    }
}

struct CardFooterItem: View {
    let count: Int
    let label: LocalizedStringKey

    var body: some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
            Text(label)
                .font(.system(size: 14))
        }
        .foregroundColor(.primary)
        .padding(.trailing, 12)
    }
}

// MARK: - Review header for detail view (DetalleView uses this)

struct ReviewHeaderRow: View {
    let review: ReviewInfo
    var onProfessorTap: (() -> Void)?
    var onUserTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { onProfessorTap?() }) {
                ProfileImageView(url: review.profesor.imageprofeUrl, size: 48)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Button(action: { onProfessorTap?() }) {
                        Text(review.profesor.nombreProfe)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer(minLength: 8)
                    Button(action: { onUserTap?() }) {
                        Text("Por: @\(review.usuario.perfilAnonimo ? NSLocalizedString("Anónimo", comment: "") : review.usuario.nombreUsu)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                HStack(spacing: 6) {
                    Text(review.materia.nombreMateria)
                        .font(.system(size: 13))
                        .foregroundColor(.verdetp)
                    StarRatingView(rating: Double(review.rating), starSize: 13)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Review body for detail view (DetalleView uses this)

struct ReviewBodyContent: View {
    let review: ReviewInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(review.content)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if !review.imageUrls.isEmpty {
                ReviewImageMosaicView(imageUrls: review.imageUrls)
                    .padding(.horizontal, 16)
            }

            HStack(spacing: 8) {
                Text(review.time)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                if review.editado {
                    Text("Editado")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.verdetp)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.verdetp.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("\(review.likes)").fontWeight(.bold)
                        Text("Likes")
                    }
                    .font(.system(size: 13))
                    HStack(spacing: 4) {
                        Text("\(review.commentsCount)").fontWeight(.bold)
                        Text("Comentarios")
                    }
                    .font(.system(size: 13))
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Skeleton shimmer for review card

struct ReviewCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.tpSurfaceVariantLight)
                    .frame(width: 48, height: 48)
                    .shimmerEffect()

                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.tpSurfaceVariantLight)
                        .frame(width: 140, height: 14)
                        .shimmerEffect()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.tpSurfaceVariantLight)
                        .frame(width: 100, height: 10)
                        .shimmerEffect()
                }
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.tpSurfaceVariantLight)
                .frame(maxWidth: .infinity)
                .frame(height: 12)
                .shimmerEffect()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.tpSurfaceVariantLight)
                .frame(width: 200, height: 12)
                .shimmerEffect()
        }
        .padding(16)
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.bordeTuProfe.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 5)
    }
}

// MARK: - Skeleton list

struct ReviewListSkeleton: View {
    var count: Int = 5

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { _ in
                    ReviewCardSkeleton()
                }
            }
            .padding(.top, 8)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Comment Card (matches Android CommentCard)

struct CommentCardView: View {
    let comment: CommentInfo
    var onUserTap: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(alignment: .top, spacing: 10) {
                ProfileImageView(
                    url: comment.usuario.imageprofeUrl,
                    size: 36
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("@\(comment.usuario.perfilAnonimo ? NSLocalizedString("Anónimo", comment: "") : comment.usuario.nombreUsu)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(comment.time)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Text(comment.content)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    if comment.editado {
                        Text("(editado)" as LocalizedStringKey)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        HStack(spacing: 3) {
                            Image(systemName: comment.liked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .foregroundColor(.verdetp)
                                .font(.system(size: 13))
                            Text("\(comment.likes)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        if comment.repliesCount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "bubble.left")
                                    .foregroundColor(.verdetp)
                                    .font(.system(size: 13))
                                Text("\(comment.repliesCount)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.pastel)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.bordeTuProfe, lineWidth: 1)
            )
            .padding(.vertical, 4)
        }
        .buttonStyle(CardPressButtonStyle())
    }
}

// MARK: - Config Item Row (matches Android ConfigItem)

struct ConfigItemRow: View {
    let systemImage: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .foregroundColor(.verdetp)
                    .font(.system(size: 24))
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
            .padding(20)
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.pastel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.bordeTuProfe, lineWidth: 2)
        )
        .padding(.vertical, 4)
    }
}

// MARK: - Back button header

struct BackButtonHeader: View {
    let action: () -> Void
    var title: String = ""

    var body: some View {
        VStack(spacing: 0) {
            TuProfeTopBarView()

            HStack {
                Button(action: action) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.verdetp)
                        .frame(width: 44, height: 44)
                }

                if !title.isEmpty {
                    Text(LocalizedStringKey(title))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .background(Color.pastel)
        }
    }
}

// MARK: - Title header (TitleHeader)

struct TitleHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.system(size: 36, weight: .heavy))
            .foregroundColor(.verdetp)
    }
}