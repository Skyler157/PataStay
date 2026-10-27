import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool downloadText(String filename, String text, String mimeType) {
  // A byte-order mark lets Excel read the UTF-8 correctly.
  final bytes = utf8.encode('﻿$text');
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: '$mimeType;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return true;
}
