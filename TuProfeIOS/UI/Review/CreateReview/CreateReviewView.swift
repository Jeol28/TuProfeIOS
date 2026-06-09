import SwiftUI
import CoreLocation
import PhotosUI

// MARK: - CreateReviewView (matches Android CreateReviewScreen)

struct CreateReviewView: View {
    let onSuccess: () -> Void
    @StateObject private var viewModel = CreateReviewViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 8)

                        // Professor search
                        ProfessorPickerSection(viewModel: viewModel)

                        // Subject picker
                        if viewModel.selectedProfessor != nil {
                            MateriaPickerSection(viewModel: viewModel)
                        }

                        // Rating
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Calificación")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)

                            InteractiveStarRating(rating: $viewModel.rating)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        // Review text
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tu reseña")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)

                            AppTextEditor(
                                placeholder: "Describe tu experiencia con este profesor...",
                                text: $viewModel.reviewText,
                                minHeight: 120
                            )

                            // Image picker toolbar
                            HStack(spacing: 12) {
                                PhotosPicker(
                                    selection: $viewModel.selectedPhotoItems,
                                    maxSelectionCount: 4,
                                    matching: .images
                                ) {
                                    Label("Fotos", systemImage: "photo.on.rectangle")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(viewModel.selectedImages.count < 4 ? .verdetp : .secondary)
                                }
                                .disabled(viewModel.selectedImages.count >= 4)

                                if !viewModel.selectedImages.isEmpty {
                                    Text("\(viewModel.selectedImages.count)/4")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 24)

                            // Selected image thumbnails
                            if !viewModel.selectedImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
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

                                                Button(action: { viewModel.removeImage(at: index) }) {
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

                        // Location toggle
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

                        // Error
                        if let error = viewModel.error {
                            Text(LocalizedStringKey(error))
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // Submit
                        AppButton(
                            title: "PUBLICAR RESEÑA",
                            action: { viewModel.createReview() },
                            isEnabled: viewModel.canSubmit,
                            isLoading: viewModel.isLoading
                        )
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Nueva reseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.verdetp)
                }
            }
            .onChange(of: viewModel.success) { success in
                if success { onSuccess() }
            }
        }
    }
}

// MARK: - Professor picker

struct ProfessorPickerSection: View {
    @ObservedObject var viewModel: CreateReviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profesor")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 24)

            if let selected = viewModel.selectedProfessor {
                HStack(spacing: 10) {
                    ProfileImageView(url: selected.imageprofeUrl, size: 36)
                    Text(selected.nombreProfe)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: { viewModel.selectedProfessor = nil; viewModel.selectedMateria = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.pastel)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.verdetp, lineWidth: 1.5))
                .padding(.horizontal, 16)
            } else {
                Menu {
                    ForEach(viewModel.filteredProfessors) { prof in
                        Button(action: { viewModel.selectProfessor(prof) }) {
                            Label(prof.nombreProfe, systemImage: "person")
                        }
                    }
                } label: {
                    HStack {
                        Text("Seleccionar profesor")
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.verdetp)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.pastel)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.gris.opacity(0.6), lineWidth: 1.5))
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Materia picker

struct MateriaPickerSection: View {
    @ObservedObject var viewModel: CreateReviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Materia")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 24)

            Menu {
                ForEach(viewModel.availableMaterias, id: \.self) { materia in
                    Button(materia) { viewModel.selectedMateria = materia }
                }
            } label: {
                HStack {
                    Group {
                        if viewModel.selectedMateria.isEmpty {
                            Text("Seleccionar materia")
                        } else {
                            Text(viewModel.selectedMateria)
                        }
                    }
                    .foregroundColor(viewModel.selectedMateria.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.verdetp)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.pastel)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.gris.opacity(0.6), lineWidth: 1.5))
                .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    CreateReviewView(onSuccess: {})
}