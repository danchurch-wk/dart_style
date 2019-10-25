// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file

// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Enum-like class for the different syntactic fixes that can be applied while
/// formatting.
class StyleFix {
  static const docComments = StyleFix._(
      "doc-comments", 'Use triple slash for documentation comments.');

  static const functionTypedefs = StyleFix._(
      "function-typedefs", 'Use new syntax for function type typedefs.');

  static const namedDefaultSeparator = StyleFix._("named-default-separator",
      'Use "=" as the separator before named parameter default values.');

  static const optionalConst = StyleFix._(
      "optional-const", 'Remove "const" keyword inside constant context.');

  static const optionalNew =
      StyleFix._("optional-new", 'Remove "new" keyword.');

  static const preferSingleQuotes =
      StyleFix._('prefer-single-quotes', 'Replaces "s with \'s');
  static const sortImports = StyleFix._('sort-imports', 'Sort imports');
  static const sortProps = StyleFix._('sort-props', 'Sort props');
  static const preferWhereType = StyleFix._('prefer-iterable-whereType', 'Prefer iterable whereType');
  static const unnecessaryParenthesis  = StyleFix._('unnecessary-parenthesis', 'Unnecessary parenthesis');
  static const preferVoidToNull  = StyleFix._('prefer-void-to-null', 'Prefer void to null');

  static const all = [
    docComments,
    functionTypedefs,
    namedDefaultSeparator,
    optionalConst,
    optionalNew,
    preferSingleQuotes,
    sortImports,
    sortProps,
    preferWhereType,
    unnecessaryParenthesis,
    preferVoidToNull,
  ];

  final String name;
  final String description;

  const StyleFix._(this.name, this.description);
}
