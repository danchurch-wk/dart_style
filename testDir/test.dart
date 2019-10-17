
@TestOn()
import 'dart:collection';
import 'dart:async';

import 'package:w_sox/ui_core.dart';

import 'package:meta/meta.dart';
import 'package:path/path.dart';

class M {
  int a;
  bool b;
  Object c;
  Function d;
  String f;

  void e() {}
  void aa() {}
}

class Test {
  Test() {
    new M()
      ..b = false
      ..c = true
      ..e()
      ..aa()
      // comment for d
      ..d = () {

      }
      ..f = "double quotes"
      ..a = 0;
  }
}