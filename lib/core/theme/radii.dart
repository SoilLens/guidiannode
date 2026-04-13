import 'package:flutter/widgets.dart';

class AppRadii {
  const AppRadii._();

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(md),
  );
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}
