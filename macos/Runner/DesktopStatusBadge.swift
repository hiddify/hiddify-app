import AppKit

/// Status mark on the Dock icon.
/// - none: disconnected — restore the real app icon (no mark)
/// - error: connected without a usable ping — red mark
/// - ok: connected with a valid ping — green mark
enum DesktopStatusBadge {
  private static var cleanIcon: NSImage?

  static func setStatus(_ status: String) {
    // Dock updates must run on the main thread; invokeMethod already does, but
    // stay explicit so a background caller cannot leave a stale green mark.
    let apply = {
      NSApp.dockTile.badgeLabel = nil
      // Drop any custom dockTile contentView from older builds.
      NSApp.dockTile.contentView = nil

      let normalized: String
      switch status {
      case "ok", "error":
        normalized = status
      default:
        normalized = "none"
      }

      switch normalized {
      case "ok":
        NSApp.applicationIconImage = iconWithMark(baseIcon(), fill: NSColor(calibratedRed: 0.20, green: 0.78, blue: 0.35, alpha: 1))
      case "error":
        NSApp.applicationIconImage = iconWithMark(baseIcon(), fill: NSColor(calibratedRed: 0.90, green: 0.22, blue: 0.21, alpha: 1))
      default:
        // nil restores the bundle AppIcon — assigning a cached copy often leaves
        // the previous (green) Dock image on macOS.
        NSApp.applicationIconImage = nil
      }
      NSApp.dockTile.display()
    }

    if Thread.isMainThread {
      apply()
    } else {
      DispatchQueue.main.async(execute: apply)
    }
  }

  /// Back-compat for older Dart that only knew connected/disconnected.
  static func setConnected(_ connected: Bool) {
    setStatus(connected ? "ok" : "none")
  }

  /// Unmarked app icon from the bundle (never a previously drawn badge).
  private static func baseIcon() -> NSImage {
    if let cleanIcon {
      return cleanIcon
    }
    // Prefer the named application icon; fall back to whatever is currently set
    // only before we have ever drawn a mark.
    let named = NSImage(named: NSImage.applicationIconName)
    let icon = named ?? NSApp.applicationIconImage ?? NSImage(size: NSSize(width: 128, height: 128))
    cleanIcon = icon.copy() as? NSImage ?? icon
    return cleanIcon!
  }

  private static func iconWithMark(_ base: NSImage, fill: NSColor) -> NSImage {
    let size = base.size.width > 0 ? base.size : NSSize(width: 128, height: 128)
    let out = NSImage(size: size)
    out.lockFocus()
    base.draw(
      in: NSRect(origin: .zero, size: size),
      from: .zero,
      operation: .sourceOver,
      fraction: 1
    )

    let diameter = min(size.width, size.height) * 0.28
    let margin = diameter * 0.25
    let rect = NSRect(
      x: size.width - diameter - margin,
      y: margin,
      width: diameter,
      height: diameter
    )
    NSColor.white.setFill()
    NSBezierPath(ovalIn: rect).fill()

    let inset = diameter * 0.12
    fill.setFill()
    NSBezierPath(ovalIn: rect.insetBy(dx: inset, dy: inset)).fill()

    out.unlockFocus()
    out.isTemplate = false
    return out
  }
}
