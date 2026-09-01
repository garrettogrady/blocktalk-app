import Foundation

/// Centralized feature flags. Toggle these to enable/disable features
/// without code changes. Eventually back by a remote config service.
enum FeatureFlags {
    /// When true, users can only post in neighborhoods where GPS confirms
    /// their physical presence. When false (current behavior), the home
    /// neighborhood is used as a fallback, allowing posting from anywhere.
    static let requireGPSForPosting = false
}
