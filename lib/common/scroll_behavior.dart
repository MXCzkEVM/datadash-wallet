import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';


  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get drdfdfagDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
