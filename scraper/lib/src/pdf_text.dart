import 'dart:convert';
import 'dart:io';

/// Turns a PDF into plain text.
typedef PdfToText = Future<String> Function(List<int> pdf);

class PdfTextException implements Exception {
  const PdfTextException(this.message);

  final String message;

  @override
  String toString() => 'PdfTextException: $message';
}

/// Converts [pdf] to text with `pdftotext` (from poppler or xpdf), which
/// must be on the PATH. `-layout` keeps each printed line on its own line.
Future<String> runPdfToText(List<int> pdf) async {
  final directory = await Directory.systemTemp.createTemp('lunch_pdf');
  try {
    final file = File('${directory.path}/menu.pdf');
    await file.writeAsBytes(pdf);
    final result = await Process.run(
      'pdftotext',
      ['-layout', '-enc', 'UTF-8', file.path, '-'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw PdfTextException(
        'pdftotext exited with ${result.exitCode}: ${result.stderr}',
      );
    }
    return result.stdout as String;
  } finally {
    await directory.delete(recursive: true);
  }
}
