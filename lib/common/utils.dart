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

//Formatting rules
//Two modes: long and short
//Long is H+:MM:SS (Hour can be 1 or more digits)
//Short is M(M?):SS (Minute can be 1 or 2 digits)
//Use long when audio is more than short can display
String timestamp(Duration duration) {
  final seconds = duration.inSeconds % 60;
  final minutes = (duration.inSeconds / 60).round();
  final hours = (duration.inSeconds / (60 * 60)).round();

  String secondStr = seconds.toString().padLeft(2, '0');
  String minuteStr = minutes.toString();

  if (hours > 0) {
    return "$hours:${minuteStr.padLeft(2, '0')}:$secondStr";
  }
  return "$minuteStr:$secondStr";
}
