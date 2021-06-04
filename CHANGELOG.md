## 2.2.0

- Support `BitArray` constructing from `Uint8List` and parsing from binary strings. ([#12](https://github.com/isoos/bit_array/pull/12) by [yanivshaked](https://github.com/yanivshaked)).
- Fix `BitSet` highest index. ([#10](https://github.com/isoos/bit_array/pull/10) by [yanivshaked](https://github.com/yanivshaked)).

## 2.1.0

- Migrated to null-safety. ([#5](https://github.com/isoos/bit_array/pull/5) by [eugmes](https://github.com/eugmes)).

## 2.0.0

**BREAKING CHANGES**
- Changed internal 64-bit int storage to 32-bit ints to be able to run in browsers.
- `asUint32Iterable` instead of `asUint64Iterable`

## 1.2.0

- Counter multiplication can be done with `operator *`.
- Support of masking counter (with threshold value).
- Support of efficient `min` and `max` operations in counters.

## 1.1.0

- `CompositeSet.clone` returns `CompositeSet`.
- Support `shiftLeft` in many operations.
- Support multiply and clone of counters.
- Use `package:pedantic` and Dart 2.2 features.

## 1.0.1

- `asUint64Iterable()` added to provide interface-level compatibility for future compressed bit arrays.
- `BitSet` to have a non-bitarray backed interface (eg. compressed structures).
- `CompositeSet` and `CompositeCounter` for arbitrary-large compressed bitmap operations.

## 1.0.0

- Initial version.
