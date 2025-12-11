import 'package:intl/intl.dart';

extension DateTimeFormatter on DateTime {
  String format() => DateFormat.yMMMd().add_Hm().format(this);
}
