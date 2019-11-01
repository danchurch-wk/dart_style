// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:irdartfmt/src/dart_formatter.dart';
import 'package:irdartfmt/src/exceptions.dart';
import 'package:irdartfmt/src/formatter_options.dart';
import 'package:irdartfmt/src/io.dart';
import 'package:irdartfmt/src/source_code.dart';
import 'package:irdartfmt/src/style_fix.dart';

// Note: The following line of code is modified by tool/grind.dart.
const version = "1.3.1";

void main(List<String> args) {
  var parser = ArgParser(allowTrailingOptions: true);

  parser.addSeparator("Common options:");
  parser.addFlag("help",
      abbr: "h", negatable: false, help: "Shows usage information.");
  parser.addFlag("version",
      negatable: false, help: "Shows version information.");
  parser.addOption("line-length",
      abbr: "l", help: "Wrap lines longer than this.", defaultsTo: "80");
  parser.addFlag("overwrite",
      abbr: "w",
      negatable: false,
      help: "Overwrite input files with formatted output.");
  parser.addFlag("dry-run",
      abbr: "n",
      negatable: false,
      help: "Show which files would be modified but make no changes.");

  parser.addSeparator("Non-whitespace fixes (off by default):");
  parser.addFlag("fix", negatable: false, help: "Apply all style fixes.");

  for (var fix in StyleFix.all) {
    // TODO(rnystrom): Allow negating this if used in concert with "--fix"?
    parser.addFlag("fix-${fix.name}", negatable: false, help: fix.description);
  }

  parser.addSeparator("Other options:");
  parser.addOption("indent",
      abbr: "i", help: "Spaces of leading indentation.", defaultsTo: "0");
  parser.addFlag("machine",
      abbr: "m",
      negatable: false,
      help: "Produce machine-readable JSON output.");
  parser.addFlag("set-exit-if-changed",
      negatable: false,
      help: "Return exit code 1 if there are any formatting changes.");
  parser.addFlag("follow-links",
      negatable: false,
      help: "Follow links to files and directories.\n"
          "If unset, links will be ignored.");
  parser.addOption("preserve",
      help: 'Selection to preserve, formatted as "start:length".');
  parser.addOption("stdin-name",
      help: "The path name to show when an error occurs in source read from "
          "stdin.",
      defaultsTo: "<stdin>");
  parser.addOption("package-name",
      help:
          "The name of the package. Used to be able to sort imports with a package section."
          "The sort fix will not consider packages if not supplied.",
      defaultsTo: null);

  parser.addFlag("profile", negatable: false, hide: true);
  parser.addFlag("transform", abbr: "t", negatable: false, hide: true);

  ArgResults argResults;
  try {
    argResults = parser.parse(args);
  } on FormatException catch (err) {
    usageError(parser, err.message);
  }

  if (argResults["help"]) {
    printUsage(parser);
    return;
  }

  if (argResults["version"]) {
    print(version);
    return;
  }

  // Can only preserve a selection when parsing from stdin.
  List<int> selection;
  if (argResults["preserve"] != null && argResults.rest.isNotEmpty) {
    usageError(parser, "Can only use --preserve when reading from stdin.");
  }

  try {
    selection = parseSelection(argResults["preserve"]);
  } on FormatException catch (_) {
    usageError(
        parser,
        '--preserve must be a colon-separated pair of integers, was '
        '"${argResults['preserve']}".');
  }

  if (argResults["dry-run"] && argResults["overwrite"]) {
    usageError(
        parser, "Cannot use --dry-run and --overwrite at the same time.");
  }

  checkForReporterCollision(String chosen, String other) {
    if (!argResults[other]) return;

    usageError(parser, "Cannot use --$chosen and --$other at the same time.");
  }

  var reporter = OutputReporter.print;
  if (argResults["dry-run"]) {
    checkForReporterCollision("dry-run", "overwrite");
    checkForReporterCollision("dry-run", "machine");

    reporter = OutputReporter.dryRun;
  } else if (argResults["overwrite"]) {
    checkForReporterCollision("overwrite", "machine");

    if (argResults.rest.isEmpty) {
      usageError(parser,
          "Cannot use --overwrite without providing any paths to format.");
    }

    reporter = OutputReporter.overwrite;
  } else if (argResults["machine"]) {
    reporter = OutputReporter.printJson;
  }

  if (argResults["profile"]) {
    reporter = ProfileReporter(reporter);
  }

  if (argResults["set-exit-if-changed"]) {
    reporter = SetExitReporter(reporter);
  }

  int pageWidth;
  try {
    pageWidth = int.parse(argResults["line-length"]);
  } on FormatException catch (_) {
    usageError(
        parser,
        '--line-length must be an integer, was '
        '"${argResults['line-length']}".');
  }

  int indent;
  try {
    indent = int.parse(argResults["indent"]);
    if (indent < 0 || indent.toInt() != indent) throw FormatException();
  } on FormatException catch (_) {
    usageError(
        parser,
        '--indent must be a non-negative integer, was '
        '"${argResults['indent']}".');
  }

  var followLinks = argResults["follow-links"];

  var fixes = <StyleFix>[];
  if (argResults["fix"]) fixes.addAll(StyleFix.all);
  for (var fix in StyleFix.all) {
    if (argResults["fix-${fix.name}"]) {
      if (argResults["fix"]) {
        usageError(parser, "--fix-${fix.name} is redundant with --fix.");
      }

      fixes.add(fix);
    }
  }

  if (argResults.wasParsed("stdin-name") && argResults.rest.isNotEmpty) {
    usageError(parser, "Cannot pass --stdin-name when not reading from stdin.");
  }

  String packageName = '';
  try {
    packageName = argResults["package-name"];
  } catch (e) {
    // do nothing
  }

  var options = FormatterOptions(reporter,
      indent: indent,
      pageWidth: pageWidth,
      followLinks: followLinks,
      fixes: fixes,
      packageName: packageName);

  if (argResults.rest.isEmpty) {
    formatStdin(options, selection, argResults["stdin-name"] as String);
  } else {
    formatPaths(options, argResults.rest);
  }

  if (argResults["profile"]) {
    (reporter as ProfileReporter).showProfile();
  }
}

