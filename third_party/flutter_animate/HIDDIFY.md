# flutter_animate 4.5.2, patched

A copy of [flutter_animate 4.5.2](https://pub.dev/packages/flutter_animate/versions/4.5.2)
(BSD 3-Clause, see LICENSE) with one change in `lib/src/flutter_animate.dart`:
`EffectEntry.buildAnimation` returns `controller.drive(CurveTween(...))` instead of a
`CurvedAnimation`. The original is built on every rebuild of an `Animate` widget, registers
itself on the controller and is never disposed, so each rebuild leaked one object per effect
for the life of the widget (gskinner/flutter_animate#155, fixed by upstream PR #166).

Remove this directory and the `dependency_overrides` entry in `pubspec.yaml` once a released
flutter_animate carries the fix.
