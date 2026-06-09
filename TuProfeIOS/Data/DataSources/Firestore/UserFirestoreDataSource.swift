import Foundation
import FirebaseFirestore
import FirebaseMessaging

final class UserFirestoreDataSource: UserDataSource {
    private let db = Firestore.firestore()

    func getUserById(_ userId: String, currentUserId: String) async throws -> Usuario {
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let data = doc.data() else {
            throw NSError(domain: "UserFirestoreDataSource", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
        }

        let followedDoc = try? await db.collection("users")
            .document(userId).collection("followers").document(currentUserId).getDocument()

        let subActive = data["subscriptionActive"] as? Bool ?? false
        let subEnd = (data["subscriptionEnd"] as? Timestamp)?.dateValue()

        return Usuario(
            id: userId,
            nombreUsu: data["username"] as? String ?? "",
            email: data["email"] as? String ?? "",
            carrera: data["carrera"] as? String ?? "",
            imageprofeUrl: data["foto"] as? String,
            followingCount: data["followingCount"] as? Int ?? 0,
            followersCount: data["followersCount"] as? Int ?? 0,
            followed: followedDoc?.exists ?? false,
            perfilAnonimo: data["perfilAnonimo"] as? Bool ?? false,
            perfilPublico: data["perfilPublico"] as? Bool ?? true,
            resenasEnPerfil: data["resenasEnPerfil"] as? Bool ?? true,
            subscriptionActive: subActive,
            subscriptionEnd: subEnd
        )
    }

    func registerUser(userId: String, username: String, email: String, carrera: String, fcmToken: String?) async throws {
        let data: [String: Any] = [
            "id": userId,
            "username": username,
            "email": email,
            "carrera": carrera,
            "followingCount": 0,
            "followersCount": 0,
            "perfilAnonimo": false,
            "perfilPublico": true,
            "resenasEnPerfil": true,
            "fcmtoken": fcmToken ?? ""
        ]
        try await db.collection("users").document(userId).setData(data)
    }

    func updateUser(userId: String, username: String, email: String, carrera: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "username": username,
            "email": email,
            "carrera": carrera
        ])
    }

    func updateUserPhoto(userId: String, photoURL: String) async throws {
        try await db.collection("users").document(userId).updateData(["foto": photoURL])
    }

    func updatePrivacySettings(userId: String, perfilAnonimo: Bool, perfilPublico: Bool, resenasEnPerfil: Bool) async throws {
        try await db.collection("users").document(userId).updateData([
            "perfilAnonimo": perfilAnonimo,
            "perfilPublico": perfilPublico,
            "resenasEnPerfil": resenasEnPerfil
        ])
    }

    func getFollowers(userId: String, currentUserId: String) async throws -> [Usuario] {
        let snapshot = try await db.collection("users")
            .document(userId).collection("followers").getDocuments()
        var result: [Usuario] = []
        for doc in snapshot.documents {
            if let user = try? await getUserById(doc.documentID, currentUserId: currentUserId) {
                result.append(user)
            }
        }
        return result
    }

    func getFollowing(userId: String, currentUserId: String) async throws -> [Usuario] {
        let snapshot = try await db.collection("users")
            .document(userId).collection("following").getDocuments()
        var result: [Usuario] = []
        for doc in snapshot.documents {
            if let user = try? await getUserById(doc.documentID, currentUserId: currentUserId) {
                result.append(user)
            }
        }
        return result
    }

    func followOrUnfollowUser(currentUserId: String, targetUserId: String) async throws {
        let currentUserRef = db.collection("users").document(currentUserId)
        let targetUserRef = db.collection("users").document(targetUserId)
        let followingRef = currentUserRef.collection("following").document(targetUserId)
        let followerRef = targetUserRef.collection("followers").document(currentUserId)

        try await db.runTransaction { transaction, errorPointer in
            let followingDoc: DocumentSnapshot
            do { followingDoc = try transaction.getDocument(followingRef) }
            catch let error as NSError { errorPointer?.pointee = error; return nil }

            if followingDoc.exists {
                transaction.deleteDocument(followingRef)
                transaction.deleteDocument(followerRef)
                transaction.updateData(["followingCount": FieldValue.increment(Int64(-1))], forDocument: currentUserRef)
                transaction.updateData(["followersCount": FieldValue.increment(Int64(-1))], forDocument: targetUserRef)
            } else {
                let ts = FieldValue.serverTimestamp()
                transaction.setData(["timestamp": ts], forDocument: followingRef)
                transaction.setData(["timestamp": ts], forDocument: followerRef)
                transaction.updateData(["followingCount": FieldValue.increment(Int64(1))], forDocument: currentUserRef)
                transaction.updateData(["followersCount": FieldValue.increment(Int64(1))], forDocument: targetUserRef)
            }
            return nil
        }
    }

    func getFollowingIds(userId: String) async throws -> [String] {
        let snapshot = try await db.collection("users")
            .document(userId).collection("following").getDocuments()
        return snapshot.documents.map { $0.documentID }
    }

    func updateFCMToken(userId: String, token: String) async throws {
        try await db.collection("users").document(userId).updateData(["fcmtoken": token])
    }

    func updateSubscription(userId: String, active: Bool, endDate: Date) async throws {
        try await db.collection("users").document(userId).updateData([
            "subscriptionActive": active,
            "subscriptionEnd": Timestamp(date: endDate)
        ])
    }
}
