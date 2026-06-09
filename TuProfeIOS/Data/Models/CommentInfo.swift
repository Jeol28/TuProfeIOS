import Foundation

struct CommentInfo: Identifiable, Equatable {
    let id: String
    var commentId: String { id }
    let reviewId: String
    let parentCommentId: String?
    let usuario: Usuario
    let content: String
    let time: String
    var likes: Int
    var liked: Bool
    var repliesCount: Int
    var editado: Bool

    static func == (lhs: CommentInfo, rhs: CommentInfo) -> Bool {
        lhs.id == rhs.id &&
        lhs.liked == rhs.liked &&
        lhs.likes == rhs.likes &&
        lhs.repliesCount == rhs.repliesCount &&
        lhs.editado == rhs.editado
    }
}