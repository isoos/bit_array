import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

/// Bit array to store bits.
class BitArray {
  Uint64List _data;
  int _length;

  BitArray._(this._data) : _length = _data.length << 6;

  /// Creates a bit array with maximum [length] items.
  ///
  /// [length] will be rounded up to match the 64-bit boundary.
  factory BitArray(int length) =>
      new BitArray._(new Uint64List(_bufferLength64(length)));

  /// Creates a bit array using a byte buffer.
  factory BitArray.fromByteBuffer(ByteBuffer buffer) {
    final data = buffer.asUint64List();
    return new BitArray._(data);
  }

  /// The value of the bit with the specified [index].
  bool operator [](int index) {
    return (_data[index >> 6] & _bitMask[index & 0x3f]) != 0;
  }

  /// Sets the bit specified by the [index] to the [value].
  void operator []=(int index, bool value) {
    if (value) {
      setBit(index);
    } else {
      clearBit(index);
    }
  }

  /// The number of bit in this [BitArray].
  ///
  /// [length] will be rounded up to match the 64-bit boundary.
  ///
  /// The valid index values for the array are `0` through `length - 1`.
  int get length => _length;
  void set length(int value) {
    if (_length == value) {
      return;
    }
    final data = new Uint64List(_bufferLength64(value));
    data.setRange(0, math.min(data.length, _data.length), _data);
    _data = data;
    _length = _data.length << 6;
  }

  /// The number of bits set to true.
  int get cardinality => _data.buffer
      .asUint8List()
      .fold(0, (sum, value) => sum + _cardinalityBitCounts[value]);

  /// Sets the bit specified by the [index] to false.
  void clearBit(int index) {
    _data[index >> 6] &= _clearMask[index & 0x3f];
  }

  /// Sets the bits specified by the [indexes] to false.
  void clearBits(Iterable<int> indexes) {
    indexes.forEach(clearBit);
  }

  /// Sets all of the bits in the current [BitArray] to false.
  void clearAll() {
    for (int i = 0; i < _data.length; i++) {
      _data[i] = 0;
    }
  }

  /// Sets the bit specified by the [index] to true.
  void setBit(int index) {
    _data[index >> 6] |= _bitMask[index & 0x3f];
  }

  /// Sets the bits specified by the [indexes] to true.
  void setBits(Iterable<int> indexes) {
    indexes.forEach(setBit);
  }

  /// Sets all the bit values in the current [BitArray] to true.
  void setAll() {
    for (int i = 0; i < _data.length; i++) {
      _data[i] = -1;
    }
  }

  /// Inverts the bit specified by the [index].
  void invertBit(int index) {
    this[index] = !this[index];
  }

  /// Inverts the bits specified by the [indexes].
  void invertBits(Iterable<int> indexes) {
    indexes.forEach(invertBit);
  }

  /// Inverts all the bit values in the current [BitArray].
  void invertAll() {
    for (int i = 0; i < _data.length; i++) {
      _data[i] = ~_data[i];
    }
  }

  /// Update the current [BitArray] using a logical AND operation with the
  /// corresponding elements in the specified [array].
  /// Excess size of the [array] is ignored.
  void and(BitArray array) {
    final minLength = math.min(_data.length, array._data.length);
    for (int i = 0; i < minLength; i++) {
      _data[i] &= array._data[i];
    }
    for (int i = minLength; i < _data.length; i++) {
      _data[i] = 0;
    }
  }

  /// Update the current [BitArray] using a logical AND NOT operation with the
  /// corresponding elements in the specified [array].
  /// Excess size of the [array] is ignored.
  void andNot(BitArray array) {
    final minLength = math.min(_data.length, array._data.length);
    for (int i = 0; i < minLength; i++) {
      _data[i] &= ~array._data[i];
    }
  }

  /// Update the current [BitArray] using a logical OR operation with the
  /// corresponding elements in the specified [array].
  /// Excess size of the [array] is ignored.
  void or(BitArray array) {
    final minLength = math.min(_data.length, array._data.length);
    for (int i = 0; i < minLength; i++) {
      _data[i] |= array._data[i];
    }
  }

