import UIKit

/// A stack view that only ever claims a touch when one of its own arranged subviews does —
/// never itself.
///
/// The recurring bug this fixes: whenever a plain content stack (labels, icons, spacers) sits
/// on top of a full-bounds tap control behind it — e.g. a card's text/icon row layered over a
/// `UIControl` covering the whole card — UIView's default `hitTest` returns the STACK ITSELF for
/// any point inside its bounds that none of its children claimed. Disabling
/// `isUserInteractionEnabled` on the individual children (spacers, label stacks, decorative
/// tiles) does NOT fix this, because the container's own default hit-test still wins: it
/// recurses into children, finds none of them claim the point, and falls back to returning
/// `self` since it is itself interactive and the point is within its bounds. The control behind
/// it never gets a chance — UIKit routes a touch to exactly one hit-test winner, it never
/// "keeps looking" once a view claims it.
///
/// Using this in place of a plain `UIStackView` for that container fixes it correctly: a tap on
/// an actual interactive child (e.g. a delete button) still resolves to that child as normal;
/// a tap anywhere else in the stack's bounds returns nil instead of self, so the superview's
/// hit-test loop continues on to the next (lower z-order) sibling — the control behind it.
final class PassThroughStackView: UIStackView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit == self ? nil : hit
    }
}
