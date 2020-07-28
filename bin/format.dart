// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:irdartfmt/src/cli/formatter_options.dart';
import 'package:irdartfmt/src/cli/options.dart';
import 'package:irdartfmt/src/cli/output.dart';
import 'package:irdartfmt/src/cli/show.dart';
import 'package:irdartfmt/src/cli/summary.dart';
import 'package:irdartfmt/src/io.dart';
import 'package:irdartfmt/src/style_fix.dart';

void main(List<String> args) {
  var parser = ArgParser(allowTrailingOptions: true);

  defineOptions(parser, oldCli: true);

  ArgResults argResults;
  try {
    argResults = parser.parse(args);
  } on FormatException catch (err) {
    usageError(parser, err.message);
  }

  if (argResults['help']) {
    printUsage(parser);
    return;
  }

  if (argResults['version']) {
    print(dartStyleVersion);
    return;
  }

  List<int> selection;
  try {
    selection = parseSelection(argResults, 'preserve');
  } on FormatException catch (exception) {
    usageError(parser, exception.message);
  }

  if (argResults['dry-run'] && argResults['overwrite']) {
    usageError(
        parser, 'Cannot use --dry-run and --overwrite at the same time.');
  }

  void checkForReporterCollision(String chosen, String other) {
    if (!argResults[other]) return;

    usageError(parser, 'Cannot use --$chosen and --$other at the same time.');
  }

  var show = Show.legacy;
  var summary = Summary.none;
  var output = Output.show;
  var setExitIfChanged = false;
  if (argResults['dry-run']) {
    checkForReporterCollision('dry-run', 'overwrite');
    checkForReporterCollision('dry-run', 'machine');

    show = Show.dryRun;
    output = Output.none;
  } else if (argResults['overwrite']) {
    checkForReporterCollision('overwrite', 'machine');

    if (argResults.rest.isEmpty) {
      usageError(parser,
          'Cannot use --overwrite without providing any paths to format.');
    }

    show = Show.overwrite;
    output = Output.write;
  } else if (argResults['machine']) {
    output = Output.json;
  }

  if (argResults['profile']) summary = Summary.profile();

  setExitIfChanged = argResults['set-exit-if-changed'];

  int pageWidth;
  try {
    pageWidth = int.parse(argResults['line-length']);
  } on FormatException catch (_) {
    usageError(
        parser,
        '--line-length must be an integer, was '
        '"${argResults['line-length']}".');
  }

  int indent;
  try {
    indent = int.parse(argResults['indent']);
    if (indent < 0 || indent.toInt() != indent) throw FormatException();
  } on FormatException catch (_) {
    usageError(
        parser,
        '--indent must be a non-negative integer, was '
        '"${argResults['indent']}".');
  }

  var followLinks = argResults['follow-links'];

  var fixes = <StyleFix>[];
  if (argResults['fix']) fixes.addAll(StyleFix.all);
  for (var fix in StyleFix.all) {
    if (argResults['fix-${fix.name}']) {
      if (argResults['fix']) {
        usageError(parser, '--fix-${fix.name} is redundant with --fix.');
      }

      fixes.add(fix);
    }
  }

  if (argResults.wasParsed('stdin-name') && argResults.rest.isNotEmpty) {
    usageError(parser, 'Cannot pass --stdin-name when not reading from stdin.');
  }

  String packageName = '';
  try {
    packageName = argResults["package-name"];
  } catch (e) {
    // do nothing
  }

  var options = FormatterOptions(
      indent: indent,
      pageWidth: pageWidth,
      followLinks: followLinks,
      fixes: fixes,
      packageName: packageName,
      show: show,
      output: output,
      summary: summary,
      setExitIfChanged: setExitIfChanged);

  if (argResults.rest.isEmpty) {
    formatStdin(options, selection, argResults['stdin-name'] as String);
  } else {
    formatPaths(options, argResults.rest);
  }

  options.summary.show();
}

/// Prints [error] and usage help then exits with exit code 64.
void usageError(ArgParser parser, String error) {
  printUsage(parser, error);
  exit(64);
}

void printUsage(ArgParser parser, [String error]) {
  var output = stdout;

  var message = 'Idiomatically formats Dart source code.';
  if (error != null) {
    message = error;
    output = stdout;
  }

  output.write('''$message

Usage:   dartfmt [options...] [files or directories...]

Example: dartfmt -w .
         Reformats every Dart file in the current directory tree.

${parser.usage}
''');
}

const List<String> defaultPaths = ['lib/'];
const List<String> defaultExclude = [];

/// Returns a set of files within [paths] to be formatted, with [exclude] excluded.
///
/// [paths] can contain both files and directories. Files within directories
/// will be processed recursively, ignoring symlinks.
///
/// If [exclude] is not empty, the return value will include [paths], expanded
/// to all matching files. Otherwise, it will not be expanded.
///
/// To force expansion, set [alwaysExpand] to `true`.
FilesToFormat getFilesToFormat({
  List<String> paths = defaultPaths,
  List<String> exclude = defaultExclude,
  bool alwaysExpand = false,
}) {
  var filesToFormat = FilesToFormat();

  if (exclude.isEmpty && !alwaysExpand) {
    // If no files are excluded, we can use the paths and let the dart
    // formatter expand the files.
    filesToFormat.files.addAll(paths);
  } else {
    // Convert paths to relative paths, so they can be efficiently
    // compared to the files we're listing.
    paths = paths.map(path.relative).toList();
    exclude = exclude.map(path.relative).toList();

    // Build the list of files by expanding the given paths, looking for
    // all .dart files that don't match any excluded path.
    for (var p in paths) {
      List<FileSystemEntity> files = FileSystemEntity.isFileSync(p)
          ? [File(p)]
          : Directory(p).listSync(recursive: true, followLinks: false);

      for (FileSystemEntity entity in files) {
        // Skip directories and links.
        if (entity is! File) continue;
        // Skip non-dart files.
        if (!entity.path.endsWith('.dart')) continue;

        var pathParts = path.split(entity.path);
        // Skip dependency files.
        if (pathParts.contains('packages')) continue;
        // Skip contents of .pub directories.
        if (pathParts.contains('.pub')) continue;
        // Skip contents of .dart_tool directories.
        if (pathParts.contains('.dart_tool')) continue;

        // Skip excluded files.
        bool isExcluded = exclude.any((excluded) =>
            entity.path == excluded || path.isWithin(excluded, entity.path));

        if (isExcluded) {
          filesToFormat.excluded.add(entity.path);
          continue;
        }

        // File should be formatted.
        filesToFormat.files.add(entity.path);
      }
    }
  }

  return filesToFormat;
}

/// Data around included/excluded files, returned [getFilesToFormat].
class FilesToFormat {
  /// Matching/included that should be formatted.
  List<String> files = [];

  /// Excluded files that should not be formatted.
  List<String> excluded = [];
}
