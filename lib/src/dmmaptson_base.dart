import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' as td;
import 'dart:typed_data';
import 'spec.dart';
import './cstring_list.dart';

int padForPointer(int len) {
  var pad = 8 - len % 8;

  if (pad < 8) {
    return pad;
  } else {
    return 0;
  }
}

abstract class Writer {
  void addSlice(List<int> value);
  void addU8(int value);
  void addI8(int value);
  void addU32(int value);
  void addI32(int value);
  void addU16(int value);
  void addI16(int value);
  void addU64(int value);
  void addI64(int value);
  void addF32(double value);
  void addF64(double value);
  void addPadForPointer() {
    var pad = 8 - position() % 8;
    if (pad < 8) {
      for (var i = 0; i < pad; i++) {
        addU8(0);
      }
    }
  }

  int position();
}

class CountWriter extends Writer {
  int size = 0;

  @override
  void addF32(double value) {
    size += 4;
  }

  @override
  void addF64(double value) {
    size += 8;
  }

  @override
  void addI16(int value) {
    size += 2;
  }

  @override
  void addI32(int value) {
    size += 4;
  }

  @override
  void addI64(int value) {
    size += 8;
  }

  @override
  void addI8(int value) {
    size += 1;
  }

  @override
  void addSlice(List<int> value) {
    size += value.length;
  }

  @override
  void addU16(int value) {
    size += 2;
  }

  @override
  void addU32(int value) {
    size += 4;
  }

  @override
  void addU64(int value) {
    size += 8;
  }

  @override
  void addU8(int value) {
    size += 1;
  }

  @override
  int position() => size;
}

class SinkWriterAdapter extends Writer {
  final ByteData _byteData = ByteData(8);
  final CountWriter _countWriter = CountWriter();
  final StreamSink<List<int>> _sink;

  SinkWriterAdapter(this._sink);

  @override
  void addF32(double value) {
    _countWriter.addF32(value);
    _byteData.setFloat32(0, value, Endian.little);
    _sink.add(Uint8List.fromList(_byteData.buffer.asUint8List(0, 4)));
  }

  @override
  void addF64(double value) {
    _countWriter.addF64(value);
    _byteData.setFloat64(0, value, Endian.little);
    _sink.add(Uint8List.fromList(_byteData.buffer.asUint8List(0, 8)));
  }

  @override
  void addI16(int value) {
    _countWriter.addI16(value);
    _byteData.setInt16(0, value, Endian.little);
    _sink.add(Uint8List.fromList(_byteData.buffer.asUint8List(0, 2)));
  }

  @override
  void addI32(int value) {
    _countWriter.addI32(value);
    _byteData.setInt32(0, value, Endian.little);
    _sink.add(Uint8List.fromList(_byteData.buffer.asUint8List(0, 4)));
  }

  @override
  void addI64(int value) {
    _countWriter.addI64(value);
    _byteData.setInt64(0, value, Endian.little);
    _sink.add(Uint8List.fromList(_byteData.buffer.asUint8List(0, 8)));
  }

  @override
  void addI8(int value) {
    _countWriter.addI8(value);
    _byteData.setInt8(0, value);
    _sink.add(Uint8List.fromList(_byteData.buffer.asUint8List(0, 1)));
  }

  @override
  void addSlice(List<int> value) {
    _countWriter.addSlice(value);
    _sink.add(value);
  }

  @override
  void addU16(int value) {
    _countWriter.addU16(value);
    _byteData.setUint16(0, value, Endian.little);
    _sink.add(Uint8List.fromList(_byteData.buffer.asUint8List(0, 2)));
  }

  @override
  void addU32(int value) {
    _countWriter.addU32(value);
    _byteData.setUint32(0, value, Endian.little);
    _sink.add(Uint8List.fromList(_byteData.buffer.asUint8List(0, 4)));
  }

  @override
  void addU64(int value) {
    _countWriter.addU64(value);
    _byteData.setUint64(0, value, Endian.little);
    _sink.add(Uint8List.fromList(_byteData.buffer.asUint8List(0, 8)));
  }

  @override
  void addU8(int value) {
    _countWriter.addU8(value);
    _sink.add([value]);
  }

  @override
  int position() => _countWriter.position();
}

class _Offset {
  int offset = 0;

  void padForPointer() {
    var pad = 8 - offset % 8;
    if (pad < 8) {
      offset += pad;
    }
  }
}

class Serializer {
  List<int> encodeSize(dynamic value) {
    var writer = CountWriter();
    _addString(writer, VERSION);
    var paddedOffset = _Offset();
    _addObject(value, writer, paddedOffset);
    var headerSize = writer.size + padForPointer(writer.size);
    writer = CountWriter();
    _addData(value, writer);
    var dataSize = writer.size;
    return [headerSize, headerSize + dataSize];
  }

