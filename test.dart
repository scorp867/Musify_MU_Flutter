import 'dart:math';

void main() {
  String? x = Random().nextBool() ? '123' : null;
  var m = {
    'k': ?x,
    'y': ?(x != null ? 'Bearer $x' : null),
  };
  print(m);
}
