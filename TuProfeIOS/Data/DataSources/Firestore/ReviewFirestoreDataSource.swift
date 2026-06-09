import Foundation
import FirebaseFirestore

final class ReviewFirestoreDataSource: ReviewDataSource {
    private let db = Firestore.firestore()

    // MARK: - Document → ReviewInfo

    private func parseReview(_ doc: DocumentSnapshot) -> ReviewInfo? {
        guard let data = doc.data() else { return nil }

        let updatedAt = data["updatedAt"] as? String
        let editado = updatedAt != nil && !updatedAt!.isEmpty

        let professorData = data["professor"] as? [String: Any]
        let prof = Profesor(
            id: professorData?["id"] as? String ?? data["professorId"] as? String ?? "",
            nombreProfe: professorData?["name"] as? String ?? "Profesor",
            imageprofeUrl: professorData?["foto"] as? String,
            departamento: professorData?["department"] as? String ?? "",
            materias: []
        )

        let userData = data["user"] as? [String: Any]
        let userId = data["userId"] as? String ?? ""
        let usuario = Usuario(
            id: userId,
            nombreUsu: userData?["username"] as? String ?? "Usuario",
            email: "",
            carrera: "",
            imageprofeUrl: userData?["foto"] as? String,
            followingCount: 0,
            followersCount: 0,
            followed: false,
            perfilAnonimo: false,
            perfilPublico: true,
            resenasEnPerfil: true,
            subscriptionActive: false,
            subscriptionEnd: nil
        )

        let materia = data["materia"] as? String ?? ""

        return ReviewInfo(
            id: doc.documentID,
            usuario: usuario,
            profesor: prof,
            materia: Materia(id: materia, nombreMateria: materia),
            content: data["content"] as? String ?? "",
            rating: data["rating"] as? Int ?? 0,
            time: formatTuProfeDate(data["createdAt"] as? String ?? data["time"] as? String),
            likes: data["likesCount"] as? Int ?? 0,
            commentsCount: data["comment"] as? Int ?? 0,
            liked: false,
            editado: editado,
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double,
            imageUrls: data["imageUrls"] as? [String] ?? []
        )
    }

    // MARK: - ReviewDataSource

