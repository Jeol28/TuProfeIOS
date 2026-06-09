import Foundation

struct MessageInfo: Identifiable, Equatable {
    let id: String
    let senderId: String
    let text: String
    let sentAt: Date?
    let read: Bool
    let imageUrl: String?
}
