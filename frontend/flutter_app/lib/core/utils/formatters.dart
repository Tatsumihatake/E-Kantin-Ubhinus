import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String rupiah(num value) => _currency.format(value);

String dateTimeLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }

  return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(value.toLocal());
}

double parseMoney(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '0') ?? 0;
}
