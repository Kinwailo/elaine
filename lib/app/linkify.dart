import 'package:linkify/linkify.dart';

final _urlRegex = RegExp(
  r'''^(.*?)(https?:\/\/[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/=[\p{L}]*))''',
  caseSensitive: false,
  dotAll: true,
  unicode: true,
);

class UrlLinkifier extends Linkifier {
  const UrlLinkifier();

  @override
  List<LinkifyElement> parse(elements, options) {
    final list = <LinkifyElement>[];

    for (var element in elements) {
      final match = element is! TextElement
          ? null
          : _urlRegex.firstMatch(element.text);
      if (match == null) {
        list.add(element);
        continue;
      }

      final text = element.text.replaceFirst(match.group(0)!, '');

      if (match.group(1)?.isNotEmpty == true) {
        list.add(TextElement(match.group(1)!));
      }

      if (match.group(2)?.isNotEmpty == true) {
        var url = match.group(2)!;
        String? end;

        if (url[url.length - 1] == ".") {
          end = ".";
          url = url.substring(0, url.length - 1);
        }

        list.add(UrlElement(url, null, url));

        if (end != null) {
          list.add(TextElement(end));
        }
      }

      if (text.isNotEmpty) {
        list.addAll(parse([TextElement(text)], options));
      }
    }

    return list;
  }
}
