String strip(String s) {
  final matches = RegExp(r'(\s*)([^\s]*)(\s*)', unicode: true).allMatches(s);
  var result = '';
  for (var m in matches) {
    if (m.group(2) != null) {
      result += m.group(2)!;
    }
  }
  return result;
}

List<String> stripList(List<String> strings) => [
      for (final s in strings)
        if (strip(s).isNotEmpty) s
    ];

List<T> joinWith<T>(List<T> items, T value) => [
      for (int i = 0; i < items.length; i++)
        if (i != 0) ...[value, items[i]] else items[i]
    ];
