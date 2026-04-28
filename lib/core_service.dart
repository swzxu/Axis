import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class SubscriptionUpdateResult {
  final bool success;
  final String? subscriptionName;
  final int serverCount;

  const SubscriptionUpdateResult({
    required this.success,
    this.subscriptionName,
    this.serverCount = 0,
  });
}

class ServerEntry {
  final String name;
  final String link;
  final bool isCustom;
  final String? countryCode;
  final String source;
  final String? subscriptionId;

  const ServerEntry({
    required this.name,
    required this.link,
    required this.isCustom,
    this.countryCode,
    this.source = 'subscription',
    this.subscriptionId,
  });
}

class SubscriptionGroup {
  final String id;
  final String name;
  final String url;
  final List<ServerEntry> servers;

  const SubscriptionGroup({
    required this.id,
    required this.name,
    required this.url,
    required this.servers,
  });
}

class CoreSettings {
  final bool tunEnabled;
  final bool customDnsEnabled;
  final String dnsPrimary;
  final String dnsSecondary;

  const CoreSettings({
    this.tunEnabled = false,
    this.customDnsEnabled = false,
    this.dnsPrimary = '1.1.1.1',
    this.dnsSecondary = '8.8.8.8',
  });
}

class CoreService {
  String currentMode = "РЎРёСЃС‚РµРјРЅС‹Р№ РїСЂРѕРєСЃРё";
  List<Map<String, String>> _serversData = []; 
  List<Map<String, dynamic>> _subscriptions = [];
  String? _selectedServerName;
  String? _selectedServerLink;
  Process? _mihomoProcess;
  CoreSettings settings = const CoreSettings();

  String? get selectedServerName => _selectedServerName;

  Future<String> get _axisPath async {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? "";
    final path = p.join(localAppData, 'Axis');
    final dir = Directory(path);
    if (!await dir.exists()) await dir.create(recursive: true);
    return path;
  }

  Future<File> get _subFile async {
    final path = await _axisPath;
    return File(p.join(path, 'sub_servers.txt'));
  }

  Future<File> get _customServersFile async {
    final path = await _axisPath;
    return File(p.join(path, 'custom_servers.json'));
  }

  Future<File> get _subscriptionsFile async {
    final path = await _axisPath;
    return File(p.join(path, 'subscriptions.json'));
  }

  void applySettings(CoreSettings next) {
    settings = next;
  }


  Future<bool> initAndStart() async {
    debugPrint("Р—Р°РїСѓСЃРє СЏРґСЂР° Mihomo...");
    if (_selectedServerLink == null) {
      final servers = await getServers();
      if (servers.isNotEmpty) {
        await selectServer(servers.first);
      }
    }
    final generated = await _generateMihomoConfig();
    if (!generated) {
      debugPrint("РќРµ СѓРґР°Р»РѕСЃСЊ СЃРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РєРѕРЅС„РёРі РёР· РІС‹Р±СЂР°РЅРЅРѕРіРѕ СЃРµСЂРІРµСЂР°");
      return false;
    }
    await _startMihomoProcess();
    if (currentMode == "РЎРёСЃС‚РµРјРЅС‹Р№ РїСЂРѕРєСЃРё") {
      await _setWindowsSystemProxy(enabled: true);
    }
    return true;
  }

  Future<void> stop() async {
    debugPrint("РћСЃС‚Р°РЅРѕРІРєР° РІСЃРµС… РїСЂРѕС†РµСЃСЃРѕРІ СЏРґСЂР°");
    await _killMihomoProcesses();
    if (currentMode == "РЎРёСЃС‚РµРјРЅС‹Р№ РїСЂРѕРєСЃРё") {
      await _setWindowsSystemProxy(enabled: false);
    }
  }

  Future<void> _startMihomoProcess() async {
    final axisPath = await _axisPath;
    final configPath = p.join(axisPath, 'config.yaml');
    final mihomoPath = await _resolveMihomoBinaryPath(axisPath);
    if (mihomoPath == null) {
      debugPrint("mihomo.exe РЅРµ РЅР°Р№РґРµРЅ, РїСЂРѕРїСѓСЃРєР°РµРј Р·Р°РїСѓСЃРє СЏРґСЂР°");
      return;
    }

    await _killMihomoProcesses();
    _mihomoProcess = await Process.start(
      mihomoPath,
      ['-f', configPath],
      runInShell: true,
    );

    _mihomoProcess?.stdout.transform(utf8.decoder).listen((data) {
      debugPrint("[mihomo] $data");
    });
    _mihomoProcess?.stderr.transform(utf8.decoder).listen((data) {
      debugPrint("[mihomo:err] $data");
    });
  }

