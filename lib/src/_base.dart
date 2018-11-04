part of bit_array;

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
