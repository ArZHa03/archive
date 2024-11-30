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
    git:
      url: https://github.com/your-repo/archive.git
      ref: main
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

## Additional information

For more information, please refer to the [documentation](https://dart.dev/tools/pub/writing-package-pages).

To contribute to this package, please create a pull request on the [GitHub repository](https://github.com/your-repo/archive).

If you encounter any issues, please file an issue on the [GitHub repository](https://github.com/your-repo/archive/issues).
