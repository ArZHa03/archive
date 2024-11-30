part of 'archive.dart';

class _ArchivePacker {
  Uint8List _buffer = Uint8List(1024 * 8); // 8KB buffer
  int _offset = 0;

  final ByteData _byteData = ByteData(8); // ByteData for numbers

  void _ensureBuffer(int length) {
    while (_offset + length > _buffer.length) {
      final newBuffer = Uint8List(_buffer.length * 2);
      newBuffer.setRange(0, _offset, _buffer);
      _buffer = newBuffer;
    }
  }

  void _encode(dynamic value) {
    if (value == null) {
      _ensureBuffer(1);
      _buffer[_offset++] = 0xC0;
      return;
    }

    if (value is bool) {
      _ensureBuffer(1);
      _buffer[_offset++] = value ? 0xC3 : 0xC2;
      return;
    }

    if (value is int) return _encodeInt(value);
    if (value is double) return _encodeDouble(value);
    if (value is String) return _encodeString(value);
    if (value is Uint8List) return _encodeBinary(value);
    if (value is Iterable) return _encodeArray(value);
    if (value is Map) return _encodeMap(value);
    if (value is DateTime) return _encodeDateTime(value);
    if (value is BigInt) return _encodeBigInt(value);

    throw UnsupportedError('Unsupported type: ${value.runtimeType}');
  }

  void _encodeInt(int value) {
    if (value >= 0 && value <= 0x7F) {
      _ensureBuffer(1);
      _buffer[_offset++] = value;
    } else if (value < 0 && value >= -32) {
      _ensureBuffer(1);
      _buffer[_offset++] = 0xE0 | (value + 32);
    } else if (value >= -128 && value <= 127) {
      _ensureBuffer(2);
      _buffer[_offset++] = 0xD0;
      _buffer[_offset++] = value & 0xFF;
    } else if (value >= -32768 && value <= 32767) {
      _ensureBuffer(3);
      _buffer[_offset++] = 0xD1;
      _byteData.setInt16(0, value, Endian.big);
      _buffer[_offset++] = _byteData.getUint8(0);
      _buffer[_offset++] = _byteData.getUint8(1);
    } else if (value >= -2147483648 && value <= 2147483647) {
      _ensureBuffer(5);
      _buffer[_offset++] = 0xD2;
      _byteData.setInt32(0, value, Endian.big);
      _buffer[_offset++] = _byteData.getUint8(0);
      _buffer[_offset++] = _byteData.getUint8(1);
      _buffer[_offset++] = _byteData.getUint8(2);
      _buffer[_offset++] = _byteData.getUint8(3);
    } else {
      _ensureBuffer(9);
      _buffer[_offset++] = 0xD3;
      _byteData.setInt64(0, value, Endian.big);
      for (int i = 0; i < 8; i++) {
        _buffer[_offset++] = _byteData.getUint8(i);
      }
    }
  }

  void _encodeDouble(double value) {
    _ensureBuffer(9);
    _buffer[_offset++] = 0xCB;
    _byteData.setFloat64(0, value, Endian.big);
    for (int i = 0; i < 8; i++) {
      _buffer[_offset++] = _byteData.getUint8(i);
    }
  }

  void _encodeString(String value) {
    final encoded = utf8.encode(value);
    final length = encoded.length;
    if (length <= 31) {
      _ensureBuffer(1 + length);
      _buffer[_offset++] = 0xA0 | length;
    } else if (length <= 0xFF) {
      _ensureBuffer(2 + length);
      _buffer[_offset++] = 0xD9;
      _buffer[_offset++] = length;
    } else if (length <= 0xFFFF) {
      _ensureBuffer(3 + length);
      _buffer[_offset++] = 0xDA;
      _byteData.setUint16(0, length, Endian.big);
      _buffer[_offset++] = _byteData.getUint8(0);
      _buffer[_offset++] = _byteData.getUint8(1);
    } else if (length <= 0xFFFFFFFF) {
      _ensureBuffer(5 + length);
      _buffer[_offset++] = 0xDB;
      _byteData.setUint32(0, length, Endian.big);
      for (int i = 0; i < 4; i++) {
        _buffer[_offset++] = _byteData.getUint8(i);
      }
    } else {
      throw _BigDataException(value);
    }
    _ensureBuffer(length);
    _buffer.setRange(_offset, _offset + length, encoded);
    _offset += length;
  }

  void _encodeBinary(Uint8List data) {
    final length = data.length;
    if (length <= 0xFF) {
      _ensureBuffer(2 + length);
      _buffer[_offset++] = 0xC4;
      _buffer[_offset++] = length;
    } else if (length <= 0xFFFF) {
      _ensureBuffer(3 + length);
      _buffer[_offset++] = 0xC5;
      _byteData.setUint16(0, length, Endian.big);
      _buffer[_offset++] = _byteData.getUint8(0);
      _buffer[_offset++] = _byteData.getUint8(1);
    } else if (length <= 0xFFFFFFFF) {
      _ensureBuffer(5 + length);
      _buffer[_offset++] = 0xC6;
      _byteData.setUint32(0, length, Endian.big);
      for (int i = 0; i < 4; i++) {
        _buffer[_offset++] = _byteData.getUint8(i);
      }
    } else {
      throw _BigDataException(data);
    }
    _ensureBuffer(length);
    _buffer.setRange(_offset, _offset + length, data);
    _offset += length;
  }