  Future<void> _killMihomoProcesses() async {
    try {
      _mihomoProcess?.kill(ProcessSignal.sigterm);
    } catch (_) {}
    _mihomoProcess = null;

    try {
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/IM', 'mihomo.exe', '/F']);
      } else if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('pkill', ['-f', 'mihomo']);
      }
    } catch (e) {
      debugPrint("Р—Р°С‡РёСЃС‚РєР° mihomo Р·Р°РІРµСЂС€РёР»Р°СЃСЊ СЃ РїСЂРµРґСѓРїСЂРµР¶РґРµРЅРёРµРј: $e");
    }
  }

  Future<String?> _resolveMihomoBinaryPath(String axisPath) async {
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      p.join(axisPath, 'mihomo.exe'),
      p.join(executableDir, 'data', 'flutter_assets', 'assets', 'bin', 'mihomo.exe'),
      p.join(executableDir, 'assets', 'bin', 'mihomo.exe'),
    ];

    for (final candidate in candidates) {
      if (await File(candidate).exists()) {
        return candidate;
      }
    }
    return null;
  }


  Future<bool> _generateMihomoConfig() async {
    final path = await _axisPath;
    final configFile = File(p.join(path, 'config.yaml'));
    final proxyEntries = _buildProxyYamlFromLink(
      _selectedServerLink,
      _selectedServerName ?? "Axis-Proxy",
    );
    if (proxyEntries == null || proxyEntries.trim().isEmpty) {
      return false;
    }
    final selectedTag = _selectedServerName ?? "Axis-Proxy";
    final groupEntries = _selectedServerLink == null
        ? '''
      - DIRECT'''
        : '''
      - "$selectedTag"
      - DIRECT''';

    final String configContent = '''
mixed-port: 2080
allow-lan: false
mode: rule
log-level: info
ipv6: false
external-controller: 127.0.0.1:9090

# РќР°СЃС‚СЂРѕР№РєРё СѓСЃРєРѕСЂРµРЅРёСЏ С‚СЂР°С„РёРєР°
tcp-fast-open: true
unified-delay: true
global-client-fingerprint: chrome

dns:
  enable: true
  listen: 0.0.0.0:1053
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver:
    - ${settings.customDnsEnabled ? settings.dnsPrimary : 'https://1.1.1.1/dns-query'}
    - ${settings.customDnsEnabled ? settings.dnsSecondary : 'https://8.8.8.8/dns-query'}
  fallback:
    - ${settings.customDnsEnabled ? settings.dnsPrimary : '1.1.1.1'}
    - ${settings.customDnsEnabled ? settings.dnsSecondary : '8.8.8.8'}

proxies:
$proxyEntries
proxy-groups:
  - name: "Axis-Auto"
    type: select
    proxies:
$groupEntries
rules:
  - MATCH,Axis-Auto
${settings.tunEnabled || currentMode == 'TUN' ? '''
tun:
  enable: true
  stack: gvisor
  auto-route: true
  auto-detect-interface: true
''' : ''}
''';
    await configFile.writeAsString(configContent);
    debugPrint("РљРѕРЅС„РёРі СЃ СѓСЃРєРѕСЂРµРЅРёРµРј СЃРѕР·РґР°РЅ РІ ${configFile.path}");
    return true;
  }


  Future<List<String>> getServers() async {
    final entries = await getServerEntries();
    return entries.map((e) => e.name).toList();
  }

  Future<List<ServerEntry>> getServerEntries() async {
    try {
      final file = await _subFile;
      final customServers = await _loadCustomServers();
      await _loadSubscriptions();
      final subServers = _serversFromSubscriptions();
      if (!await file.exists()) {
        _serversData = [...subServers, ...customServers];
        return _serversData
            .map((e) => ServerEntry(
                  name: e['name']!,
                  link: e['link']!,
                  isCustom: (e['source'] ?? 'custom') == 'custom',
                  countryCode: _extractCountryCode(e['name']!),
                  source: e['source'] ?? 'custom',
                  subscriptionId: e['subscriptionId'],
                ))
            .toList();
      }

      final content = await file.readAsString();
      String decoded = content;
      
      try {
        if (!content.contains('://')) {
          final normalized = base64.normalize(content.trim());
          decoded = utf8.decode(base64.decode(normalized));
        }
      } catch (_) {}

      final lines = decoded.split('\n').where((l) => l.contains('://')).toList();
      
      final legacySubServers = lines.map((link) {
        String name = "Unknown Server";
        try {
          if (link.contains('#')) {
            name = Uri.decodeComponent(link.split('#').last);
          } else {
            final uri = Uri.parse(link);
            name = uri.host;
          }
        } catch (_) {}
        return {"name": name, "link": link, "source": "subscription", "subscriptionId": 'legacy'};
      }).toList();
      _serversData = [...subServers, ...legacySubServers, ...customServers];

      if (_serversData.isNotEmpty) {
        final selectedExists = _serversData.any((s) => s['name'] == _selectedServerName);
        if (!selectedExists) {
          _selectedServerName = _serversData.first['name'];
          _selectedServerLink = _serversData.first['link'];
        }
      } else {
        _selectedServerName = null;
        _selectedServerLink = null;
      }

      return _serversData
          .map((e) => ServerEntry(
                name: e['name']!,
                link: e['link']!,
                isCustom: (e['source'] ?? 'subscription') == 'custom',
                countryCode: _extractCountryCode(e['name']!),
                source: e['source'] ?? 'subscription',
                subscriptionId: e['subscriptionId'],
              ))
          .toList();
    } catch (e) {
      debugPrint("РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё СЃРµСЂРІРµСЂРѕРІ: $e");
      return const [];
    }
  }

  Future<bool> selectServer(String name) async {
    final server = _serversData.firstWhere((s) => s['name'] == name, orElse: () => {});
    if (server.isNotEmpty) {
      final link = server['link'];
      final testYaml = _buildProxyYamlFromLink(link, server['name'] ?? name);
      if (testYaml == null || testYaml.trim().isEmpty) {
        debugPrint("РЎРµСЂРІРµСЂ $name РёРјРµРµС‚ РЅРµРїРѕРґРґРµСЂР¶РёРІР°РµРјС‹Р№ С„РѕСЂРјР°С‚ СЃСЃС‹Р»РєРё");
        return false;
      }
      _selectedServerName = server['name'];
      _selectedServerLink = link;
      await _generateMihomoConfig();
      debugPrint("Р’С‹Р±СЂР°РЅ СЃРµСЂРІРµСЂ: ${server['name']}");
      return true;
    }
    return false;
  }

  String _escapeYaml(String value) => value.replaceAll('"', '\\"');

  String? _extractCountryCode(String name) {
    final upper = name.toUpperCase();
    final match = RegExp(r'\b([A-Z]{2})\b').firstMatch(upper);
    return match?.group(1);
  }

  String _decodeRemarkFromLink(String link) {
    if (!link.contains('#')) return '';
    try {
      return Uri.decodeComponent(link.split('#').last.trim());
    } catch (_) {
      return link.split('#').last.trim();
    }
  }

  int _toInt(String? value, [int fallback = 0]) {
    if (value == null || value.isEmpty) return fallback;
    return int.tryParse(value) ?? fallback;
    }

  String? _buildProxyYamlFromLink(String? rawLink, String fallbackName) {
    if (rawLink == null || rawLink.isEmpty) return null;
    final link = rawLink.trim();
    final scheme = link.split('://').first.toLowerCase();
    final name = _escapeYaml(_decodeRemarkFromLink(link).isNotEmpty ? _decodeRemarkFromLink(link) : fallbackName);

    try {
      if (scheme == 'ss') {
        final uri = Uri.parse(link);
        final host = uri.host;
        final port = uri.port;
        String method = '';
        String password = '';
        if (uri.userInfo.contains(':')) {
          final parts = uri.userInfo.split(':');
          method = parts.first;
          password = parts.sublist(1).join(':');
        } else if (uri.userInfo.isNotEmpty) {
          final decoded = utf8.decode(base64.decode(base64.normalize(uri.userInfo)));
          final creds = decoded.split(':');
          if (creds.length >= 2) {
            method = creds.first;
            password = creds.sublist(1).join(':');
          }
        }
        if (host.isEmpty || port <= 0 || method.isEmpty) return null;
        return '''
  - name: "$name"
    type: ss
    server: $host
    port: $port
    cipher: ${_escapeYaml(method)}
    password: "${_escapeYaml(password)}"''';
      }

      if (scheme == 'trojan') {
        final uri = Uri.parse(link);
        if (uri.host.isEmpty || uri.port <= 0 || uri.userInfo.isEmpty) return null;
        return '''
  - name: "$name"
    type: trojan
    server: ${uri.host}
    port: ${uri.port}
    password: "${_escapeYaml(uri.userInfo)}"
    udp: true
    sni: "${_escapeYaml(uri.queryParameters['sni'] ?? uri.host)}"
    skip-cert-verify: true''';
      }

      if (scheme == 'vmess') {
        final payload = link.substring('vmess://'.length);
        final decoded = utf8.decode(base64.decode(base64.normalize(payload)));
        final data = jsonDecode(decoded) as Map<String, dynamic>;
        final host = (data['add'] ?? '').toString();
        final port = _toInt((data['port'] ?? '').toString());
        final id = (data['id'] ?? '').toString();
        final tls = (data['tls'] ?? '').toString() == 'tls';
        final network = ((data['net'] ?? 'tcp').toString().isEmpty ? 'tcp' : data['net'].toString());
        final path = (data['path'] ?? '').toString();
        final hostHeader = (data['host'] ?? '').toString();
        if (host.isEmpty || port <= 0 || id.isEmpty) return null;
        final wsBlock = network == 'ws'
            ? '''
    ws-opts:
      path: "${_escapeYaml(path.isEmpty ? '/' : path)}"
      headers:
        Host: "${_escapeYaml(hostHeader.isEmpty ? host : hostHeader)}"'''
            : '';
        final grpcBlock = network == 'grpc'
            ? '''
    grpc-opts:
      grpc-service-name: "${_escapeYaml(path.isEmpty ? 'grpc' : path)}"'''
            : '';
        return '''
  - name: "$name"
    type: vmess
    server: $host
    port: $port
    uuid: "${_escapeYaml(id)}"
    alterId: ${_toInt((data['aid'] ?? '0').toString())}
    cipher: auto
    udp: true
    tls: $tls
    network: ${_escapeYaml(network)}
    servername: "${_escapeYaml((data['sni'] ?? host).toString())}"$wsBlock$grpcBlock''';
      }

      if (scheme == 'vless') {
        final uri = Uri.parse(link);
        if (uri.host.isEmpty || uri.port <= 0 || uri.userInfo.isEmpty) return null;
        final network = uri.queryParameters['type'] ?? 'tcp';
        final security = uri.queryParameters['security'] ?? '';
        final tlsEnabled = security == 'tls' || security == 'reality';
        final wsBlock = network == 'ws'
            ? '''
    ws-opts:
      path: "${_escapeYaml(uri.queryParameters['path'] ?? '/')}"
      headers:
        Host: "${_escapeYaml(uri.queryParameters['host'] ?? uri.host)}"'''
            : '';
        final grpcBlock = network == 'grpc'
            ? '''
    grpc-opts:
      grpc-service-name: "${_escapeYaml(uri.queryParameters['serviceName'] ?? 'grpc')}"'''
            : '';
        return '''
  - name: "$name"
    type: vless
    server: ${uri.host}
    port: ${uri.port}
    uuid: "${_escapeYaml(uri.userInfo)}"
    udp: true
    network: ${_escapeYaml(network)}
    tls: $tlsEnabled
    servername: "${_escapeYaml(uri.queryParameters['sni'] ?? uri.host)}"
    flow: "${_escapeYaml(uri.queryParameters['flow'] ?? '')}"
    client-fingerprint: chrome
    reality-opts:
      public-key: "${_escapeYaml(uri.queryParameters['pbk'] ?? '')}"
      short-id: "${_escapeYaml(uri.queryParameters['sid'] ?? '')}"$wsBlock$grpcBlock''';
      }
    } catch (e) {
      debugPrint("РћС€РёР±РєР° РїР°СЂСЃРёРЅРіР° СЃРµСЂРІРµСЂР°: $e");
    }
    return null;
  }

  Future<SubscriptionUpdateResult> updateSubscription(String url) async {
    if (url.isEmpty || !url.startsWith('http')) {
      return const SubscriptionUpdateResult(success: false);
    }
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final file = await _subFile;
        await file.writeAsString(response.body.trim());
        final servers = await getServers();
        return SubscriptionUpdateResult(
          success: true,
          subscriptionName: _extractSubscriptionName(response, url),
          serverCount: servers.length,
        );
      }
      return const SubscriptionUpdateResult(success: false);
    } catch (e) {
      debugPrint("Update error: $e");
      return const SubscriptionUpdateResult(success: false);
    }
  }

  Future<List<SubscriptionGroup>> getSubscriptionGroups() async {
    await _loadSubscriptions();
    return _subscriptions.map((sub) {
      final servers = (sub['servers'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((s) => ServerEntry(
                name: (s['name'] ?? '').toString(),
                link: (s['link'] ?? '').toString(),
                isCustom: false,
                source: 'subscription',
                subscriptionId: (sub['id'] ?? '').toString(),
                countryCode: _extractCountryCode((s['name'] ?? '').toString()),
              ))
          .where((s) => s.name.isNotEmpty && s.link.isNotEmpty)
          .toList();
      return SubscriptionGroup(
        id: (sub['id'] ?? '').toString(),
        name: (sub['name'] ?? 'Subscription').toString(),
        url: (sub['url'] ?? '').toString(),
        servers: servers,
      );
    }).toList();
  }

  Future<SubscriptionUpdateResult> addSubscription({
    required String url,
    String? customName,
  }) async {
    if (url.isEmpty || !url.startsWith('http')) {
      return const SubscriptionUpdateResult(success: false);
    }
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 || response.body.isEmpty) {
        return const SubscriptionUpdateResult(success: false);
      }
      final normalized = _decodeSubscriptionPayload(response.body);
      final links = normalized.split('\n').where((l) => l.contains('://')).toList();
      final servers = links.map((link) {
        final name = _decodeRemarkFromLink(link).isNotEmpty ? _decodeRemarkFromLink(link) : (Uri.tryParse(link)?.host ?? 'Unknown');
        return {'name': name, 'link': link};
      }).toList();
      if (servers.isEmpty) {
        return const SubscriptionUpdateResult(success: false);
      }
      await _loadSubscriptions();
      final derivedName = customName?.trim().isNotEmpty == true ? customName!.trim() : _extractSubscriptionName(response, url);
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      _subscriptions.add({'id': id, 'name': derivedName, 'url': url, 'servers': servers});
      await _saveSubscriptions();
      await getServerEntries();
      return SubscriptionUpdateResult(success: true, subscriptionName: derivedName, serverCount: servers.length);
    } catch (e) {
      debugPrint('Add subscription error: $e');
      return const SubscriptionUpdateResult(success: false);
    }
  }

  Future<void> renameSubscription(String id, String newName) async {
    await _loadSubscriptions();
    for (final sub in _subscriptions) {
      if ((sub['id'] ?? '').toString() == id) {
        sub['name'] = newName;
        break;
      }
    }
    await _saveSubscriptions();
  }

  String _decodeSubscriptionPayload(String content) {
    final trimmed = content.trim();
    if (trimmed.contains('://')) {
      return trimmed;
    }
    try {
      return utf8.decode(base64.decode(base64.normalize(trimmed)));
    } catch (_) {
      return trimmed;
    }
  }

  Future<void> _loadSubscriptions() async {
    try {
      final file = await _subscriptionsFile;
      if (!await file.exists()) {
        _subscriptions = [];
        return;
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _subscriptions = decoded.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {
      _subscriptions = [];
    }
  }

  List<Map<String, String>> _serversFromSubscriptions() {
    final out = <Map<String, String>>[];
    for (final sub in _subscriptions) {
      final sid = (sub['id'] ?? '').toString();
      final servers = (sub['servers'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
      for (final item in servers) {
        final name = (item['name'] ?? '').toString();
        final link = (item['link'] ?? '').toString();
        if (name.isEmpty || link.isEmpty) continue;
        out.add({'name': name, 'link': link, 'source': 'subscription', 'subscriptionId': sid});
      }
    }
    return out;
  }

  Future<void> _saveSubscriptions() async {
    final file = await _subscriptionsFile;
    await file.writeAsString(jsonEncode(_subscriptions));
  }

  Future<void> setAutoStart(bool enabled) async {
    if (!Platform.isWindows) return;
    final exePath = Platform.resolvedExecutable;
    final key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
    if (enabled) {
      await Process.run('reg', ['add', key, '/v', 'Axis', '/t', 'REG_SZ', '/d', exePath, '/f']);
    } else {
      await Process.run('reg', ['delete', key, '/v', 'Axis', '/f']);
    }
  }

  Future<bool> isRunningAsAdmin() async {
    if (!Platform.isWindows) return true;
    try {
      final result = await Process.run('net', ['session']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> relaunchAsAdmin() async {
    if (!Platform.isWindows) return true;
    final isAdmin = await isRunningAsAdmin();
    if (isAdmin) return true;
    try {
      final exePath = Platform.resolvedExecutable;
      final command = 'Start-Process -FilePath "$exePath" -Verb RunAs';
      await Process.run('powershell', ['-NoProfile', '-Command', command]);
      return true;
    } catch (e) {
      debugPrint('РќРµ СѓРґР°Р»РѕСЃСЊ Р·Р°РїСЂРѕСЃРёС‚СЊ РїСЂР°РІР° Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°: $e');
      return false;
    }
  }

  String _extractSubscriptionName(http.Response response, String sourceUrl) {
    final profileTitle = response.headers['profile-title'];
    if (profileTitle != null && profileTitle.isNotEmpty) {
      try {
        return utf8.decode(base64.decode(base64.normalize(profileTitle)));
      } catch (_) {
        return profileTitle;
      }
    }
    final contentDisposition = response.headers['content-disposition'] ?? '';
    final fileNameMatch = RegExp(r'filename="?([^"]+)"?', caseSensitive: false).firstMatch(contentDisposition);
    if (fileNameMatch != null) {
      return fileNameMatch.group(1)!;
    }
    try {
      return Uri.parse(sourceUrl).host;
    } catch (_) {
      return 'Subscription';
    }
  }

  Future<List<Map<String, String>>> _loadCustomServers() async {
    try {
      final file = await _customServersFile;
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final list = <Map<String, String>>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final name = (item['name'] ?? '').toString();
          final link = (item['link'] ?? '').toString();
          if (name.isEmpty || link.isEmpty) continue;
          list.add({'name': name, 'link': link, 'source': 'custom'});
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCustomServers() async {
    final custom = _serversData.where((s) => (s['source'] ?? '') == 'custom').toList();
    final file = await _customServersFile;
    await file.writeAsString(jsonEncode(custom.map((e) => {'name': e['name'], 'link': e['link']}).toList()));
  }

  Future<bool> addCustomServer({required String name, required String link}) async {
    final validated = _buildProxyYamlFromLink(link, name);
    if (validated == null || validated.isEmpty) return false;
    final current = await getServerEntries();
    final exists = current.any((s) => s.name == name);
    if (exists) return false;
    _serversData.add({'name': name, 'link': link, 'source': 'custom'});
    await _saveCustomServers();
    return true;
  }

  Future<int?> pingServer(String serverName, String pingMode) async {
    if (_serversData.isEmpty) {
      await getServerEntries();
    }
    Map<String, String>? server;
    for (final item in _serversData) {
      if (item['name'] == serverName) {
        server = item;
        break;
      }
    }
    if (server == null) return null;
    if (pingMode == 'proxy') {
      final sw = Stopwatch()..start();
      final ip = await _fetchIpInfoViaLocalProxy();
      sw.stop();
      return ip == null ? null : sw.elapsedMilliseconds;
    }
    final endpoint = _extractEndpointFromLink(server['link'] ?? '');
    if (endpoint == null) return null;
    if (pingMode == 'icmp') {
      return _icmpPing(endpoint.$1);
    }
    return _tcpPing(endpoint.$1, endpoint.$2);
  }

  Future<Map<String, int?>> pingAllServers(String pingMode) async {
    final list = await getServerEntries();
    final result = <String, int?>{};
    for (final server in list) {
      result[server.name] = await pingServer(server.name, pingMode);
    }
    return result;
  }

  (String, int)? _extractEndpointFromLink(String link) {
    try {
      final scheme = link.split('://').first.toLowerCase();
      if (scheme == 'vmess') {
        final payload = link.substring('vmess://'.length);
        final decoded = utf8.decode(base64.decode(base64.normalize(payload)));
        final data = jsonDecode(decoded) as Map<String, dynamic>;
        final host = (data['add'] ?? '').toString();
        final port = int.tryParse((data['port'] ?? '').toString()) ?? 0;
        if (host.isEmpty || port <= 0) return null;
        return (host, port);
      }
      final uri = Uri.parse(link);
      if (uri.host.isEmpty || uri.port <= 0) return null;
      return (uri.host, uri.port);
    } catch (_) {
      return null;
    }
  }

  Future<int?> _tcpPing(String host, int port) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
      await socket.close();
      sw.stop();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _icmpPing(String host) async {
    try {
      final result = await Process.run('ping', Platform.isWindows ? ['-n', '1', '-w', '2000', host] : ['-c', '1', '-W', '2', host]);
      final text = '${result.stdout}\n${result.stderr}';
      final match = RegExp(r'time[=<]?\s*(\d+)', caseSensitive: false).firstMatch(text) ??
          RegExp(r'РІСЂРµРјСЏ[=<]?\s*(\d+)', caseSensitive: false).firstMatch(text);
      if (match == null) return null;
      return int.tryParse(match.group(1)!);
    } catch (_) {
      return null;
    }
  }

  Future<String> fetchPublicIP() async {
    try {
      final viaProxy = await _fetchIpInfoViaLocalProxy();
      if (viaProxy != null && viaProxy.isNotEmpty) {
        return viaProxy;
      }
      final direct = await _fetchIpInfoDirect();
      if (direct != null && direct.isNotEmpty) {
        return direct;
      }
      return "...";
    } catch (_) {
      return "0.0.0.0";
    }
  }

  Future<String?> _fetchIpInfoViaLocalProxy() async {
    final client = HttpClient();
    try {
      client.findProxy = (uri) => "PROXY 127.0.0.1:2080";
      client.connectionTimeout = const Duration(seconds: 6);
      final apis = <Uri>[
        Uri.parse('https://api.ipify.org?format=json'),
        Uri.parse('https://api.myip.com'),
        Uri.parse('https://ipwho.is/'),
      ];
      for (final api in apis) {
        final req = await client.getUrl(api);
        final res = await req.close().timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) {
          continue;
        }
        final body = (await utf8.decoder.bind(res).join()).trim();
        final parsed = _parseIpFromApiBody(body);
        if (parsed != null) {
          return parsed;
        }
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<String?> _fetchIpInfoDirect() async {
    final apis = <Uri>[
      Uri.parse('https://api.ipify.org?format=json'),
      Uri.parse('https://api.myip.com'),
      Uri.parse('https://ipwho.is/'),
    ];
    for (final api in apis) {
      try {
        final res = await http.get(api).timeout(const Duration(seconds: 6));
        if (res.statusCode != 200) {
          continue;
        }
        final parsed = _parseIpFromApiBody(res.body);
        if (parsed != null) {
          return parsed;
        }
      } catch (_) {
      }
    }
    return null;
  }

  String? _parseIpFromApiBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final ip = (decoded['ip'] ?? decoded['query'] ?? '').toString().trim();
        final country = (decoded['country'] ?? decoded['country_name'] ?? '').toString().trim();
        if (ip.isEmpty) {
          return null;
        }
        if (country.isNotEmpty && country != 'null') {
          return '$ip вЂў $country';
        }
        return ip;
      }
    } catch (_) {
    }

    final rawIp = trimmed.replaceAll('"', '');
    final isIpLike = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(rawIp);
    return isIpLike ? rawIp : null;
  }

  Future<void> _setWindowsSystemProxy({required bool enabled}) async {
    if (!Platform.isWindows) return;
    try {
      final key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings';
      await Process.run('reg', ['add', key, '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', enabled ? '1' : '0', '/f']);
      if (enabled) {
        await Process.run('reg', ['add', key, '/v', 'ProxyServer', '/t', 'REG_SZ', '/d', '127.0.0.1:2080', '/f']);
        await Process.run('reg', ['add', key, '/v', 'ProxyOverride', '/t', 'REG_SZ', '/d', '<local>', '/f']);
      }
    } catch (e) {
      debugPrint('РќРµ СѓРґР°Р»РѕСЃСЊ РёР·РјРµРЅРёС‚СЊ СЃРёСЃС‚РµРјРЅС‹Р№ РїСЂРѕРєСЃРё: $e');
    }
  }
}
