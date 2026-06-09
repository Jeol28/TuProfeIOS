import SwiftUI
import PhotosUI
import CoreLocation

struct EditReviewView: View {
    let reviewId: String
    @StateObject private var viewModel = EditReviewViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            if viewModel.isInitialLoading {
                ProgressView().tint(.verdetp)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 8)

                        // ── Title ─────────────────────────────────────────
                        Text("Editar reseña")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)

                        // ── Professor name ────────────────────────────────
                        if !viewModel.professorName.isEmpty {
                            HStack(spacing: 4) {
                                Text("Profesor:")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text(viewModel.professorName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                        }

                        // ── Rating ────────────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Calificación")
                                .font(.system(size: 15, weight: .semibold))
                                .padding(.horizontal, 24)
                            InteractiveStarRating(rating: $viewModel.rating)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        // ── Review text + images ──────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tu reseña")
                                .font(.system(size: 15, weight: .semibold))
                                .padding(.horizontal, 24)

                            AppTextEditor(
                                placeholder: "Describe tu experiencia...",
                                text: $viewModel.reviewText,
                                minHeight: 120
                            )

                            // Image picker toolbar
                            let totalImages = viewModel.existingImageUrls.count + viewModel.selectedImages.count
                            HStack(spacing: 12) {
                                PhotosPicker(
                                    selection: $viewModel.selectedPhotoItems,
                                    maxSelectionCount: max(4 - viewModel.existingImageUrls.count, 0),
                                    matching: .images
                                ) {
                                    Label("Fotos", systemImage: "photo.on.rectangle")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(totalImages < 4 ? .verdetp : .secondary)
                                }
                                .disabled(totalImages >= 4)

                                if totalImages > 0 {
                                    Text("\(totalImages)/4")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 24)

                            // Thumbnails
                            if totalImages > 0 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        // Existing network images
                                        ForEach(viewModel.existingImageUrls, id: \.self) { url in
                                            ZStack(alignment: .topTrailing) {
                                                AsyncImage(url: URL(string: url)) { phase in
                                                    switch phase {
                                                    case .success(let image):
                                                        image.resizable().scaledToFill()
                                                    default:
                                                        Color.gray.opacity(0.2)
                                                    }
                                                }
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .strokeBorder(Color.bordeTuProfe, lineWidth: 1)
                                                )

                                                Button(action: { viewModel.removeExistingImage(url: url) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                        .font(.system(size: 18))
                                                }
                                                .offset(x: 6, y: -6)
                                            }
                                        }

                                        // New local images
                                        ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .strokeBorder(Color.bordeTuProfe, lineWidth: 1)
                                                    )

                                                Button(action: { viewModel.removeNewImage(at: index) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                        .font(.system(size: 18))
                                                }
                                                .offset(x: 6, y: -6)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }

                        // ── Location toggle ───────────────────────────────
                        HStack {
                            Toggle(isOn: $viewModel.includeLocation) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Incluir ubicación")
                                        .font(.system(size: 15, weight: .medium))
                                    Text("Aparecerá en el mapa de reseñas")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(.verdetp)
                        }
                        .padding(.horizontal, 24)
                        .onChange(of: viewModel.includeLocation) { enabled in
                            if enabled && viewModel.latitude == nil {
                                viewModel.requestCurrentLocation()
                            } else if !enabled {
                                viewModel.latitude = nil
                                viewModel.longitude = nil
                            }
                        }

                        // ── Error ─────────────────────────────────────────
                        if let error = viewModel.error {
                            Text(LocalizedStringKey(error))
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                                .padding(.horizontal, 24)
                        }

                        // ── Save button ───────────────────────────────────
                        AppButton(
                            title: "GUARDAR CAMBIOS",
                            action: { viewModel.updateReview() },
                            isEnabled: !viewModel.reviewText.isEmpty && !viewModel.isLoading,
                            isLoading: viewModel.isLoading
                        )
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            TuProfeTopBarView()
        }
        .onChange(of: viewModel.success) { ok in if ok { navState.pop() } }
        .onAppear { viewModel.cargarReview(reviewId: reviewId) }
    }
}

// MARK: - ViewModel

@MainActor
class EditReviewViewModel: ObservableObject {
    @Published var reviewId = ""
    @Published var reviewText = ""
    @Published var rating = 5
    @Published var professorName = ""
    @Published var isInitialLoading = true
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var success = false

    // Photos
    @Published var existingImageUrls: [String] = []
    @Published var selectedImages: [UIImage] = []
    @Published var selectedPhotoItems: [PhotosPickerItem] = [] {
        didSet { Task { await loadNewImages(from: selectedPhotoItems) } }
    }

    // Location
    @Published var includeLocation = false
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil

    private let reviewRepo = ReviewRepository.shared
    private let locationManager = CLLocationManager()

    func cargarReview(reviewId: String) {
        self.reviewId = reviewId
        Task {
            do {
                let review = try await reviewRepo.getReviewById(reviewId)
                reviewText = review.content
                rating = review.rating
                professorName = review.profesor.nombreProfe
                existingImageUrls = review.imageUrls
                latitude = review.latitude
                longitude = review.longitude
                includeLocation = review.latitude != nil && review.longitude != nil
            } catch {
                self.error = error.localizedDescription
            }
            isInitialLoading = false
        }
    }

    func removeExistingImage(url: String) {
        existingImageUrls.removeAll { $0 == url }
    }

    func removeNewImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        if index < selectedPhotoItems.count { selectedPhotoItems.remove(at: index) }
    }

    func requestCurrentLocation() {
        locationManager.requestWhenInUseAuthorization()
        if let loc = locationManager.location {
            latitude = loc.coordinate.latitude
            longitude = loc.coordinate.longitude
        }
    }

    private func loadNewImages(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        let remaining = max(4 - existingImageUrls.count, 0)
        for item in items.prefix(remaining) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data) {
                images.append(ui)
            }
        }
        selectedImages = images
    }

    func updateReview() {
        isLoading = true
        error = nil

        Task {
            // Upload new images
            var newUrls: [String] = []
            if !selectedPhotoItems.isEmpty,
               let userId = AuthRepository.shared.currentUserId {
                var jpegData: [Data] = []
                for item in selectedPhotoItems {
                    if let raw = try? await item.loadTransferable(type: Data.self),
                       let ui = UIImage(data: raw),
                       let jpeg = ui.jpegData(compressionQuality: 0.8) {
                        jpegData.append(jpeg)
                    }
                }
                if !jpegData.isEmpty {
                    do {
                        newUrls = try await StorageRepository.shared.uploadReviewImages(userId: userId, images: jpegData)
                    } catch {
                        self.error = "Error al subir las imágenes"
                        isLoading = false
                        return
                    }
                }
            }

            let allImageUrls = existingImageUrls + newUrls
            let finalLat = includeLocation ? (latitude ?? locationManager.location?.coordinate.latitude) : nil
            let finalLng = includeLocation ? (longitude ?? locationManager.location?.coordinate.longitude) : nil

            do {
                try await reviewRepo.updateReview(
                    reviewId,
                    content: reviewText,
                    rating: rating,
                    imageUrls: allImageUrls,
                    latitude: finalLat,
                    longitude: finalLng
                )
                success = true
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}
