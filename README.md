# Archive

A Flutter package to encode and decode data efficiently.

## Features

- Encode various data types including `int`, `double`, `String`, `Uint8List`, `Iterable`, `Map`, `DateTime`, and `BigInt`.
- Decode data back to its original form.
- Efficient handling of large data with buffer management.

## Getting started

To use this package, add `archive` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  archive:
    git: https://github.com/ArZHa03/archive.git
```

## Usage

### Packing Data

You can pack various data types into a `Uint8List` using the `pack` method.

```dart
import 'package:archive/archive.dart';

void main() {
  final packedData = 'Hello, World!'.pack();
  print(packedData);
}
```

### Unpacking Data

You can unpack a `Uint8List` back to its original form using the `unpack` method.

```dart
import 'package:archive/archive.dart';

void main() {
  final packedData = 'Hello, World!'.pack();
  final unpackedData = packedData.unpack<String>();
  print(unpackedData); // Output: Hello, World!
}
```