  /// Update the current [BitArray] using a logical XOR operation with the
  /// corresponding elements in the specified [array].
  /// Excess size of the [array] is ignored.
  void xor(BitArray array) {
    final minLength = math.min(_data.length, array._data.length);
    for (int i = 0; i < minLength; i++) {
      _data[i] = _data[i] ^ array._data[i];
    }
  }

  /// Creates a copy of the current [BitArray].
  BitArray clone() {
    final newData = new Uint64List(_data.length);
    newData.setRange(0, _data.length, _data);
    return new BitArray._(newData);
  }

  /// Creates a new [BitArray] using a logical AND operation with the
  /// corresponding elements in the specified [array].
  BitArray operator &(BitArray array) => clone()..and(array);

  /// Creates a new [BitArray] using a logical AND NOT operation with the
  /// corresponding elements in the specified [array].
  BitArray operator %(BitArray array) => clone()..andNot(array);

  /// Creates a new [BitArray] using a logical OR operation with the
  /// corresponding elements in the specified [array].
  BitArray operator |(BitArray array) => clone()..or(array);

  /// Creates a new [BitArray] using a logical XOR operation with the
  /// corresponding elements in the specified [array].
  BitArray operator ^(BitArray array) => clone()..xor(array);

  /// Creates a string of 0s and 1s of the content of the array.
  String toBinaryString() {
    final sb = new StringBuffer();
    for (int i = 0; i < length; i++) {
      sb.write(this[i] ? '1' : '0');
    }
    return sb.toString();
  }

  /// The backing, mutable byte buffer of the [BitArray].
  /// Use with caution.
  ByteBuffer get byteBuffer => _data.buffer;

  /// The backing, mutable 64-bit int list of the [BitArray].
  /// Use with caution.
  Uint64List get asUint64List => _data;

  /// Returns an iterable wrapper of the bit array that iterates over the index
  /// numbers that match [value] (by default the bits that are set).
  Iterable<int> asIntIterable([bool value = true]) {
    return new _IntIterable(this, value);
  }
}

final _bitMask = new List<int>.generate(64, (i) => 1 << i);
final _clearMask = new List<int>.generate(64, (i) => ~(1 << i));
final _cardinalityBitCounts = new List<int>.generate(256, _cardinalityOfByte);

int _cardinalityOfByte(int value) {
  int result = 0;
  while (value > 0) {
    if (value & 0x01 != 0) {
      result++;
    }
    value = value >> 1;
  }
  return result;
}

class _IntIterable extends IterableBase<int> {
  final BitArray _array;
  final bool _value;
  _IntIterable(this._array, this._value);

  @override
  Iterator<int> get iterator =>
      new _IntIterator(_array._data, _array.length, _value);
}

class _IntIterator implements Iterator<int> {
  final Uint64List _buffer;
  final int _length;
  final bool _matchValue;
  final int _skipMatch;
  final int _cursorMax = (1 << 63);
  int _current = -1;
  int _cursor = 0;
  int _cursorByte = 0;
  int _cursorMask = 1;

  _IntIterator(this._buffer, this._length, this._matchValue)
      : _skipMatch = _matchValue ? 0x00 : 0xffffffffffffffff;

  @override
  int get current => _current;

  @override
  bool moveNext() {
    while (_cursor < _length) {
      final value = _buffer[_cursorByte];
      if (_cursorMask == 1 && value == _skipMatch) {
        _cursorByte++;
        _cursor += 64;
        continue;
      }
      final isSet = (value & _cursorMask) != 0;
      if (isSet == _matchValue) {
        _current = _cursor;
        _increment();
        return true;
      }
      _increment();
    }
    return false;
  }

  void _increment() {
    if (_cursorMask == _cursorMax) {
      _cursorMask = 1;
      _cursorByte++;
    } else {
      _cursorMask <<= 1;
    }
    _cursor++;
  }
}

int _bufferLength64(int length) {
  final hasExtra = (length & 0x3f) != 0;
  return (length >> 6) + (hasExtra ? 1 : 0);
}
