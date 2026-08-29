import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';

String buildCsv(List<Transaction> txns) {
  final buf = StringBuffer();
  buf.writeln('Date,Type,Category,Note,Amount');
  for (final t in txns) {
    final date =
        '${t.date.year.toString().padLeft(4, '0')}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
    final cat = (t.category?.name ?? 'Uncategorized').replaceAll('"', '""');
    final note = t.note.replaceAll('"', '""');
    buf.writeln('$date,${t.type.name},"$cat","$note",${t.amount.toStringAsFixed(2)}');
  }
  return buf.toString();
}

Future<void> shareCsv(List<Transaction> txns, {String fileName = 'expenses.csv'}) async {
  final csv = buildCsv(txns);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(csv);
  await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'text/csv', name: fileName)], text: 'Expense export'));
}
