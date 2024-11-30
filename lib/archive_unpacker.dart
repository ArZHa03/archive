part of 'archive.dart';

class _ArchiveUnpacker {
  _ArchiveUnpacker(this._bytes);

  final Uint8List _bytes;
  int _offset = 0;
  final ByteData _byteData = ByteData(8); // ByteData for numbers

  BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (var byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }

  dynamic _decode() {
    if (_offset >= _bytes.length) throw _UnexpectedError('Unexpected end of input');

    final int prefix = _bytes[_offset++];

    if (prefix <= 0x7F) return prefix; // Positive FixInt
    if (prefix >= 0xE0) return prefix - 256; // Negative FixInt
    if (prefix >= 0xA0 && prefix <= 0xBF) return _readString(prefix & 0x1F);
    if (prefix >= 0x90 && prefix <= 0x9F) return _readArray(prefix & 0x0F);
    if (prefix >= 0x80 && prefix <= 0x8F) return _readMap(prefix & 0x0F);

    if (prefix == 0xC0) return null;
    if (prefix == 0xC2) return false;
    if (prefix == 0xC3) return true;

    if (prefix == 0xCC) return _readUint(1);
    if (prefix == 0xCD) return _readUint(2);
    if (prefix == 0xCE) return _readUint(4);
    if (prefix == 0xCF) return _readUint(8);

    if (prefix == 0xD0) return _readInt(1);
    if (prefix == 0xD1) return _readInt(2);
    if (prefix == 0xD2) return _readInt(4);
    if (prefix == 0xD3) return _readInt(8);

    if (prefix == 0xCB) return _readDouble();

    if (prefix == 0xD9) return _readString(_readUint(1));
    if (prefix == 0xDA) return _readString(_readUint(2));
    if (prefix == 0xDB) return _readString(_readUint(4));

    if (prefix == 0xC4) return _readBinary(_readUint(1));
    if (prefix == 0xC5) return _readBinary(_readUint(2));
    if (prefix == 0xC6) return _readBinary(_readUint(4));

    if (prefix == 0xDC) return _readArray(_readUint(2));
    if (prefix == 0xDD) return _readArray(_readUint(4));

    if (prefix == 0xDE) return _readMap(_readUint(2));
    if (prefix == 0xDF) return _readMap(_readUint(4));

    if (prefix == 0xC7) {
      // ext 8
      final length = _bytes[_offset++];
      return _readExt(length);
    }

    if (prefix == 0xC8) {
      // ext 16
      final length = _readUint(2);
      return _readExt(length);
    }

    if (prefix == 0xC9) {
      // ext 32
      final length = _readUint(4);
      return _readExt(length);
    }

    throw UnsupportedError('Unknown prefix: 0x${prefix.toRadixString(16)}');
  }

  int _readUint(int byteCount) {
    if (_offset + byteCount > _bytes.length) throw _UnexpectedError('Unexpected end of input');

    int value = 0;
    for (int i = 0; i < byteCount; i++) {
      value = (value << 8) | _bytes[_offset++];
    }
    return value;
  }

  int _readInt(int byteCount) {
    if (_offset + byteCount > _bytes.length) throw _UnexpectedError('Unexpected end of input');
    for (int i = 0; i < byteCount; i++) {
      _byteData.setUint8(i, _bytes[_offset++]);
    }
    if (byteCount == 1) return _byteData.getInt8(0);
    if (byteCount == 2) return _byteData.getInt16(0, Endian.big);
    if (byteCount == 4) return _byteData.getInt32(0, Endian.big);
    if (byteCount == 8) return _byteData.getInt64(0, Endian.big);
    return 0;
  }

  double _readDouble() {
    if (_offset + 8 > _bytes.length) throw _UnexpectedError('Unexpected end of input');

    for (int i = 0; i < 8; i++) {
      _byteData.setUint8(i, _bytes[_offset++]);
    }
    return _byteData.getFloat64(0, Endian.big);
  }

  String _readString(int length) {
    if (_offset + length > _bytes.length) throw _UnexpectedError('Unexpected end of input');

    final str = utf8.decode(_bytes.sublist(_offset, _offset + length));
    _offset += length;

    return str;
  }

  Uint8List _readBinary(int length) {
    if (_offset + length > _bytes.length) {
      throw _UnexpectedError('Unexpected end of input');
    }
    final result = Uint8List.view(_bytes.buffer, _bytes.offsetInBytes + _offset, length);
    _offset += length;
    return result;
  }

  List<dynamic> _readArray(int length) {
    final list = List<dynamic>.filled(length, null, growable: false);
    for (int i = 0; i < length; i++) {
      list[i] = _decode();
    }
    return list;
  }

  Map<dynamic, dynamic> _readMap(int length) {
    final map = <dynamic, dynamic>{};
    for (int i = 0; i < length; i++) {
      final key = _decode();
      final value = _decode();
      map[key] = value;
    }
    return map;
  }

  dynamic _readExt(int length) {
    if (_offset + length > _bytes.length) throw _UnexpectedError('Unexpected end of input');

    final type = _bytes[_offset++];

    if (type == 0x01) {
      // BigInt type code
      if (length < 1) throw StateError('Invalid length for BigInt ext');

      final signByte = _bytes[_offset++];
      final isNegative = signByte == 0x01;
      final magnitudeLength = length - 1; // Subtract sign byte length
      final magnitudeBytes = Uint8List.sublistView(_bytes, _offset, _offset + magnitudeLength);
      _offset += magnitudeLength;
      final magnitude = _bytesToBigInt(magnitudeBytes);
      final value = isNegative ? -magnitude : magnitude;
      return value;
    }

    if (type == 0xFF) {
      // DateTime type code
      if (length != 12) throw _UnexpectedError('Unexpected ext length for DateTime: $length');

      final millisecondsSinceEpoch = _readInt(8);
      final microsecond = _readInt(4);
      return DateTime.fromMicrosecondsSinceEpoch(millisecondsSinceEpoch * 1000 + microsecond, isUtc: false);
    }

    // Handle other ext types or throw an error
    final data = Uint8List.sublistView(_bytes, _offset, _offset + length - 1);
    _offset += length - 1;
    return {'type': type, 'data': data};
  }
}
