import 'package:flutter/material.dart';

extension SpacingExt on num {
  /// Height space helper (SizedBox(height: num))
  SizedBox get vSpace => SizedBox(height: toDouble());

  /// Width space helper (SizedBox(width: num))
  SizedBox get hSpace => SizedBox(width: toDouble());
}
