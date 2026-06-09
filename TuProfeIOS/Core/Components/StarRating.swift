import SwiftUI

// MARK: - Display-only star rating (matches Android RatingStars)

struct StarRatingView: View {
    let rating: Double
    var maxStars: Int = 5
    var starColor: Color = .verdetp
    var starSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxStars, id: \.self) { index in
                starImage(for: index)
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
                    .foregroundColor(starColor)
            }
        }
    }

    private func starImage(for index: Int) -> Image {
        let doubleIndex = Double(index)
        if rating >= doubleIndex {
            return Image(systemName: "star.fill")
        } else if rating >= doubleIndex - 0.5 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
}

// MARK: - Interactive star rating (for create/edit review)

struct InteractiveStarRating: View {
    @Binding var rating: Int
    var maxStars: Int = 5
    var starColor: Color = .verdetp
    var starSize: CGFloat = 36

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maxStars, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
                    .foregroundColor(starColor)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                            rating = index
                        }
                    }
                    .scaleEffect(index <= rating ? 1.1 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: rating)
            }
        }
    }
}

// MARK: - Compact rating badge

struct RatingBadge: View {
    let rating: Int

    var badgeColor: Color {
        switch rating {
        case 5: return Color(hex: "1AC06A")
        case 4: return Color(hex: "4BE086")
        case 3: return Color(hex: "FFC107")
        case 2: return Color(hex: "FF9800")
        default: return Color(hex: "F44336")
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Text("\(rating)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: 3.5)
        StarRatingView(rating: 4.0, starColor: .yellow)
        InteractiveStarRating(rating: .constant(3))
        HStack {
            RatingBadge(rating: 5)
            RatingBadge(rating: 3)
            RatingBadge(rating: 1)
        }
    }
    .padding()
}