  void _encodeArray(Iterable iterable) {
    final length = iterable.length;
    if (length <= 0xF) {
      _ensureBuffer(1);
      _buffer[_offset++] = 0x90 | length;
    } else if (length <= 0xFFFF) {
      _ensureBuffer(3);
      _buffer[_offset++] = 0xDC;
      _byteData.setUint16(0, length, Endian.big);
      _buffer[_offset++] = _byteData.getUint8(0);
      _buffer[_offset++] = _byteData.getUint8(1);
    } else if (length <= 0xFFFFFFFF) {
      _ensureBuffer(5);
      _buffer[_offset++] = 0xDD;
      _byteData.setUint32(0, length, Endian.big);
      for (int i = 0; i < 4; i++) {
        _buffer[_offset++] = _byteData.getUint8(i);
      }
    } else {
      throw _BigDataException(iterable);
    }
    for (final item in iterable) {
      _encode(item);
    }
  }

  void _encodeMap(Map<dynamic, dynamic> map) {
    final length = map.length;
    if (length <= 0xF) {
      _ensureBuffer(1);
      _buffer[_offset++] = 0x80 | length;
    } else if (length <= 0xFFFF) {
      _ensureBuffer(3);
      _buffer[_offset++] = 0xDE;
      _byteData.setUint16(0, length, Endian.big);
      _buffer[_offset++] = _byteData.getUint8(0);
      _buffer[_offset++] = _byteData.getUint8(1);
    } else if (length <= 0xFFFFFFFF) {
      _ensureBuffer(5);
      _buffer[_offset++] = 0xDF;
      _byteData.setUint32(0, length, Endian.big);
      for (int i = 0; i < 4; i++) {
        _buffer[_offset++] = _byteData.getUint8(i);
      }
    } else {
      throw _BigDataException(map);
    }
    for (final key in map.keys) {
      _encode(key);
      _encode(map[key]);
    }
  }

  void _encodeDateTime(DateTime value) {
    _ensureBuffer(1 + 1 + 1 + 12);
    _buffer[_offset++] = 0xC7; // ext 8
    _buffer[_offset++] = 12; // 12 bytes of data
    _buffer[_offset++] = 0xFF; // Type for DateTime
    _byteData.setInt64(0, value.millisecondsSinceEpoch, Endian.big);
    for (int i = 0; i < 8; i++) {
      _buffer[_offset++] = _byteData.getUint8(i);
    }
    _byteData.setInt32(0, value.microsecond, Endian.big);
    for (int i = 0; i < 4; i++) {
      _buffer[_offset++] = _byteData.getUint8(i);
    }
  }

  void _encodeBigInt(BigInt value) {
    final isNegative = value.isNegative;
    final magnitudeBytes = _bigIntToBytes(value.abs());
    final length = 1 + magnitudeBytes.length; // 1 byte for sign

    int headerSize = 0;
    if (length <= 0xFF) {
      headerSize = 2;
      _ensureBuffer(headerSize + length);
      _buffer[_offset++] = 0xC7; // ext 8
      _buffer[_offset++] = length;
    } else if (length <= 0xFFFF) {
      headerSize = 3;
      _ensureBuffer(headerSize + length);
      _buffer[_offset++] = 0xC8; // ext 16
      _byteData.setUint16(0, length, Endian.big);
      _buffer[_offset++] = _byteData.getUint8(0);
      _buffer[_offset++] = _byteData.getUint8(1);
    } else if (length <= 0xFFFFFFFF) {
      headerSize = 5;
      _ensureBuffer(headerSize + length);
      _buffer[_offset++] = 0xC9; // ext 32
      _byteData.setUint32(0, length, Endian.big);
      for (int i = 0; i < 4; i++) {
        _buffer[_offset++] = _byteData.getUint8(i);
      }
    }
    _buffer[_offset++] = 0x01; // BigInt
    _buffer[_offset++] = isNegative ? 0x01 : 0x00; // Sign byte
    _buffer.setRange(_offset, _offset + magnitudeBytes.length, magnitudeBytes);
    _offset += magnitudeBytes.length;
  }

  Uint8List _bigIntToBytes(BigInt value) {
    int bytesNeeded = (value.bitLength + 7) >> 3;
    final result = Uint8List(bytesNeeded);
    BigInt temp = value;
    for (int i = bytesNeeded - 1; i >= 0; i--) {
      result[i] = (temp & BigInt.from(0xFF)).toInt();
      temp = temp >> 8;
    }
    return result;
  }

  Uint8List _takeBytes() => Uint8List.view(_buffer.buffer, 0, _offset);
}
