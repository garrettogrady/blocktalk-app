import Foundation

@Observable
final class EnrollmentStore {
    private(set) var enrolledPostIds: Set<UUID> = []
    private let service = EnrollmentService()

    func load(userId: UUID) async {
        do {
            enrolledPostIds = try await service.enrolledPostIds(userId: userId)
        } catch {
            print("[EnrollmentStore] Failed to load enrollments: \(error)")
        }
    }

    func isEnrolled(_ postId: UUID) -> Bool {
        enrolledPostIds.contains(postId)
    }

    func enroll(userId: UUID, postId: UUID) {
        enrolledPostIds.insert(postId)
        Task {
            do {
                try await service.enroll(userId: userId, postId: postId)
            } catch {
                print("[EnrollmentStore] Failed to enroll: \(error)")
                enrolledPostIds.remove(postId)
            }
        }
    }

    func unenroll(userId: UUID, postId: UUID) {
        enrolledPostIds.remove(postId)
        Task {
            do {
                try await service.unenroll(userId: userId, postId: postId)
            } catch {
                print("[EnrollmentStore] Failed to unenroll: \(error)")
                enrolledPostIds.insert(postId)
            }
        }
    }
}
