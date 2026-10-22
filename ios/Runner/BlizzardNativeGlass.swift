import Flutter
import UIKit

/// The actual Apple material; Flutter retains the action and its semantics.
final class BlizzardNativeGlassFactory: NSObject, FlutterPlatformViewFactory {
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let values = args as? [String: Any] ?? [:]
        let radius = (values["radius"] as? NSNumber)?.doubleValue ?? 0
        return BlizzardNativeGlassPlatformView(frame: frame, radius: radius, lens: values["lens"] as? Bool ?? false)
    }
}

private final class BlizzardNativeGlassPlatformView: NSObject, FlutterPlatformView {
    private let material: BlizzardNativeGlassMaterial

    init(frame: CGRect, radius: Double, lens: Bool) {
        material = BlizzardNativeGlassMaterial(frame: frame, radius: radius, lens: lens)
        super.init()
    }

    func view() -> UIView { material }
}

final class BlizzardNativeGlassMaterial: UIVisualEffectView {
    private let lens: Bool
    private var transparencyObserver: NSObjectProtocol?

    init(frame: CGRect, radius: Double, lens: Bool) {
        self.lens = lens
        super.init(effect: nil)
        self.frame = frame
        layer.cornerRadius = radius.isFinite ? CGFloat(max(0, radius)) : 0
        layer.cornerCurve = .continuous
        clipsToBounds = true
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        accessibilityIdentifier = "app.blizzard.native-glass"
        updateMaterial()
        transparencyObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.updateMaterial() }
    }

    required init?(coder: NSCoder) { return nil }

    deinit {
        if let transparencyObserver { NotificationCenter.default.removeObserver(transparencyObserver) }
    }

    private func updateMaterial() {
        if UIAccessibility.isReduceTransparencyEnabled {
            effect = nil
            backgroundColor = UIColor(red: 25 / 255, green: 55 / 255, blue: 76 / 255, alpha: 1)
        } else if #available(iOS 26.0, *) {
            backgroundColor = .clear
            let glass = UIGlassEffect(style: lens ? .clear : .regular)
            effect = glass
        } else {
            // A conventional system material on older iOS, not Liquid Glass.
            backgroundColor = .clear
            effect = UIBlurEffect(style: .systemMaterial)
        }
    }
}
