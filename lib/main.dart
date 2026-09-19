//! main.dart - 区块索引: [boot] [server] [host]
// ExamScheduleX 宿主：Windows 窗口内嵌 WebView，页面资源由本地 HTTP 服务从 Flutter 资产提供
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _kConfigName = 'schedule.json';
const String _kAssetPrefix = 'assets/web/';

void main() {
  runApp(const App());
}

// [boot]
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true, colorSchemeSeed: const Color(0xFF4AABEA)),
      home: const HostPage(),
    );
  }
}

// [host]
class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = _AssetServer().start();
  }

  /// exe 同目录 schedule.json 的内容，不存在返回 null
  String? _readFileConfig() {
    try {
      final file = _configFile();
      return file.existsSync() ? file.readAsStringSync() : null;
    } catch (_) {
      return null;
    }
  }

  static File _configFile() {
    final dir = File(Platform.resolvedExecutable).parent;
    return File('${dir.path}${Platform.pathSeparator}$_kConfigName');
  }

  bool _saveConfig(String json) {
    try {
      _configFile().writeAsStringSync(json, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: _urlFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('本地资源服务启动失败: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (InAppWebViewPlatform.instance == null) {
            return const Center(child: Text('WebView 运行时不可用'));
          }
          return InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(snap.data!)),
            initialSettings: InAppWebViewSettings(
              supportZoom: false,
              disableContextMenu: true,
            ),
            onWebViewCreated: (controller) {
              controller.addJavaScriptHandler(
                handlerName: 'saveConfig',
                callback: (args) => args.isNotEmpty && args.first is String
                    ? _saveConfig(args.first as String)
                    : false,
              );
            },
            onLoadStop: (controller, url) async {
              final fileJson = _readFileConfig();
              await controller.evaluateJavascript(
                source:
                    'window.__hostProvideFileConfig(${json.encode(fileJson)});',
              );
            },
          );
        },
      ),
    );
  }
}

// [server] 从 Flutter 资产内存中提供 assets/web/*，随机端口
class _AssetServer {
  final Map<String, String> _routes = {};
  HttpServer? _server;

  static const Map<String, String> _mime = {
    'html': 'text/html; charset=utf-8',
    'css': 'text/css; charset=utf-8',
    'js': 'text/javascript; charset=utf-8',
    'json': 'application/json; charset=utf-8',
    'woff2': 'font/woff2',
    'woff': 'font/woff',
    'ttf': 'font/ttf',
    'png': 'image/png',
    'svg': 'image/svg+xml',
    'ico': 'image/x-icon',
  };

  Future<String> start() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final key in manifest.listAssets()) {
      if (key.startsWith(_kAssetPrefix)) {
        _routes[key.substring(_kAssetPrefix.length)] = key;
      }
    }
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handle, onError: (Object _) {});
    return 'http://127.0.0.1:${_server!.port}/';
  }

  Future<void> _handle(HttpRequest req) async {
    final path = req.uri.path == '/' ? 'index.html' : req.uri.path.substring(1);
    final asset = _routes[path];
    try {
      if (asset == null) {
        req.response.statusCode = HttpStatus.notFound;
      } else {
        final data = await rootBundle.load(asset);
        final ext =
            path.contains('.') ? path.split('.').last.toLowerCase() : '';
        req.response.headers.contentType =
            ContentType.parse(_mime[ext] ?? 'application/octet-stream');
        req.response.add(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }
      await req.response.close();
    } catch (_) {
      // 客户端中断等网络错误：忽略，下一次请求继续
    }
  }
}
