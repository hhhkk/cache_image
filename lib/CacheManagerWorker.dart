import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class CacheManagerWorker {
  static SendPort _messager;
  static Directory _directory;
  static String _path;

  static void init(SendPort sendPort) {
    _messager = sendPort;
    ReceivePort receivePort = ReceivePort();
    receivePort.listen(_onEvent);
    Map data = Map();
    data["action"] = "init";
    sendPort.send(data);
  }

  static void _onEvent(message) {
    switch (message["action"]) {
      case "init":
        _directory = message["directory"];
        _path = _directory.path;
        checkDir();
        break;
      case "doGet":
        _doGet(message["url"]);
        break;
    }
  }

  static List<String> looper = List();

  static void _doGet(String url) {
    var md5Value = generate_MD5(url);
    var cachePath = _path + "/" + md5Value + ".jpg";
    File temp = File(cachePath);
    if (temp.existsSync()) {
      notify(cachePath, url);
      return;
    }
    if (!looper.contains(url)) {
      worker(url, cachePath);
    }
  }

  static void worker(String url, String cachePath) async {
    Dio().download(url, cachePath, deleteOnError: true).whenComplete(() {
      notify(cachePath, url);
    });
  }

  static void notify(String cachePath, String url) {
    Map map = Map();
    map["path"] = cachePath;
    map["url"] = url;
    map["action"] = "done";
    _messager.send(map);
  }

  // md5 加密
  static String generate_MD5(String data) {
    var content = new Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  static void checkDir() {
    Directory file = Directory(_path + "/img");
    var exists = file.existsSync();
    if (!exists) {
      file.createSync();
    }
  }
}
