import Foundation
import CoreLocation
@testable import BlockTalk

enum TestFixtures {
    static let userId = UUID()
    static let neighborhoodId = UUID()
    static let postId = UUID()

    static func makePost(
        id: UUID = UUID(),
        userId: UUID = TestFixtures.userId,
        neighborhoodId: UUID = TestFixtures.neighborhoodId,
        text: String = "Hello neighbors!",
        score: Int = 0,
        upvoteCount: Int = 0,
        downvoteCount: Int = 0,
        replyCount: Int = 0,
        reportCount: Int = 0,
        status: PostStatus = .live,
        pinId: UUID? = nil,
        isDailyPrompt: Bool = false,
        dailyPromptId: UUID? = nil,
        imageUrl: String? = nil,
        createdAt: Date? = Date()
    ) -> Post {
        Post(
            id: id,
            userId: userId,
            neighborhoodId: neighborhoodId,
            text: text,
            imageUrl: imageUrl,
            pinId: pinId,
            isDailyPrompt: isDailyPrompt,
            dailyPromptId: dailyPromptId,
            score: score,
            upvoteCount: upvoteCount,
            downvoteCount: downvoteCount,
            replyCount: replyCount,
            reportCount: reportCount,
            status: status,
            createdAt: createdAt
        )
    }

    static func makeReply(
        id: UUID = UUID(),
        postId: UUID = TestFixtures.postId,
        parentReplyId: UUID? = nil,
        userId: UUID = TestFixtures.userId,
        text: String = "Nice post!",
        score: Int = 0,
        upvoteCount: Int = 0,
        downvoteCount: Int = 0,
        depth: Int = 0,
        children: [Reply]? = nil,
        createdAt: Date? = Date()
    ) -> Reply {
        Reply(
            id: id,
            postId: postId,
            parentReplyId: parentReplyId,
            userId: userId,
            text: text,
            score: score,
            upvoteCount: upvoteCount,
            downvoteCount: downvoteCount,
            depth: depth,
            createdAt: createdAt,
            children: children,
            author: ReplyAuthor(username: "tester", userNumber: 1, homeShortCode: "LES")
        )
    }

    static func makeNeighborhood(
        id: UUID = UUID(),
        name: String = "Lower East Side",
        shortCode: String = "LES",
        borough: String = "Manhattan"
    ) -> Neighborhood {
        Neighborhood(id: id, name: name, shortCode: shortCode, borough: borough)
    }

    static func makeDailyPrompt(
        id: UUID = UUID(),
        question: String = "What's the best pizza spot?",
        activeFrom: Date = Date().addingTimeInterval(-3600),
        activeUntil: Date = Date().addingTimeInterval(3600)
    ) -> DailyPrompt {
        DailyPrompt(id: id, question: question, activeFrom: activeFrom, activeUntil: activeUntil)
    }

    static func makeQueuedPost(
        post: Post? = nil,
        text: String = "Hello neighbors!",
        userId: UUID = TestFixtures.userId,
        neighborhoodId: UUID = TestFixtures.neighborhoodId,
        imageData: Data? = nil,
        pinCoordinate: CLLocationCoordinate2D? = nil,
        pinCornerName: String? = nil,
        placeName: String? = nil,
        placeCategory: String? = nil,
        placeSymbol: String? = nil,
        isDailyPrompt: Bool = false,
        dailyPromptId: UUID? = nil,
        queuedAt: Date = Date()
    ) -> OfflineStore.QueuedPost {
        let p = post ?? makePost(userId: userId, neighborhoodId: neighborhoodId, text: text)
        return OfflineStore.QueuedPost(
            post: p,
            text: text,
            userId: userId,
            neighborhoodId: neighborhoodId,
            imageData: imageData,
            pinCoordinate: pinCoordinate,
            pinCornerName: pinCornerName,
            placeName: placeName,
            placeCategory: placeCategory,
            placeSymbol: placeSymbol,
            isDailyPrompt: isDailyPrompt,
            dailyPromptId: dailyPromptId,
            queuedAt: queuedAt
        )
    }

    /// A simple square polygon for testing point-in-polygon
    static let squareRing: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 0, longitude: 10),
        CLLocationCoordinate2D(latitude: 10, longitude: 10),
        CLLocationCoordinate2D(latitude: 10, longitude: 0),
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
    ]
}
