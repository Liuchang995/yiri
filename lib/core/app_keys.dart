import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);

final GlobalKey rootBoundaryKey = GlobalKey(debugLabel: 'rootBoundary');
