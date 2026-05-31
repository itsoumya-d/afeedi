import 'dart:async';

void main() async {
  Future<List<int>> fetch(int val, bool fail) async {
    await Future.delayed(Duration(milliseconds: 100));
    if (fail) throw Exception('Fail');
    return [val];
  }

  var futures = [1, 2].map((v) {
    return fetch(v, v == 1).catchError((e) async {
      print('Caught $e');
      return <int>[];
    });
  }).toList();

  var res = await Future.wait(futures);
  print(res);
}
