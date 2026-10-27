import 'csv_download_stub.dart' if (dart.library.js_interop) 'csv_download_web.dart' as impl;

/// Builds RFC 4180 CSV. Cells starting with = + - @ are prefixed with an
/// apostrophe so spreadsheet apps do not run them as formulas.
String toCsv(List<List<Object?>> rows) {
  String cell(Object? v) {
    var s = v?.toString() ?? '';
    if (s.isNotEmpty && '=+-@\t\r'.contains(s[0])) s = "'$s";
    if (s.contains(RegExp(r'[",\r\n]'))) s = '"${s.replaceAll('"', '""')}"';
    return s;
  }

  return rows.map((r) => r.map(cell).join(',')).join('\r\n');
}

/// Saves [csv] as a file in the browser. Returns false where downloads are
/// not supported (tests).
bool downloadCsv(String filename, String csv) => impl.downloadText(filename, csv, 'text/csv');
