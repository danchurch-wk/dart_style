// irdartfmt -w -l 120 --fix-unnecessary-parenthesis

class FuncParam {
  Function f;

  FuncParam(this.f);
}

class ReactElement {
  int x;
  int y;

  void call() {}
}

void main() {
  print('Lisp, is that you?');
  print(5 + 4 * 3);
  print((5 + 4) * 3);
  print(((5) + (4)) * (3));

  FuncParam((_) {});

  (ReactElement())();
  ReactElement()();
  (ReactElement())();
  (ReactElement()
    ..x = 5
    ..y = 10
  )();
}
