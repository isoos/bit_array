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
