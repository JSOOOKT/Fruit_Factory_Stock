import 'package:intl/intl.dart';

class AppFormatters {
  static final DateFormat date = DateFormat('dd/MM/yyyy');
  static final DateFormat dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final NumberFormat decimal = NumberFormat('#,##0.0');

  static String kg(double value) => '${decimal.format(value)} KG';
}