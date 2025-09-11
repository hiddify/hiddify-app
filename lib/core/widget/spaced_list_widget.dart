import 'package:flutter/widgets.dart';

extension SpacedWidgets on List<Widget> {
  List<Widget> spaceBy({double? width, double? height}) => [
        for (int i = 0; i < length; i++) ...[
          if (i > 0) SizedBox(width: width, height: height),
          this[i],
        ],
      ];
}