  Future encodeInSink(dynamic value, StreamSink<List<int>> ioSink) async {
    var writer = SinkWriterAdapter(ioSink);
    encodeIn(value, writer);
  }

  // Future encodeInFile(dynamic value, String path) async {
  //   var file = File(path);
  //   var ioSink = file.openWrite();
  //   var writer = SinkWriterAdapter(ioSink);
  //
  //   try {
  //     encodeIn(value, writer);
  //   } finally {
  //     await ioSink.flush();
  //     await ioSink.close();
  //   }
  // }

  void encodeIn(dynamic value, Writer writer) {
    var size = encodeSize(value);
    _addString(writer, VERSION);

    var paddedOffset = _Offset()..offset = size[0];
    _addObject(value, writer, paddedOffset);

    var pad = padForPointer(writer.position());
    for (var i = 0; i < pad; i++) {
      writer.addU8(0);
    }
    assert(writer.position() == size[0]);
    _addData(value, writer);

    assert(writer.position() == size[1]);
    assert(paddedOffset.offset == size[1]);
  }

  void _addData(dynamic value, Writer writer) {
    if (value == null) {
    } else if (value is String) {
    } else if (value is int) {
    } else if (value is double) {
    } else if (value is bool) {
    } else if (value is td.TypedData) {
      writer.addPadForPointer();
      writer.addSlice(value.buffer.asUint8List());
    } else if (value is CStringList) {
      _addData(value.toBytes(), writer);
      _addData(value.starts, writer);
    } else if (value is List) {
      for (var o in value) {
        _addData(o, writer);
      }
    } else if (value is Map) {
      for (var v in value.values) {
        _addData(v, writer);
      }
    } else {
      throw 'bad type';
    }
  }

  void _addObject(dynamic value, Writer writer, _Offset offset) {
    if (value == null) {
      writer.addU8(NULL_TYPE);
    } else if (value is String) {
      _addString(writer, value);
    } else if (value is int) {
      writer.addU8(INTEGER_TYPE);
      writer.addI32(value);
    } else if (value is double) {
      writer.addU8(DOUBLE_TYPE);
      writer.addF64(value);
    } else if (value is bool) {
      writer.addU8(BOOL_TYPE);
      if (value) {
        writer.addU8(1);
      } else {
        writer.addU8(0);
      }
    } else if (value is td.TypedData) {
      int len = 0;
      if (value is td.Uint8List) {
        writer.addU8(LIST_UINT8_TYPE);
        len = value.length;
      } else if (value is td.Uint16List) {
        writer.addU8(LIST_UINT16_TYPE);
        len = value.length;
      } else if (value is td.Uint32List) {
        writer.addU8(LIST_UINT32_TYPE);
        len = value.length;
      } else if (value is td.Int8List) {
        writer.addU8(LIST_INT8_TYPE);
        len = value.length;
      } else if (value is td.Int16List) {
        writer.addU8(LIST_INT16_TYPE);
        len = value.length;
      } else if (value is td.Int32List) {
        writer.addU8(LIST_INT32_TYPE);
        len = value.length;
      } else if (value is td.Int64List) {
        writer.addU8(LIST_INT64_TYPE);
        len = value.length;
      } else if (value is td.Uint64List) {
        writer.addU8(LIST_UINT64_TYPE);
        len = value.length;
      } else if (value is td.Float32List) {
        writer.addU8(LIST_FLOAT32_TYPE);
        len = value.length;
      } else if (value is td.Float64List) {
        writer.addU8(LIST_FLOAT64_TYPE);
        len = value.length;
      } else {
        throw 'bad type';
      }

      offset.padForPointer();
      _addLen(writer, offset.offset);
      _addLen(writer, len);
      offset.offset += value.lengthInBytes;
    } else if (value is CStringList) {
      writer.addU8(LIST_STRING_TYPE);
      _addObject(value.toBytes(), writer, offset);
      _addObject(value.starts, writer, offset);
    } else if (value is List) {
      writer.addU8(LIST_TYPE);
      _addLen(writer, value.length);
      for (var o in value) {
        _addObject(o, writer, offset);
      }
    } else if (value is Map) {
      writer.addU8(MAP_TYPE);
      _addLen(writer, value.length);
      for (var o in value.entries) {
        _addString(writer, o.key as String);
        _addObject(o.value, writer, offset);
      }
    } else {
      throw 'bad type';
    }
  }

  void _addLen(Writer writer, int value) {
    writer.addU64(value);
  }

  void _addString(Writer writer, String value) {
    writer.addU8(STRING_TYPE);
    _addCString(writer, value);
  }

  void _addCString(Writer writer, String value) {
    writer
      ..addSlice(utf8.encode(value))
      ..addU8(0);
  }
}
