// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file

// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Enum-like class for the different syntactic fixes that can be applied while
/// formatting.
class StyleFix {
  static const docComments = StyleFix._(
      'doc-comments', 'Use triple slash for documentation comments.');

  static const functionTypedefs = StyleFix._(
      'function-typedefs', 'Use new syntax for function type typedefs.');

  static const namedDefaultSeparator = StyleFix._('named-default-separator',
      'Use "=" as the separator before named parameter default values.');

  static const optionalConst = StyleFix._(
      'optional-const', 'Remove "const" keyword inside constant context.');

  static const optionalNew =
      StyleFix._('optional-new', 'Remove "new" keyword.');

  static const singleCascadeStatements = StyleFix._('single-cascade-statements',
      'Remove unnecessary single cascades from expression statements.');

  static const preferSingleQuotes =
      StyleFix._('prefer-single-quotes', 'Replace double quotes with single quotes when the double quotes are not necessary.');

  static const sortImports = StyleFix._('sort-imports', 'Sort imports. Use with package-name to sort them into their own section.');

  static const sortProps = StyleFix._('sort-props', 'Sort cascades.');

  static const unnecessaryParenthesis = StyleFix._('unnecessary-parenthesis', 'Remove unnecessary parenthesis.');

  static const requiredFirst = StyleFix._('required-parameters-first', 'Sort required parameters first');

  static const noThis = StyleFix._('no-this', '“This” is bad, pls no');


  // WIP, don't use

  static const preferTrailingParameterListComma = StyleFix._('prefer-trailing-parameter-list-comma', 'Adds a trailing comma to parameter lists that exceed the page width.');

  static const String wipMessage = 'WIP - Do not use.';
  static const preferMultilineCascade = StyleFix._('prefer-multiline-cascade', '$wipMessage Ensure each part of a cascade is on it\'s own line');

  static const preferWhereType = StyleFix._('prefer-iterable-whereType', '$wipMessage [].where((v) => v is T) -> [].whereType<T>()');
  static const preferVoidToNull  = StyleFix._('prefer-void-to-null', '$wipMessage Null -> void');

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
    preferTrailingParameterListComma,
    preferMultilineCascade,
    requiredFirst,
    noThis,
    singleCascadeStatements,
  ];

  final String name;
  final String description;

  const StyleFix._(this.name, this.description);
}
