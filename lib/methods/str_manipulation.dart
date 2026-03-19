import 'package:market_invoices_app/methods/database.dart';

bool isNumeric(String? s) {
  if(s == null) {
    return false;
  }
  return double.tryParse(s) != null;
}

String cleanLine(String s) {
  String result = s;
  if (s.lastIndexOf(',') == s.length - 1) {
    result = s.substring(0, s.length - 1);
  }
  return result.trim();
}

List<String> removeEmpty(List<String> source) {
  final List<String> list = [];
  var iterator = source.iterator;
  while (iterator.moveNext()) {
    if (iterator.current.isEmpty || iterator.current.contains(' ')) continue;
    list.add(iterator.current);
  }
  return list;
}

List<String> checkEmpty(List<String> source) {
  var iterator = source.iterator;
  while (iterator.moveNext()) {
    if (iterator.current.isEmpty || iterator.current.contains(' ')) return removeEmpty(source);
  }
  return source;
}

int? getNumeric(List<String> s) {
  int? last;
  int idx = 0;
  for (final String word in s) {
    if (word.isEmpty) {
      return getNumeric(removeEmpty(s));
    }
    String first = word.split('')[0];
    if (isNumeric(first)) {
      last = idx;
    }
    idx ++;
  }
  return last;
}


(String, double) retriveInfo(List<String> words) {
  final List<String> noSpace = checkEmpty(words);
  final int? idx = getNumeric(noSpace);
  if (idx == null) return (noSpace.join(" "), 0);
  final String name = noSpace.sublist(0, idx).join(" ");
  final double price = double.parse(noSpace[idx].replaceAll(RegExp(r','), '.'));
  return (name, price);
}

String cutStr(String str, {int maxSize = 21}) {
  if (str.length <= maxSize) {
    return str;
  }
  else {
    return str.substring(0, 21);
  }
}



List<Item>? textToList(String text, int tableId) {
  if (text == '') return null;
  List<Item>? result = [];
  List<String> lines = text.split('\n');
  for (String line in lines) {
    line = cleanLine(line);
    final (String name, double price) = retriveInfo(line.split(' '));
    result.add(
      Item(
        name: cutStr(name).capitalize(), 
        price: price, 
        tableId: tableId
      )
    );
  }
  return result;
}

List<Item> speechToList(List items, int tableId) {
  List<Item> result = [];
  for (int i = 0; i < items.length; i++) {
    var item = items[i];
    result.add(Item(name: cutStr(item['nome']).capitalize(), price: double.parse("${item['preço']}"), tableId: tableId, quantity: double.parse("${item['quantidade']}"), type: item["formato"]));
  }
  return result;
}

extension StringExtensions on String { 
  String capitalize() { 
    return "${this[0].toUpperCase()}${substring(1)}"; 
  } 
}