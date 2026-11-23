import 'package:material_ui/material_ui.dart';

/// Window size classes (Material 3 breakpoints). Layout is driven by the
/// width the app actually has, never by a device model.
enum WindowClass {
  /// Phones in portrait: bottom tabs, one column.
  compact,

  /// Large phones, small tablets, split screen: side tabs, a wider column.
  medium,

  /// Tablets: side tabs, text a little larger, column capped for reading.
  expanded;

  static WindowClass ofWidth(double width) => width < 600
      ? compact
      : width < 840
      ? medium
      : expanded;

  static WindowClass of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);

  bool get usesSideNav => this != compact;

  /// Widest the content column grows: long lines are hard to read.
  double get contentMaxWidth => switch (this) {
    compact => double.infinity,
    medium => 680,
    expanded => 760,
  };

  /// Multiplies the text size so the screen is read at the same visual size
  /// at arm's length on a tablet as on a phone.
  double get textBoost => switch (this) {
    compact => 1.0,
    medium => 1.1,
    expanded => 1.2,
  };
}

/// True when the window is short (a small phone, or split screen), so
/// chrome such as the title bar can take less height.
bool isShortWindow(BuildContext context) =>
    MediaQuery.sizeOf(context).height < 600;
