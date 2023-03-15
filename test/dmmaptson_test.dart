import 'dart:io';
import 'dart:typed_data' as td;
import 'package:dmmaptson/dmmaptson.dart';
import 'package:dmmaptson/src/cstring_list.dart';
import 'package:test/test.dart';

void main() {
  Directory testDir = Directory("${Directory.current.path}/dmmaptson_test");
  Serializer serializer = Serializer();
  setUp(() {
    testDir.createSync(recursive: true);
  });

  test('empty_list', () async {
    var file = File("${testDir.path}/empty_list");
    // print(file.path);
    var value = [];
    var sink = file.openWrite();
    try {
      await serializer.encodeInSink(value, sink);
    } finally {
      await sink.flush();
      await sink.close();
    }
  });

  test('empty_map', () async {
    var file = File("${testDir.path}/empty_map");
    var value = {};
    var sink = file.openWrite();
    try {
      await serializer.encodeInSink(value, sink);
    } finally {
      await sink.flush();
      await sink.close();
    }
  });

  test('CStringList', () async {
    var file = File("${testDir.path}/CStringList");
    var value = CStringList.fromList(["hey"]);
    var sink = file.openWrite();
    try {
      await serializer.encodeInSink(value, sink);
    } finally {
      await sink.flush();
      await sink.close();
    }
  });

  test('list1', () async {
    var file = File("${testDir.path}/list1");
    var value = [
      "hey",
      true,
      42,
      42.0,
      {
        "key1": [42.0]
      },
      [
        {
          "key1": {"key2": 42.0}
        }
      ]
    ];
    var sink = file.openWrite();
    try {
      await serializer.encodeInSink(value, sink);
    } finally {
      await sink.flush();
      await sink.close();
    }
  });

  test('table', () async {
    var file = File("${testDir.path}/table");
    var value = {
      "nRows": 2,
      "columns": [
        {
          "name": "CStringList",
          "values": CStringList.fromList(["0", "42"])
        },
        {
          "name": "Uint8List",
          "values": td.Uint8List.fromList([0, 42])
        },
        {
          "name": "Uint16List",
          "values": td.Uint16List.fromList([0, 42])
        },
        {
          "name": "Uint32List",
          "values": td.Uint32List.fromList([0, 42])
        },
        {
          "name": "Uint64List",
          "values": td.Uint64List.fromList([0, 42])
        },
        {
          "name": "Int8List",
          "values": td.Int8List.fromList([0, -42])
        },
        {
          "name": "Int16List",
          "values": td.Int16List.fromList([0, -42])
        },
        {
          "name": "Int32List",
          "values": td.Int32List.fromList([0, -42])
        },
        {
          "name": "Int64List",
          "values": td.Int64List.fromList([0, -42])
        },
        {
          "name": "Float32List",
          "values": td.Float32List.fromList([0, -42])
        },
        {
          "name": "Int64List",
          "values": td.Float64List.fromList([0, -42])
        },
      ]
    };
    var sink = file.openWrite();
    try {
      await serializer.encodeInSink(value, sink);
    } finally {
      await sink.flush();
      await sink.close();
    }
  });
}
