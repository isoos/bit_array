part of bit_array;

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

  /// Returns an iterable wrapper of the bit array that iterates over the index
  /// numbers that match [value] (by default the bits that are set).
  Iterable<int> asIntIterable([bool value = true]) {
    return new _IntIterable(this, value);
  }
}
