import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  @MainActor func testGlassUsesTheAppleEffectAvailableOnThisOS() {
    let glass = BlizzardNativeGlassMaterial(frame: CGRect(x: 0, y: 0, width: 148, height: 148), radius: 44, lens: true)
    if UIAccessibility.isReduceTransparencyEnabled {
      XCTAssertNil(glass.effect)
      XCTAssertEqual(glass.backgroundColor?.cgColor.alpha, 1)
    } else if #available(iOS 26.0, *) {
      XCTAssertTrue(glass.effect is UIGlassEffect)
    } else {
      XCTAssertTrue(glass.effect is UIBlurEffect)
    }
  }

  @MainActor func testGlassPreservesTheNativeShapeWithoutOwningInteractionOrAccessibility() {
    let glass = BlizzardNativeGlassMaterial(frame: CGRect(x: 0, y: 0, width: 353, height: 66), radius: 33, lens: false)
    XCTAssertEqual(glass.layer.cornerRadius, 33)
    XCTAssertTrue(glass.clipsToBounds)
    XCTAssertFalse(glass.isUserInteractionEnabled)
    XCTAssertNil(glass.hitTest(CGPoint(x: 50, y: 30), with: nil))
    XCTAssertFalse(glass.isAccessibilityElement)
    XCTAssertTrue(glass.accessibilityElementsHidden)
  }

  @MainActor func testNonFiniteRadiusCannotReachTheNativeLayer() {
    let glass = BlizzardNativeGlassMaterial(frame: .zero, radius: .infinity, lens: false)
    XCTAssertEqual(glass.layer.cornerRadius, 0)
  }

}