    func getAllReviews() async throws -> [ReviewInfo] {
        let snapshot = try await db.collection("reviews")
            .order(by: "time", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { parseReview($0) }
    }

    func listenAllReviews() -> AsyncStream<[ReviewInfo]> {
        AsyncStream { continuation in
            let listener = self.db.collection("reviews")
                .order(by: "time", descending: true)
                .addSnapshotListener { [weak self] snapshot, _ in
                    guard let self, let snapshot else { return }
                    let reviews = snapshot.documents.compactMap { self.parseReview($0) }
                    continuation.yield(reviews)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func getReviewById(_ id: String, currentUserId: String?) async throws -> ReviewInfo {
        let doc = try await db.collection("reviews").document(id).getDocument()
        guard var review = parseReview(doc) else { throw APIError.noData }

        if let userId = currentUserId {
            let likeDoc = try? await db.collection("reviews")
                .document(id).collection("likes").document(userId).getDocument()
            review.liked = likeDoc?.exists ?? false
        }
        return review
    }

    func getReviewsByProfessor(_ professorId: String) async throws -> [ReviewInfo] {
        let snapshot = try await db.collection("reviews")
            .whereField("professorId", isEqualTo: professorId)
            .getDocuments()
        return snapshot.documents.compactMap { parseReview($0) }
            .sorted { $0.time > $1.time }
    }

    func getReviewsByUser(_ userId: String) async throws -> [ReviewInfo] {
        let snapshot = try await db.collection("reviews")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.compactMap { parseReview($0) }
            .sorted { $0.time > $1.time }
    }

    func createReview(_ dto: CreateReviewDto) async throws -> ReviewInfo {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timeStr = dto.time ?? fmt.string(from: Date())

        var data: [String: Any] = [
            "userId": dto.userId ?? "",
            "professorId": dto.professorId ?? "",
            "content": dto.content ?? "",
            "rating": dto.rating ?? 0,
            "time": timeStr,
            "materia": dto.materia ?? "",
            "likesCount": 0,
            "comment": 0
        ]
        if let lat = dto.latitude { data["latitude"] = lat }
        if let lng = dto.longitude { data["longitude"] = lng }
        if let urls = dto.imageUrls, !urls.isEmpty { data["imageUrls"] = urls }
        if let prof = dto.professor {
            data["professor"] = ["id": prof.id, "name": prof.name, "foto": prof.foto ?? ""]
        }
        if let user = dto.user {
            data["user"] = ["username": user.username, "foto": user.foto ?? ""]
        }

        let ref = try await db.collection("reviews").addDocument(data: data)

        return ReviewInfo(
            id: ref.documentID,
            usuario: Usuario(
                id: dto.userId ?? "", nombreUsu: dto.user?.username ?? "Usuario",
                email: "", carrera: "", imageprofeUrl: dto.user?.foto,
                followingCount: 0, followersCount: 0, followed: false,
                perfilAnonimo: false, perfilPublico: true, resenasEnPerfil: true,
                subscriptionActive: false, subscriptionEnd: nil
            ),
            profesor: Profesor(
                id: dto.professorId ?? "", nombreProfe: dto.professor?.name ?? "",
                imageprofeUrl: dto.professor?.foto, departamento: "", materias: []
            ),
            materia: Materia(id: dto.materia ?? "", nombreMateria: dto.materia ?? ""),
            content: dto.content ?? "",
            rating: dto.rating ?? 0,
            time: formatTuProfeDate(timeStr),
            likes: 0, commentsCount: 0, liked: false, editado: false,
            latitude: dto.latitude, longitude: dto.longitude,
            imageUrls: dto.imageUrls ?? []
        )
    }

    func updateReview(_ id: String, content: String, rating: Int, imageUrls: [String], latitude: Double?, longitude: Double?) async throws {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var updates: [String: Any] = [
            "content": content,
            "rating": rating,
            "updatedAt": fmt.string(from: Date()),
            "imageUrls": imageUrls
        ]
        if let lat = latitude, let lng = longitude {
            updates["latitude"] = lat
            updates["longitude"] = lng
        } else {
            updates["latitude"] = FieldValue.delete()
            updates["longitude"] = FieldValue.delete()
        }
        try await db.collection("reviews").document(id).updateData(updates)
    }

    func deleteReview(_ id: String) async throws {
        try await db.collection("reviews").document(id).delete()
    }

    func toggleLike(reviewId: String, userId: String) async throws {
        let reviewRef = db.collection("reviews").document(reviewId)
        let likeRef = reviewRef.collection("likes").document(userId)

        try await db.runTransaction { transaction, errorPointer in
            let likeDoc: DocumentSnapshot
            do { likeDoc = try transaction.getDocument(likeRef) }
            catch let e as NSError { errorPointer?.pointee = e; return nil }

            if likeDoc.exists {
                transaction.deleteDocument(likeRef)
                transaction.updateData(["likesCount": FieldValue.increment(Int64(-1))], forDocument: reviewRef)
            } else {
                transaction.setData(["userId": userId], forDocument: likeRef)
                transaction.updateData(["likesCount": FieldValue.increment(Int64(1))], forDocument: reviewRef)
            }
            return nil
        }
    }

    func getMapMarkers() async throws -> [ReviewMapMarker] {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let cutoff = fmt.string(from: Date().addingTimeInterval(-86400))

        let snapshot = try await db.collection("reviews")
            .whereField("time", isGreaterThan: cutoff)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> ReviewMapMarker? in
            let data = doc.data()
            guard let lat = data["latitude"] as? Double,
                  let lng = data["longitude"] as? Double else { return nil }
            let prof = data["professor"] as? [String: Any]
            return ReviewMapMarker(
                id: doc.documentID,
                profesorNombre: prof?["name"] as? String ?? "Profesor",
                rating: data["rating"] as? Int ?? 0,
                latitude: lat,
                longitude: lng,
                materia: data["materia"] as? String ?? "",
                profesorFotoUrl: prof?["foto"] as? String,
                authorUserId: data["userId"] as? String ?? ""
            )
        }
    }
}
