// stubs/html.dart

class ConnectionInfo {
  String get effectiveType => '4g';
}

class Navigator {
  String get userAgent => 'Mobile';
  ConnectionInfo get connection => ConnectionInfo();
}

class Window {
  Navigator get navigator => Navigator();
  Location get location => Location();
}

class Location {
    String get origin => "localhost";
}

final Window window = Window();

class VideoElement {
  String canPlayType(String type) => '';
  Future<void> play() async {}
  void pause() {}
  set currentTime(num? value) {}
  num? get currentTime => 0;
  set src(String? value) {}
  String? get src => '';
  set controls(bool? value) {}
  bool? get controls => false;
  set autoplay(bool? value) {}
  bool? get autoplay => false;
  Stream<void> get onLoadedMetadata => Stream.empty();
  num? get duration => 0;
  Stream<void> get onTimeUpdate => Stream.empty();
}

class CanvasElement {
  dynamic getContext(String context) => null;
}

class IFrameElement {
    set src(String? value) {}
    String? get src => '';
    set srcdoc(String? value) {}
    String? get srcdoc => '';
    final style = IFrameElementStyle();
    set allowFullscreen(bool? value) {}
    bool? get allowFullscreen => false;
    void setAttribute(String name, String value) {}
}

class IFrameElementStyle {
    set border(String? value) {}
    String? get border => '';
    set height(String? value) {}
    String? get height => '';
    set width(String? value) {}
    String? get width => '';
}

class Document {
    Element? getElementById(String id) => null;
    HeadElement? get head => HeadElement();
}

class HeadElement extends Element {
    void append(Element element) {}
}

class Element {
    List<Element> get children => [];
}

final Document document = Document();