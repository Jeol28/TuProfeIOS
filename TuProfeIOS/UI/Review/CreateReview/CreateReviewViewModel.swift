import Foundation
import CoreLocation
import PhotosUI
import SwiftUI

@MainActor
class CreateReviewViewModel: ObservableObject {
    @Published var reviewText = ""
    @Published var rating = 0
    @Published var selectedProfessor: Profesor? = nil
    @Published var professorQuery = "" { didSet { filterProfessors() } }
    @Published var filteredProfessors: [Profesor] = []
    @Published var selectedMateria = ""
    @Published var includeLocation = false
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var success = false
    @Published var selectedImages: [UIImage] = []
    @Published var selectedPhotoItems: [PhotosPickerItem] = [] {
        didSet { Task { await loadImages(from: selectedPhotoItems) } }
    }

    private var allProfessors: [Profesor] = []

    var availableMaterias: [String] {
        selectedProfessor?.materias ?? []
    }

    var canSubmit: Bool {
        selectedProfessor != nil &&
        !selectedMateria.isEmpty &&
        rating > 0 &&
        !reviewText.isEmpty &&
        !isLoading
    }

    private let professorRepo = ProfessorRepository.shared
    private let reviewRepo = ReviewRepository.shared
    private let userRepo = UserRepository.shared
    private let locationManager = CLLocationManager()

    init() {
        loadProfessors()
    }

    func loadProfessors() {
        Task {
            allProfessors = (try? await professorRepo.getAllProfessors()) ?? []
            filteredProfessors = allProfessors
        }
    }

    func selectProfessor(_ prof: Profesor) {
        selectedProfessor = prof
        professorQuery = ""
        filteredProfessors = []
        selectedMateria = ""
    }

    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        if index < selectedPhotoItems.count { selectedPhotoItems.remove(at: index) }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items.prefix(4) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data) {
                images.append(ui)
            }
        }
        selectedImages = images
    }

    private func filterProfessors() {
        if professorQuery.isEmpty {
            filteredProfessors = allProfessors
            return
        }
        let q = professorQuery.lowercased()
        filteredProfessors = allProfessors.filter {
            $0.nombreProfe.lowercased().contains(q) ||
            $0.departamento.lowercased().contains(q)
        }
    }

    func createReview() {
        guard let prof = selectedProfessor,
              let userId = AuthRepository.shared.currentUserId else { return }

        isLoading = true
        error = nil

        Task {
            var lat: Double? = nil
            var lng: Double? = nil

            if includeLocation {
                if let loc = locationManager.location {
                    lat = loc.coordinate.latitude
                    lng = loc.coordinate.longitude
                }
            }

            var uploadedUrls: [String]? = nil
            if !selectedPhotoItems.isEmpty {
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
                        uploadedUrls = try await StorageRepository.shared.uploadReviewImages(userId: userId, images: jpegData)
                    } catch {
                        self.error = "Error al subir las imágenes"
                        isLoading = false
                        return
                    }
                }
            }

            let currentUser = try? await userRepo.getUserById(userId, currentUserId: userId)

            let dto = CreateReviewDto(
                userId: userId,
                professorId: prof.profeId,
                content: reviewText,
                rating: rating,
                time: { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f.string(from: Date()) }(),
                materia: selectedMateria,
                latitude: lat,
                longitude: lng,
                user: CreateReviewUserDto(
                    id: userId,
                    username: currentUser?.nombreUsu ?? "",
                    foto: currentUser?.imageprofeUrl
                ),
                professor: CreateReviewProfessorDto(
                    id: prof.profeId,
                    name: prof.nombreProfe,
                    foto: prof.imageprofeUrl
                ),
                imageUrls: uploadedUrls
            )

            do {
                _ = try await reviewRepo.createReview(dto)
                success = true
            } catch {
                self.error = "Error al publicar"
            }
            isLoading = false
        }
    }
}