import Foundation
import FirebaseFirestore

final class CommentFirestoreDataSource: CommentDataSource {
    private let db = Firestore.firestore()

    private func parseComment(_ doc: DocumentSnapshot) -> CommentInfo? {
        guard let data = doc.data() else { return nil }

        let updatedAt = data["updatedAt"] as? String
        let editado = updatedAt != nil && !updatedAt!.isEmpty

        let userData = data["user"] as? [String: Any]
        let userId = data["userId"] as? String ?? ""
        let usuario = Usuario(
            id: userId,
            nombreUsu: userData?["username"] as? String ?? data["username"] as? String ?? "Usuario",
            email: "",
            carrera: "",
            imageprofeUrl: userData?["foto"] as? String,
            followingCount: 0,
            followersCount: 0,
            followed: false,
            perfilAnonimo: userData?["perfilAnonimo"] as? Bool ?? false,
            perfilPublico: true,
            resenasEnPerfil: true,
            subscriptionActive: false,
            subscriptionEnd: nil
        )

        return CommentInfo(
            id: doc.documentID,
            reviewId: data["reviewId"] as? String ?? "",
            parentCommentId: data["parentCommentId"] as? String,
            usuario: usuario,
            content: data["content"] as? String ?? "",
            time: formatTuProfeDate(data["createdAt"] as? String),
            likes: data["likesCount"] as? Int ?? 0,
            liked: false,
            repliesCount: data["repliesCount"] as? Int ?? 0,
            editado: editado
        )
    }

    func getCommentById(_ id: String, currentUserId: String?) async throws -> CommentInfo {
        let doc = try await db.collection("comments").document(id).getDocument()
        guard var comment = parseComment(doc) else { throw APIError.noData }
        if let userId = currentUserId, !userId.isEmpty {
            let likeDoc = try? await db.collection("comments")
                .document(id).collection("likes").document(userId).getDocument()
            comment.liked = likeDoc?.exists ?? false
        }
        return comment
    }

    func getCommentsByReview(_ reviewId: String) async throws -> [CommentInfo] {
        let snapshot = try await db.collection("comments")
            .whereField("reviewId", isEqualTo: reviewId)
            .getDocuments()
        return snapshot.documents.compactMap { doc -> CommentInfo? in
            let data = doc.data()
            let parent = data["parentCommentId"] as? String
            guard parent == nil || parent!.isEmpty else { return nil }
            return parseComment(doc)
        }.sorted { $0.time < $1.time }
    }

    func getReplies(parentId: String) async throws -> [CommentInfo] {
        let snapshot = try await db.collection("comments")
            .whereField("parentCommentId", isEqualTo: parentId)
            .getDocuments()
        return snapshot.documents.compactMap { parseComment($0) }
            .sorted { $0.time < $1.time }
    }

    func createComment(_ dto: CreateCommentDto) async throws -> CommentInfo {
        var data: [String: Any] = [
            "reviewId": dto.reviewId,
            "userId": dto.userId,
            "content": dto.content,
            "createdAt": dto.createdAt,
            "likesCount": 0,
            "repliesCount": 0
        ]
        if let parentId = dto.parentCommentId, !parentId.isEmpty {
            data["parentCommentId"] = parentId
        }
        if let user = dto.user {
            data["user"] = [
                "username": user.username ?? "",
                "foto": user.foto ?? "",
                "perfilAnonimo": user.perfilAnonimo ?? false
            ]
        }

        let ref = try await db.collection("comments").addDocument(data: data)

        if let parentId = dto.parentCommentId, !parentId.isEmpty {
            try? await db.collection("comments").document(parentId).updateData([
                "repliesCount": FieldValue.increment(Int64(1))
            ])
        } else {
            try? await db.collection("reviews").document(dto.reviewId).updateData([
                "comment": FieldValue.increment(Int64(1))
            ])
        }

        let userDto = dto.user ?? UserDto(id: dto.userId)
        return CommentInfo(
            id: ref.documentID,
            reviewId: dto.reviewId,
            parentCommentId: dto.parentCommentId,
            usuario: userDto.toUsuario(),
            content: dto.content,
            time: formatTuProfeDate(dto.createdAt),
            likes: 0,
            liked: false,
            repliesCount: 0,
            editado: false
        )
    }

    func updateComment(_ id: String, content: String) async throws {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try await db.collection("comments").document(id).updateData([
            "content": content,
            "updatedAt": fmt.string(from: Date())
        ])
    }

    func deleteComment(_ id: String) async throws {
        let doc = try await db.collection("comments").document(id).getDocument()
        let data = doc.data()
        let reviewId = data?["reviewId"] as? String ?? ""
        let parentId = data?["parentCommentId"] as? String

        try await db.collection("comments").document(id).delete()

        if let parentId, !parentId.isEmpty {
            try? await db.collection("comments").document(parentId).updateData([
                "repliesCount": FieldValue.increment(Int64(-1))
            ])
        } else if !reviewId.isEmpty {
            try? await db.collection("reviews").document(reviewId).updateData([
                "comment": FieldValue.increment(Int64(-1))
            ])
        }
    }

    func toggleLike(commentId: String, userId: String) async throws {
        let commentRef = db.collection("comments").document(commentId)
        let likeRef = commentRef.collection("likes").document(userId)

        try await db.runTransaction { transaction, errorPointer in
            let likeDoc: DocumentSnapshot
            do { likeDoc = try transaction.getDocument(likeRef) }
            catch let e as NSError { errorPointer?.pointee = e; return nil }

            if likeDoc.exists {
                transaction.deleteDocument(likeRef)
                transaction.updateData(["likesCount": FieldValue.increment(Int64(-1))], forDocument: commentRef)
            } else {
                transaction.setData(["userId": userId], forDocument: likeRef)
                transaction.updateData(["likesCount": FieldValue.increment(Int64(1))], forDocument: commentRef)
            }
            return nil
        }
    }

    func getCommentsByUser(_ userId: String) async throws -> [CommentInfo] {
        let snapshot = try await db.collection("comments")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.compactMap { parseComment($0) }
            .sorted { $0.time > $1.time }
    }
}
