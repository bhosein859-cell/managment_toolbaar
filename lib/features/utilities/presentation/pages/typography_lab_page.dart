import 'package:flutter/material.dart';

import '../../../../core/utils/persian_numbers.dart';
import '../../../../core/widgets/ltr_text.dart';

class TypographyLabPage extends StatefulWidget {
  const TypographyLabPage({super.key});

  @override
  State<TypographyLabPage> createState() => _TypographyLabPageState();
}

class _TypographyLabPageState extends State<TypographyLabPage> {
  final _input = TextEditingController();
  double? _value;
  bool _hasInput = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('آزمایش فارسی و متن ترکیبی')),
    body: ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
      children: [
        Text(
          'نمونهٔ فونت وزیرمتن',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'جعبه‌ابزار مدیریت؛ حروف فارسی: گ چ پ ژ ی ک — نیم‌فاصله و نشانه‌گذاری.',
        ),
        const Text(
          'متن پررنگ فارسی',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text('فارسی، نام انگلیسی، مقدار و واحد:'),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('ظرفیت تولید'),
            const LtrText('Throughput'),
            LtrText('${PersianNumbers.format(1250.5)} kg/h'),
          ],
        ),
        const SizedBox(height: 16),
        const Text('فرمول در محدودهٔ چپ‌به‌راست:'),
        const LtrText('OEE = A × P × Q'),
        LtrText(
          'OEE = ${PersianNumbers.format(0.9)} × ${PersianNumbers.format(0.95)} × ${PersianNumbers.format(0.98)} = ${PersianNumbers.format(83.79)}%',
        ),
        const SizedBox(height: 16),
        const Text('شناسهٔ انگلیسی (بدون تبدیل ارقام شناسه):'),
        const LtrText('Android 8.0+ / Windows 10–11 / API 26'),
        const SizedBox(height: 24),
        TextField(
          key: const Key('numeric-input'),
          controller: _input,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            labelText: 'عدد آزمایشی',
            hintText: '۱۲۳٫۴۵ / ١٢٣٫٤٥ / 123.45',
            helperText: 'ممیز: نقطه یا ٫؛ جداکنندهٔ هزارگان: ٬ یا کاما با گروه‌بندی سه‌رقمی',
            helperMaxLines: 3,
            errorText: _hasInput && _value == null
                ? 'یک عدد معتبر وارد کنید.'
                : null,
          ),
          onChanged: (value) => setState(() {
            _hasInput = value.trim().isNotEmpty;
            _value = PersianNumbers.tryParse(value);
          }),
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            _value == null
                ? 'نتیجه‌ای برای نمایش نیست.'
                : 'نمایش فارسی: \u2066${PersianNumbers.format(_value!, decimalPlaces: 6)}\u2069',
            key: const Key('numeric-preview'),
          ),
        ),
        const SizedBox(height: 24),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.arrow_forward),
          title: Text('آیکون جهت‌دار باید با RTL هماهنگ باشد.'),
          subtitle: Text('دکمهٔ بازگشت در سمت راست نوار بالا بررسی شود.'),
        ),
      ],
    ),
  );
}
