/// Framework-independent failure; domain code does not import Flutter.
class AppFailure implements Exception {
  const AppFailure(this.message, {this.code = 'unknown'});

  final String message;
  final String code;

  @override
  String toString() => 'AppFailure($code): $message';
}
