extension StringUtils on String {
  String get sender => _extractSender(this);
  String get email => _extractEmail(this);
  String get urlFilename => _getUrlFilename(this);
  String get decodeUrl => _decodeUrl(this);
  String get noLinebreak => _noLinebreak(this);
  String get stripQuote => _stripQuote(this);
  String get stripMultiEmptyLine => _stripMultiEmptyLine(this);
  String get stripHtmlTag => _stripHtmlTag(this);

  String get stripAll => _stripAll(this);

  bool get isImageFile => _isImageFile(this);

  String _stripAll(String text) {
    text = text.replaceAll('\u200b', '');
    text = text.stripSameContent('');
    text = text.stripSignature([
      r'^-- ?$',
      r'^----Android NewsGroup Reader----$',
    ]);
    text = text.stripQuote;
    text = text.stripMultiEmptyLine;
    text = text.stripCustomPattern([]);
    text = text.trim();
    return text;
  }

  String _extractSender(String from) {
    var re = RegExp(r'^(.*)(?:[_ ])<(.*)>$');
    var match = re.firstMatch(from);
    var sender = match?.group(1) ?? from;
    re = RegExp('"([^"]*(?:.[^"]*)*)"');
    match = re.firstMatch(sender);
    sender = match?.group(1) ?? sender;
    return sender;
  }

  String _extractEmail(String from) {
    var re = RegExp(r'^(.*)(?:[_ ])<(.*)>$');
    var match = re.firstMatch(from);
    return match?.group(2) ?? from;
  }

  String _getUrlFilename(String text) {
    var regex = RegExp(r'(?<=\/)[^\/\?#]+(?=[^\/]*$)');
    var filename = regex.firstMatch(text)?[0] ?? 'image.jpg';
    if (!filename.contains('.')) {
      var filename2 = text.substring(0, text.lastIndexOf('/'));
      filename2 = regex.firstMatch(filename2)?[0] ?? 'image.jpg';
      if (filename2.contains('.')) filename = filename2;
    }
    return filename;
  }

  String _decodeUrl(String text) {
    try {
      return Uri.decodeComponent(text);
    } catch (e) {
      return text;
    }
  }

  bool _isImageFile(String filename) {
    return filename.contains('.') &&
        [
          'webp',
          'png',
          'jpg',
          'jpeg',
          'jfif',
          'gif',
          'bmp',
        ].contains(filename.split('.').last.toLowerCase());
  }

  String _noLinebreak(String text) {
    var re = RegExp(r'(\n\s?){3}');
    text = text.trim();
    while (text.contains(re)) {
      text = text.replaceAll(re, '\n\n');
    }
    text = text.replaceAll('\n\n', '⤶ ');
    text = text.replaceAll('\n', '⤶ ');
    return text;
  }

  String stripSameContent(String text) {
    var esc = RegExp.escape(text);
    var re = RegExp('^$esc\$', multiLine: true);
    return replaceAll(re, '');
  }

  String stripSignature(List<String> patterns) {
    String text = this;
    for (var re in patterns) {
      int start = 0;
      int? end = 0;
      re = '^.*$re';
      do {
        start = text.indexOf(RegExp(re, multiLine: true));
        if (start != -1) {
          end = text.indexOf(RegExp(r'\n\s?\n'), start);
          end = end == -1 ? null : end + 1;
          text = text.replaceRange(start, end, '');
        }
      } while (start != -1);
    }
    return text;
  }

  String _stripQuote(String text) {
    int start = 0;
    int end = 0;
    do {
      start = text.indexOf(RegExp(r'^>.*$', multiLine: true));
      if (start != -1) {
        end = text.indexOf(
          RegExp(r'\n([^>].*|\s?)$', multiLine: true),
          start + 1,
        );
        if (start > 0) {
          int br = text.lastIndexOf(
            RegExp(r'$(\r\n|\r|\n)', multiLine: true),
            start - 1,
          );
          start = br == -1 ? start : br;
          start = text.lastIndexOf(RegExp(r'^.*?', multiLine: true), start - 1);
        }
        if (end == -1) {
          text = text.substring(0, start);
        } else {
          text = text.replaceRange(start, end, '');
        }
      }
    } while (start != -1);
    return text;
  }

  String _stripMultiEmptyLine(String text) {
    var re = RegExp(r'(\n\s?){3}');
    while (text.contains(re)) {
      text = text.replaceAll(re, '\n\n');
    }
    return text;
  }

  String stripCustomPattern(List<String> patterns) {
    String text = this;
    for (var re in patterns) {
      int start = 0;
      int? end = 0;
      re = '^.*$re';
      do {
        start = text.indexOf(RegExp(re, multiLine: true));
        if (start != -1) {
          end = text.indexOf(RegExp(r'\n'), start);
          end = end == -1 ? null : end + 1;
          text = text.replaceRange(start, end, '');
        }
      } while (start != -1);
    }
    return text;
  }

  String _stripHtmlTag(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
  }
}
