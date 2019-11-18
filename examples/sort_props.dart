// irdartfmt -w -l 120 --fix-sort-props

class CascadesForDays {
  int a;
  void b() {}
  String c;
  Object d;
  String e() => 'five';
  String get f => 'two';
  set g(String r) {}
}

void main() {
  CascadesForDays()
    ..f
    ..g = ''
    ..e()
    ..a = 5
    // A very interesting comment about `c`
    ..c = ''
    ..b()
    ..d = (CascadesForDays()
      ..e()
      ..a = 5
      // This line really needs
      // two lines of comments
      ..d = (CascadesForDays()
        ..f
        ..g = ''
        ..e()
        ..c = ''
        ..d = Object()
        ..b()
        ..a = 5)
      ..f
      ..b()
      ..c = ''
      ..g = '');
}
