# Bit array implementation in Dart

A bit array (also known as BitMap, BitSet, BitString, or BitVector)
is an array data structure that compactly stores bits.

## Usage

A simple usage example:

```dart
import 'package:bit_array/bit_array.dart';

void main() {
  final array = BitArray(1024);
  array[12] = true;
  array.setBit(123);
  array.invertBit(200);
  array.clearBit(12);
  print(array.asIntIterable().toList()); // prints [123, 200]

  final other = BitArray(1024);
  other[123] = true;

  final and = array & other;
  print(and.asIntIterable().toList()); // prints [123]
}
```
