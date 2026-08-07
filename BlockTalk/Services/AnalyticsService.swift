import Foundation
import PostHog

enum Analytics {
    static func setup() {
        let config = PostHogConfig(apiKey: "phc_PLACEHOLDER_KEY", host: "https://us.i.posthog.com")
        PostHogSDK.shared.setup(config)
    }

    static func identify(userId: UUID, isSeed: Bool) {
        PostHogSDK.shared.identify(userId.uuidString, userProperties: [
            "is_seed": isSeed,
        ])
    }

    static func reset() {
        PostHogSDK.shared.reset()
    }

    // MARK: - Events

    static func appOpened() {
        PostHogSDK.shared.capture("app_opened")
    }

    static func signupCompleted() {
        PostHogSDK.shared.capture("signup_completed")
    }

    static func postCreated(isDailyPrompt: Bool) {
        PostHogSDK.shared.capture("post_created", properties: [
            "is_daily_prompt": isDailyPrompt,
        ])
    }

    static func replyCreated() {
        PostHogSDK.shared.capture("reply_created")
    }

    static func voteCast(direction: Int) {
        PostHogSDK.shared.capture("vote_cast", properties: [
            "direction": direction == 1 ? "up" : "down",
        ])
    }

    static func shareTapped() {
        PostHogSDK.shared.capture("share_tapped")
    }

    static func locationPermissionResult(granted: Bool) {
        PostHogSDK.shared.capture("location_permission_result", properties: [
            "granted": granted,
        ])
    }

    static func reportSubmitted(reason: String) {
        PostHogSDK.shared.capture("report_submitted", properties: [
            "reason": reason,
        ])
    }

    static func bellEnrolled(enrolled: Bool) {
        PostHogSDK.shared.capture("bell_enrolled", properties: [
            "enrolled": enrolled,
        ])
    }
}
