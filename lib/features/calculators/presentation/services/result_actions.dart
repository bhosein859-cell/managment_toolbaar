import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

enum ResultShareStatus { shared, dismissed, unavailable }

abstract interface class ResultActions {
  Future<void> copyText(String text);
  Future<ResultShareStatus> shareText(String text, {Rect? origin});
}

final class PlatformResultActions implements ResultActions {
  const PlatformResultActions();
  @override
  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
  @override
  Future<ResultShareStatus> shareText(String text, {Rect? origin}) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: text,
        title: 'نتیجهٔ جعبه‌ابزار مدیریت',
        subject: 'نتیجهٔ محاسبه',
        sharePositionOrigin: origin,
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => ResultShareStatus.shared,
      ShareResultStatus.dismissed => ResultShareStatus.dismissed,
      ShareResultStatus.unavailable => ResultShareStatus.unavailable,
    };
  }
}