List<int> parseSelection(String selection) {
  if (selection == null) return null;

  var coordinates = selection.split(":");
  if (coordinates.length != 2) {
    throw FormatException(
        'Selection should be a colon-separated pair of integers, "123:45".');
  }

  return coordinates.map((coord) => coord.trim()).map(int.parse).toList();
}

/// Reads input from stdin until it's closed, and the formats it.
void formatStdin(FormatterOptions options, List<int> selection, String name) {
  var selectionStart = 0;
  var selectionLength = 0;

  if (selection != null) {
    selectionStart = selection[0];
    selectionLength = selection[1];
  }

  var input = StringBuffer();
  stdin.transform(Utf8Decoder()).listen(input.write, onDone: () {
    var formatter = DartFormatter(
        indent: options.indent,
        pageWidth: options.pageWidth,
        fixes: options.fixes,
        packageName: options.packageName);
    try {
      options.reporter.beforeFile(null, name);
      var source = SourceCode(input.toString(),
          uri: name,
          selectionStart: selectionStart,
          selectionLength: selectionLength);
      var output = formatter.formatSource(source);
      options.reporter
          .afterFile(null, name, output, changed: source.text != output.text);
      return;
    } on FormatterException catch (err) {
      stderr.writeln(err.message());
      exitCode = 65; // sysexits.h: EX_DATAERR
    } catch (err, stack) {
      stderr.writeln('''Hit a bug in the formatter when formatting stdin.
Please report at: github.com/dart-lang/irdartfmt/issues
$err
$stack''');
      exitCode = 70; // sysexits.h: EX_SOFTWARE
    }
  });
}

/// Formats all of the files and directories given by [paths].
void formatPaths(FormatterOptions options, List<String> paths) {
  for (var path in paths) {
    var directory = Directory(path);
    if (directory.existsSync()) {
      if (!processDirectory(options, directory)) {
        exitCode = 65;
      }
      continue;
    }

    var file = File(path);
    if (file.existsSync()) {
      if (!processFile(options, file)) {
        exitCode = 65;
      }
    } else {
      stderr.writeln('No file or directory found at "$path".');
    }
  }
}

/// Prints [error] and usage help then exits with exit code 64.
void usageError(ArgParser parser, String error) {
  printUsage(parser, error);
  exit(64);
}

void printUsage(ArgParser parser, [String error]) {
  var output = stdout;

  var message = "Idiomatically formats Dart source code.";
  if (error != null) {
    message = error;
    output = stdout;
  }

  output.write("""$message

Usage:   dartfmt [options...] [files or directories...]

Example: dartfmt -w .
         Reformats every Dart file in the current directory tree.

${parser.usage}
""");
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
