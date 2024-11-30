part of 'archive.dart';

class _UnexpectedError implements Exception {
  _UnexpectedError(this.message);
  final String message;

  @override
  String toString() => 'Unexpected error: $message';
}
