// Development-only gate. Does not enable PDF export in the application.
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  final directory = Directory('docs/validation/stage17/pdf');
  await directory.create(recursive: true);
  final font = pw.Font.ttf(
    ByteData.sublistView(
      await File('assets/fonts/Vazirmatn-Regular.ttf').readAsBytes(),
    ),
  );
  final bold = pw.Font.ttf(
    ByteData.sublistView(
      await File('assets/fonts/Vazirmatn-Bold.ttf').readAsBytes(),
    ),
  );
  final image = pw.MemoryImage(
    await File('assets/branding/logo.png').readAsBytes(),
  );
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: bold),
  );
  final samples = <String>[
    'جعبه‌ابزار مدیریت',
    'سازنده حسین بختیاری',
    'پژوهش، چگالی، گسترش و کیفیت',
    'می‌روم؛ بهره‌وری و سرمایه‌گذاری',
    'NPV = 125,000 ریال؛ نرخ ۲۰٪ و OEE = 83.79%',
    'تبدیل 32 °F به 0 °C؛ تغییر −25٪',
    'کارگاه ۱۴۰۵/۰۷/۲۴؛ نتیجه (ROI): ۱۲۳٫۴۵',
  ];
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      header: (_) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('گزارش آزمایشی فارسی'),
          pw.Image(image, width: 48, height: 48),
        ],
      ),
      footer: (c) => pw.Text('صفحه ${c.pageNumber} از ${c.pagesCount}'),
      build: (_) => [
        for (var i = 0; i < samples.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(samples[i], style: const pw.TextStyle(fontSize: 18)),
          ),
        pw.NewPage(),
        for (var i = 0; i < 40; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text(
              'ردیف ${i + 1} — ${samples[i % samples.length]}',
              style: const pw.TextStyle(fontSize: 14),
            ),
          ),
      ],
    ),
  );
  await File('${directory.path}/persian-probe.pdf')
      .writeAsBytes(await doc.save());
  await File('${directory.path}/logical-input.txt')
      .writeAsString(samples.join('\n'));
  stdout.writeln(
    'Generated branded Persian/mixed text/multipage PDF, pdf 3.13.1. Rendering acceptance is separate.',
  );
}
