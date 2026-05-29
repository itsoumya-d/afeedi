// stubs/js.dart

class JsObject {
  bool hasProperty(String property) => false;

  dynamic callMethod(String method, [List<dynamic>? args]) => null;

  dynamic operator [](String property) => null;
  void operator []=(String property, dynamic value) {}
}

final JsObject context = JsObject();
