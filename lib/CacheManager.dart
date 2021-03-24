import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'package:path_provider/path_provider.dart';
import 'CacheManagerWorker.dart';

class CacheManager {
  static int _initState;
  static Directory _directory;
  static SendPort _messager;
  static Map<String, List<Function(String)>> _delay = Map();
  static Map<String, List<Function(String)>> _looper = Map();

  static void init() async {
    if (_initState > 0) {
      return;
    }
    _initState = 1;
    _directory = await getExternalStorageDirectory();
    ReceivePort receivePort = ReceivePort();
    receivePort.listen(_onEvent);
    Isolate.spawn(CacheManagerWorker.init, receivePort.sendPort);
  }

  static void _onEvent(dynamic message) {
    switch (message["action"]) {
      case "init":
        _messager = message["port"];
        sendEnv(message);
        _initState = 2;
        break;
      case "done":
        done(message);
        break;
    }
  }

  static void done(message) {
    String path = message["path"];
    String url = message["url"];
    var callbacks = _looper[url];
    if (callbacks != null) {
      callbacks.forEach((element) {
        try {
          element(path);
        } catch (e) {
          print(e);
        }
      });
      _looper.clear();
      _looper.remove(url);
    }
  }

  static void doGet(String url, Function(String) callback) {
    if (_initState != 2) {
      addDoGetThread(url, callback, _delay);
      return;
    } else {
      addDoGetThread(url, callback, _looper);
    }
    execThread(url);
  }

  static void addDoGetThread(
      String url, callback(String), Map<String, List<Function(String)>> obj) {
    if (obj.containsKey(url)) {
      obj[url].add(callback);
    } else {
      List list = List();
      obj[url] = list;
      list.add(callback);
    }
  }

  static void sendEnv(message) {
    Map map = Map();
    map["action"] = "init";
    map["_directory"] = _directory;
    _messager.send(map);
    _delay.forEach((key, value) {
      if (_looper.containsKey(key)) {
        _looper[key].addAll(value);
      } else {
        _looper[key] = value;
      }
      execThread(key);
    });
    _delay.clear();
    _delay = null;
  }

  static void execThread(String url) {
    Map map = Map();
    map["action"] = "doGet";
    map["url"] = url;
    _messager.send(map);
  }

  static void release(String url, Function(String) callback) {
    clear(url, callback, _delay);
    clear(url, callback, _looper);
  }

  static void clear(
      String url, callback(String), Map<String, List<Function(String)>> obj) {
    if (obj != null) {
      if (obj.containsKey(url)) {
        var temp = obj[url];
        if (temp.contains(callback)) {
          temp.remove(callback);
          if (temp.isEmpty) {
            obj.remove(url);
          }
        }
      }
    }
  }
}
