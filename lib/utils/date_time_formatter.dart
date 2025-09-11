import 'package:intl/intl.dart';

extension DateTimeFormatter on DateTime {
  String format() {
    return DateFormat.yMMMd().add_Hm().format(this);
  }
}
