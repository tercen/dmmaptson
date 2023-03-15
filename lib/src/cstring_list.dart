import 'dart:collection';
import 'dart:typed_data' as td;
import 'dart:convert';

class CStringList extends ListBase<String> implements List<String>  {
  late td.Uint8List _bytes;
  late td.Uint64List _starts;

  CStringList.fromBytes(this._bytes);
  CStringList.fromList(List<String> list) {
    var lengthInBytes = list.fold(0, (dynamic len, str) {
      return len + utf8.encode(str).length + 1;
    });
    _bytes = td.Uint8List(lengthInBytes);
    _starts = td.Uint64List(list.length + 1);
    _starts[0] = 0;
    var offset = 0;
    var start = 1;
    for (var str in list) {
      var bytes = utf8.encode(str);
      _bytes.setRange(offset, offset + bytes.length, bytes);
      offset += bytes.length + 1;
      _starts[start] = offset;
      start++;
    }
  }

  td.Uint8List toBytes() => _bytes;
  int get lengthInBytes => _bytes.length;

  td.Uint64List get starts => _starts;

  int get length => starts.length - 1;

  set length(int newLength) => throw "list is read only";

  operator [](int i) {
    var start = starts[i];
    var end = starts[i + 1];
    return utf8.decode(_bytes.sublist(start, end - 1));
  }

  operator []=(int i, String value) => throw "list is read only";
}
