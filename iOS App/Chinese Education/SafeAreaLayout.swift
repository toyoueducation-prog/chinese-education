import SpriteKit
#if os(iOS)
import UIKit
#endif

/// Shared safe-area helpers for SpriteKit scenes.
/// Backgrounds may still bleed under the status bar; HUD/UI must stay inside these insets
/// so the clock, battery, wifi, and home indicator remain visible.
enum SafeAreaLayout {
    /// Prefer the live `SKView` insets; fall back to the key window, then notch-era defaults.
    /// Always raise to a notch/home-indicator floor on tall phones — SpriteView with
    /// `ignoresSafeArea` often reports understated or zero insets at first layout.
    static func insets(for scene: SKScene) -> UIEdgeInsets {
        #if os(iOS)
        var insets = UIEdgeInsets.zero
        if let view = scene.view {
            insets = view.safeAreaInsets
        }
        if insets.top < 1 || insets.bottom < 1 {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            if let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
                ?? scenes.first?.windows.first {
                let w = window.safeAreaInsets
                insets.top = max(insets.top, w.top)
                insets.left = max(insets.left, w.left)
                insets.bottom = max(insets.bottom, w.bottom)
                insets.right = max(insets.right, w.right)
            }
        }
        // Floor for Dynamic Island / home-indicator phones (and understated SpriteView insets).
        if scene.size.height >= 700 {
            insets.top = max(insets.top, 59)
            insets.bottom = max(insets.bottom, 34)
        } else if scene.size.height >= 600 {
            insets.top = max(insets.top, 47)
            insets.bottom = max(insets.bottom, 34)
        }
        return insets
        #else
        return .zero
        #endif
    }

    static func contentFrame(in scene: SKScene, margin: CGFloat = 8) -> CGRect {
        let i = insets(for: scene)
        return CGRect(
            x: i.left + margin,
            y: i.bottom + margin,
            width: max(0, scene.size.width - i.left - i.right - margin * 2),
            height: max(0, scene.size.height - i.top - i.bottom - margin * 2)
        )
    }
}

extension SKScene {
    var safeInsets: UIEdgeInsets { SafeAreaLayout.insets(for: self) }

    /// Scene coordinates (origin bottom-left): top edge of safe content.
    var safeTopY: CGFloat { size.height - safeInsets.top }

    /// Scene coordinates: bottom edge of safe content.
    var safeBottomY: CGFloat { safeInsets.bottom }

    var safeContentFrame: CGRect { SafeAreaLayout.contentFrame(in: self) }

    /// Camera-child coordinates (origin screen center): top edge of safe content.
    var cameraSafeTopY: CGFloat { size.height / 2 - safeInsets.top }

    /// Camera-child coordinates: bottom edge of safe content.
    var cameraSafeBottomY: CGFloat { -size.height / 2 + safeInsets.bottom }
}

#if os(iOS)
extension SKLabelNode {
    /// Measured height for wrapped Chinese / multiline labels.
    func measuredTextHeight(maxWidth: CGFloat? = nil) -> CGFloat {
        let width = maxWidth ?? (preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : 300)
        let font = UIFont(name: fontName ?? "AvenirNext-Medium", size: fontSize)
            ?? UIFont.systemFont(ofSize: fontSize)
        let text = self.text ?? ""
        guard !text.isEmpty else { return font.lineHeight }
        let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
        let bounds = (text as NSString).boundingRect(
            with: constraint,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(bounds.height)
    }

    /// Shrink font until text fits `maxHeight`, never below `minimum`.
    func fitFont(maxWidth: CGFloat, maxHeight: CGFloat, minimum: CGFloat = 16, starting: CGFloat? = nil) {
        preferredMaxLayoutWidth = maxWidth
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        var size = starting ?? fontSize
        fontSize = size
        while size > minimum && measuredTextHeight(maxWidth: maxWidth) > maxHeight {
            size -= 1
            fontSize = size
        }
    }
}
#endif
