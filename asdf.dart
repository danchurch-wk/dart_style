Future<Null> test() async => null;

void main() {
  ((5 + 4));

  final x = (5);

  final z = (x + 2) * 5;

  [0, 1, 2].where((e) => e is int);

  Iterable<num>  j = [0.2, 1, 3];

  Iterable<int> m = j.where((l) => l is! int);

  Null f() {}
  Future<Null> fr() {}
  Stream<Null> fg() {}

  Map<Null, Null> d = <Null, Null>{};

  print('test' + x.toString() + 'five');
}

fr(Null x) {}