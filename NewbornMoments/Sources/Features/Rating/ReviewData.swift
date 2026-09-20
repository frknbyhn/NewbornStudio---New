import Foundation

struct RatingReview {
    let nickname: String
    let title: String
    let body: String
}

/// Social-proof cards shown on the rating screen. Nicknames are already masked and kept
/// identical across languages; only the title/body are localized.
enum RatingReviewStore {
    private static let nicknames = ["E**** C*****", "M**** L*****", "S**** K****", "J****** R*****", "A**** T*****"]

    static let all: [RatingReview] = nicknames.enumerated().map { index, nickname in
        let number = index + 1
        return RatingReview(
            nickname: nickname,
            title: NSLocalizedString("rating.review.\(number).title", comment: "Rating screen review \(number) title"),
            body: NSLocalizedString("rating.review.\(number).body", comment: "Rating screen review \(number) body")
        )
    }
}
