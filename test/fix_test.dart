// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn("vm")
library irdartfmt.test.fix_test;

import 'package:test/test.dart';

import 'package:irdartfmt/irdartfmt.dart';

import 'utils.dart';

void main() {
  testFile(
      "fixes/named_default_separator.unit", [StyleFix.namedDefaultSeparator]);
  testFile("fixes/doc_comments.stmt", [StyleFix.docComments]);
  testFile("fixes/function_typedefs.unit", [StyleFix.functionTypedefs]);
  testFile("fixes/optional_const.unit", [StyleFix.optionalConst]);
  testFile("fixes/optional_new.stmt", [StyleFix.optionalNew]);
}
