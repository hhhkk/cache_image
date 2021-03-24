import 'dart:io';
import 'package:cache_image/CacheManager.dart';
import 'package:flutter/material.dart';

class CacheImageWidget extends StatefulWidget {
  String url;

  BoxFit fit;

  Widget placeholder;

  CacheImageWidget(this.url, this.fit, this.placeholder);

  @override
  State<StatefulWidget> createState() {
    return CacheImageWidgetState();
  }
}

class CacheImageWidgetState extends State<CacheImageWidget> {
  Function(String) callback;
  File _file;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    callback = (path) {
      _file = File(path);
      if (mounted) {
        setState(() {});
      }
    };
    CacheManager.doGet(widget.url, callback);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return _file == null
        ? widget.placeholder != null
            ? widget.placeholder
            : Center()
        : Image.file(
            _file,
            fit: widget.fit,
          );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    CacheManager.release(widget.url, callback);
    _file = null;
  }
}
