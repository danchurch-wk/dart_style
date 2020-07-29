// irdartfmt -w -l 120 --fix-sort-props

class CascadesForDays {
  int a;
  void b() {}
  String c;
  Object d;
  String e() => 'five';
  String get f => 'two';
  set g(String r) {}

  Function foo;
}

void main() {
  CascadesForDays()
    ..g = ''
    ..f
    ..e()
    // A very interesting comment about `c`
    ..c = ''
    ..a = 5
    ..b()
    ..d = (CascadesForDays()
      ..e()
      // This line really needs
      // two lines of comments
      ..d = (CascadesForDays()
        ..g = ''
        ..f
        ..e()
        ..d = Object()
        ..a // EOL comment
        ..b()
        ..g = ''
        ..foo = () => null)
      ..f
      ..b()
      ..c = ''
      ..g = ''
      ..a = 5);
}
