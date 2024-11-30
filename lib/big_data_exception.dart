part of 'archive.dart';

class _BigDataException implements Exception {
  _BigDataException(this.data);
  final dynamic data;

  @override
  String toString() => 'Data $data is too big to process';
}
