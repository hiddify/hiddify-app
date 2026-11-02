# Changelog
All notable changes to this project will be documented in this file.

## [4.5.2] - 2024-11-25
### Changed
- remove unnecessary visibility_detector dependency

## [4.5.1] - 2024-11-21
### Changed
- fix console formatting reset for warn prints

## [4.5.0] - 2024-01-31
### Changed
- include `ShaderEffect` in export by default
- use `AnimatedSampler` from `flutter_shaders` package (versus copying it in)

## [4.4.1] - 2024-01-26
### Changed
- improved documentation for extension methods

## [4.4.0] - 2024-01-08
### Added
- `Animate.value` — sets the starting value/position of an animation

## [4.3.0] - 2023-09-21
### Added
- `AlignEffect` - animate alignment
- `transformHitTests` on `ScaleEffect` and `RotateEffect`
- `EffectList` - build lists of effects with the chained API

### Changed
- fix to properly support `FollowPathEffect.rotate`
- made extension method types less ambiguous
- fixed total animation duration when using `ThenEffect`
- updated to use super initializers
- other minor fixes / doc updates

## [4.2.0] - 2023-06-19
### Added
- `FollowPathEffect`
- `ShaderEffect` - currently in prerelease & must be imported directly

### Changed
- removed unused `adapter` param from `AnimateList`
- added more tests

## [4.1.1] - 2023-03-23
### Changed
- fixed an issue with `onPlay` triggering on every rebuild

## [4.1.0] - 2023-02-13
### Added
- `Animate.autoPlay` and `AnimateList.autoPlay`
- `Animate.onInit` and `AnimateList.onInit`
- `AnimateList.delay`
- debug warnings for some incompatible parameter combinations

### Changed
- fixed issues with orphaned adapters causing errors

## [4.0.0] - 2023-02-13
### Added
- `CrossfadeEffect` - cross fades in a new widget
- `Adapter.direction` - optionally update in only one direction

### Changed
- major refactor of `Adapter`
- fix issue with adapters generating errors on disposed `Animate` instances
- improve smoothing for `Adapter.animated`
- improve adapter examples
- changed `ThenEffect` functionality to establish a new baseline time
- cleaned up tests & added tests for new effects

## [3.1.0] - 2023-01-30
### Added
- added a few fun examples to the `everything_view`

### Changed
- changed `ShakeEffect.hz` to a double
- added padding to `ShimmerEffect` to reduce visual issues with ShaderMask and antialiasing
- fix an error in the `AnimationController.loop` extension when the target was disposed

## [3.0.0] - 2023-01-19
### Changed
- reorganize `lib` folder to follow dart guidance
- cleanup of documentation to improve consistency
- renamed `test_view` to `playground_view`

## [2.2.0] - 2023-01-15
### Added
- `ColorEffect` - animate between two colors with a blend mode

### Changed
- reset animation if `onPlay` changes
- simplified `BoxShadowEffect` implementation

## [2.1.0] - 2022-12-24
### Added
- `Animate.target` for declarative animation
- `BoxShadowEffect` - animate `BoxShadow`
- `ElevationEffect` - animate elevation shadows
- `Animate.restartOnHotReload` static property

### Changed
- fixed issues with low value blurs on web
- fixed errors with 0 sized gradients in ShimmerEffect
- removed optimizations that modify the display list

## [2.0.1] - 2022-10-30
### Changed
- fixed `ShakeEffect.hz` calculations and adjusted defaults

## [2.0.0] - 2022-10-23
### Added
- effects now use "smart" parameters. See README: Other Effect Parameters
- effects now expose default param values as static fields
- `FlipEffect` (2.5d card flip)
- `loop` extension to `AnimationController`
- support for non-uniform blurs in `BlurEffect`
- `animated` property for all adapters
- `transformHitTest` param on `MoveEffect`
- first set of automated tests

### Changed
- changes to some effect extension methods (ex. `move`) to be more consistent
- fix for `BlurEffect` on the web with low sigma values
- exposed some effects' utility methods as static methods
- changed `SwapEffect.builder` method signature to have a non-nullable child
- minor documentation improvements and small fixes

### Removed
- `unblur` extension method. Use `blurXY` with a `begin` value instead

## [1.0.0] - 2022-08-18
### Added
- `RotateEffect`

### Changed
- `SwapEffect.builder` now receives a reference to the original child
- `Animate.onInit` renamed to `onPlay`
- improved hot reload support

## [0.3.0] - 2022-06-20
### Added
- `.unblur()` extension method
- `.effect()` extension method
- kitchen sink example view

### Changed
- Optimized all effect builders to only build on value change
- Minor cleanup
- `ShakeEffect` now uses `hz` instead of `count`
- `TintEffect` now uses opaque black for default color
- Made `CallbackEffect` more robust

## [0.2.0] - 2022-06-17
### Added
- Adapters: Drive animations from external sources (scrolling, notifiers, etc)
- `ShakeEffect`: translation and/or rotation based shaking effect
- `SaturateEffect`: Color saturation effect (ex. animate to grayscale)
- `TintEffect`: Animated color tint

### Changed
- Fix issue with `Animate` delay returning after dispose
- Improved example

## [0.1.1] - 2022-05-31
### Changed
- Fix a major widget lifecycle issue with `Animate` delay

## [0.1.0] - 2022-05-29
### Added
- `ShimmerEffect`: can do a variety of gradient effects, including load shimmers
- `ThenEffect`: simplifies sequencing effects by calculating a new inheritable delay

### Changed
- `onInit` & `onComplete` are now propagated to all children of `AnimateList`
- improved documentation
- `Animate` delay is now separate from the animation and only runs once
- Effect is now an empty effect instead of an abstract class
- Updated example
- Fixed an issue with property inheritance through multiple effects

## [0.0.1] - 2022-05-20
### Added
- Initial pre-release