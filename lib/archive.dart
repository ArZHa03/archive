import 'dart:convert';
import 'dart:typed_data';

part 'big_data_exception.dart';
part 'unexpected_error.dart';
part 'archive_packer.dart';
part 'archive_unpacker.dart';

class _Archive {
  static Uint8List pack(dynamic value) {
    final _ArchivePacker encoder = _ArchivePacker();
    encoder._encode(value);
    return encoder._takeBytes();
  }

  static T unpack<T>(Uint8List bytes) {
    final _ArchiveUnpacker decoder = _ArchiveUnpacker(bytes);
    return decoder._decode();
  }
}

extension ArchiveExtension on dynamic {
  Uint8List pack() => _Archive.pack(this);
}

extension ArchiveUint8ListExtension on Uint8List {
  T unpack<T>() => _Archive.unpack<T>(this);
}
