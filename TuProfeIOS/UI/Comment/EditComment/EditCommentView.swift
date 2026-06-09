import SwiftUI

struct EditCommentView: View {
    let commentId: String
    @StateObject private var viewModel = EditCommentViewModel()
    @EnvironmentObject var navState: NavigationState

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 20) {
                Spacer().frame(height: 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Editar comentario")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 24)

                    AppTextEditor(
                        placeholder: "Escribe tu comentario...",
                        text: $viewModel.commentText,
                        minHeight: 120
                    )
                }

                if let error = viewModel.error {
                    Text(LocalizedStringKey(error))
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                        .padding(.horizontal, 24)
                }

                AppButton(
                    title: "GUARDAR",
                    action: { viewModel.updateComment() },
                    isEnabled: !viewModel.commentText.isEmpty && !viewModel.isLoading,
                    isLoading: viewModel.isLoading
                )

                Spacer()
            }
        }
        .safeAreaInset(edge: .top) {
            TuProfeTopBarView()
        }
        .onChange(of: viewModel.success) { ok in if ok { navState.pop() } }
        .onAppear { viewModel.cargarComment(commentId: commentId) }
    }
}

@MainActor
class EditCommentViewModel: ObservableObject {
    @Published var commentText = ""
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var success = false

    private var commentId = ""
    private let commentRepo = CommentRepository.shared

    func cargarComment(commentId: String) {
        self.commentId = commentId
        Task {
            do {
                let comment = try await commentRepo.getCommentById(commentId)
                commentText = comment.content
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func updateComment() {
        isLoading = true
        Task {
            do {
                try await commentRepo.updateComment(commentId, content: commentText)
                success = true
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}