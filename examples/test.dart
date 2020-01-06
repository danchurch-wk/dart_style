import 'package:meta/meta.dart';

class Logger {
  String f;
  String d;
  String c;

  Logger({String m, @required String d = null}) : this.f = m, d = d, c = null;

  void test({String m, @required String d = null}) {

  }

  @override
  int onCreateV2(int x, int y, {
    int contextMenuGroupFactory,
    @required String key,
    @required String wuri,
    int styles,
    String tooltipText,
    String overlayText,
  }) {
    return 0;
  }
}

void main() {
  int x = null;
}