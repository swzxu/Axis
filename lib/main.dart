import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:system_tray/system_tray.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'core_service.dart';
import 'localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AxisApp());
}

class AxisApp extends StatefulWidget {
  const AxisApp({super.key});
  @override
  State<AxisApp> createState() => _AxisAppState();
}

class _AxisAppState extends State<AxisApp> {
  Color _seedColor = Colors.blue;
  Color? _systemAccentColor;
  bool _isRussian = true;
  String _proxyMode = "Системный прокси";
  String? _selectedServer;
  String _pingMode = 'tcp';
  String _subscriptionName = '';
  bool _tunEnabled = false;
  bool _customDnsEnabled = false;
  String _dnsPrimary = '1.1.1.1';
  String _dnsSecondary = '8.8.8.8';
  bool _autoStart = false;
  String _themeMode = 'system';
  bool _useSystemAccent = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFullConfig();
  }

  Future<File> _getConfigFile() async {
    final localPath = Platform.environment['LOCALAPPDATA'] ?? "";
    final axisDir = Directory(p.join(localPath, 'Axis'));
    if (!await axisDir.exists()) await axisDir.create(recursive: true);
    return File(p.join(axisDir.path, 'config.json'));
  }

  Future<void> _loadFullConfig() async {
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        setState(() {
          _isRussian = data['isRussian'] ?? true;
          _seedColor = Color(data['seedColor'] ?? Colors.blue.toARGB32());
          _proxyMode = data['proxyMode'] ?? "Системный прокси";
          _selectedServer = data['selectedServer'];
          _pingMode = data['pingMode'] ?? 'tcp';
          _subscriptionName = data['subscriptionName'] ?? '';
          _tunEnabled = data['tunEnabled'] ?? false;
          _customDnsEnabled = data['customDnsEnabled'] ?? false;
          _dnsPrimary = data['dnsPrimary'] ?? '1.1.1.1';
          _dnsSecondary = data['dnsSecondary'] ?? '8.8.8.8';
          _autoStart = data['autoStart'] ?? false;
          _themeMode = data['themeMode'] ?? 'system';
          _useSystemAccent = data['useSystemAccent'] ?? false;
        });
        await _loadWindowsAccentColor();
      }
    } catch (e) {
      debugPrint("Load error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWindowsAccentColor() async {
    if (!Platform.isWindows) return;
    try {
      final key = r'HKCU\Software\Microsoft\Windows\DWM';
      final result = await Process.run('reg', ['query', key, '/v', 'AccentColor']);
      final output = '${result.stdout}';
      final match = RegExp(r'AccentColor\s+REG_DWORD\s+0x([0-9a-fA-F]+)').firstMatch(output);
      if (match == null) return;
      final value = int.tryParse(match.group(1)!, radix: 16);
      if (value == null) return;
      final a = (value >> 24) & 0xFF;
      final b = (value >> 16) & 0xFF;
      final g = (value >> 8) & 0xFF;
      final r = value & 0xFF;
      setState(() {
        _systemAccentColor = Color.fromARGB(a == 0 ? 255 : a, r, g, b);
      });
    } catch (e) {
      debugPrint('Accent color read failed: $e');
    }
  }

  Future<void> _saveFullConfig() async {
    try {
      final file = await _getConfigFile();
      final data = {
        'isRussian': _isRussian,
        'seedColor': _seedColor.toARGB32(),
        'proxyMode': _proxyMode,
        'selectedServer': _selectedServer,
        'pingMode': _pingMode,
        'subscriptionName': _subscriptionName,
        'tunEnabled': _tunEnabled,
        'customDnsEnabled': _customDnsEnabled,
        'dnsPrimary': _dnsPrimary,
        'dnsSecondary': _dnsSecondary,
        'autoStart': _autoStart,
        'themeMode': _themeMode,
        'useSystemAccent': _useSystemAccent,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    
    final brightness = switch (_themeMode) {
      'light' => Brightness.light,
      'dark' => Brightness.dark,
      _ => View.of(context).platformDispatcher.platformBrightness,
    };

    final activeSeed = _useSystemAccent ? (_systemAccentColor ?? _seedColor) : _seedColor;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: activeSeed, 
        brightness: brightness,
        cardTheme: CardThemeData(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(220, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: MainNavigation(
        config: {
          'isRussian': _isRussian,
          'proxyMode': _proxyMode,
          'selectedServer': _selectedServer,
          'pingMode': _pingMode,
          'subscriptionName': _subscriptionName,
          'tunEnabled': _tunEnabled,
          'customDnsEnabled': _customDnsEnabled,
          'dnsPrimary': _dnsPrimary,
          'dnsSecondary': _dnsSecondary,
          'autoStart': _autoStart,
          'themeMode': _themeMode,
          'useSystemAccent': _useSystemAccent,
        },
        onConfigChange: (newConfig) {
          setState(() {
            _isRussian = newConfig['isRussian'];
            _proxyMode = newConfig['proxyMode'];
            _selectedServer = newConfig['selectedServer'];
            _pingMode = newConfig['pingMode'];
            _subscriptionName = newConfig['subscriptionName'];
            _tunEnabled = newConfig['tunEnabled'] ?? _tunEnabled;
            _customDnsEnabled = newConfig['customDnsEnabled'] ?? _customDnsEnabled;
            _dnsPrimary = newConfig['dnsPrimary'] ?? _dnsPrimary;
            _dnsSecondary = newConfig['dnsSecondary'] ?? _dnsSecondary;
            _autoStart = newConfig['autoStart'] ?? _autoStart;
            _themeMode = newConfig['themeMode'] ?? _themeMode;
            _useSystemAccent = newConfig['useSystemAccent'] ?? _useSystemAccent;
          });
          if (_useSystemAccent) {
            _loadWindowsAccentColor();
          }
          _saveFullConfig();
        },
        onColorChange: (c) { 
          setState(() => _seedColor = c); 
          _saveFullConfig(); 
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onConfigChange;
  final Function(Color) onColorChange;

  const MainNavigation({
    super.key, 
    required this.config, 
    required this.onConfigChange, 
    required this.onColorChange
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _isConnected = false;
  String _ipAddress = "...";
  String? _selectedServer;
  String _pingMode = 'tcp';
  String _subscriptionName = '';
  Timer? _updateTimer;
  bool _isPingingAll = false;
  bool _sortByPing = false;
  Map<String, int?> _pingByServer = {};
  
  final CoreService _coreService = CoreService();
  final SystemTray _systemTray = SystemTray();
  final AppWindow _appWindow = AppWindow();
  final TextEditingController _dnsPrimaryController = TextEditingController();
  final TextEditingController _dnsSecondaryController = TextEditingController();

  AxisStrings get s => widget.config['isRussian'] ? AxisStrings.ru : AxisStrings.en;

  @override
  void didUpdateWidget(covariant MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config['isRussian'] != widget.config['isRussian']) {
      _updateTrayMenu();
    }
  }

  @override
  void initState() {
    super.initState();
    _coreService.currentMode = widget.config['proxyMode'];
    _selectedServer = widget.config['selectedServer'];
    _pingMode = widget.config['pingMode'] ?? 'tcp';
    _subscriptionName = widget.config['subscriptionName'] ?? '';
    _dnsPrimaryController.text = widget.config['dnsPrimary'] ?? '1.1.1.1';
    _dnsSecondaryController.text = widget.config['dnsSecondary'] ?? '8.8.8.8';
    _coreService.applySettings(CoreSettings(
      tunEnabled: widget.config['tunEnabled'] ?? false,
      customDnsEnabled: widget.config['customDnsEnabled'] ?? false,
      dnsPrimary: widget.config['dnsPrimary'] ?? '1.1.1.1',
      dnsSecondary: widget.config['dnsSecondary'] ?? '8.8.8.8',
    ));
    _restoreSelectedServer();
    _initSystemTray();
    _startAutoUpdateTask();
  }

  Future<void> _restoreSelectedServer() async {
    final saved = _selectedServer;
    if (saved == null || saved.isEmpty) return;
    final servers = await _coreService.getServers();
    if (!mounted || servers.isEmpty) return;
    if (servers.contains(saved)) {
      await _coreService.selectServer(saved);
      if (!mounted) return;
      setState(() => _selectedServer = saved);
      return;
    }
    final fallback = servers.first;
    await _coreService.selectServer(fallback);
    if (!mounted) return;
    setState(() => _selectedServer = fallback);
    widget.onConfigChange({...widget.config, 'selectedServer': fallback});
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _dnsPrimaryController.dispose();
    _dnsSecondaryController.dispose();
    super.dispose();
  }

  void _startAutoUpdateTask() {
    _updateTimer = Timer.periodic(const Duration(hours: 12), (timer) async {});
  }

  Future<void> _pingAllServers() async {
    setState(() => _isPingingAll = true);
    final results = await _coreService.pingAllServers(_pingMode);
    if (!mounted) return;
    setState(() {
      _pingByServer = results;
      _isPingingAll = false;
    });
  }

  String _displayServerName(ServerEntry entry) {
    final name = entry.name.trim();
    final match = RegExp(r'^([A-Za-z]{2})[\s\-_]+(.+)$').firstMatch(name);
    if (match != null) {
      final rest = (match.group(2) ?? '').trim();
      if (rest.isNotEmpty) {
        return rest;
      }
    }
    return name;
  }

  String? _displayCountryCode(ServerEntry entry) {
    if (entry.countryCode != null && entry.countryCode!.length == 2) {
      return entry.countryCode;
    }
    final match = RegExp(r'^([A-Za-z]{2})[\s\-_]+').firstMatch(entry.name.trim());
    return match?.group(1)?.toUpperCase();
  }

  String _displayServerNameFromRaw(String raw) {
    final name = raw.trim();
    final match = RegExp(r'^([A-Za-z]{2})[\s\-_]+(.+)$').firstMatch(name);
    if (match != null) {
      final rest = (match.group(2) ?? '').trim();
      if (rest.isNotEmpty) return rest;
    }
    return name;
  }

  String? _displayCountryCodeFromRaw(String raw) {
    final match = RegExp(r'^([A-Za-z]{2})[\s\-_]+').firstMatch(raw.trim());
    return match?.group(1)?.toUpperCase();
  }

  Future<void> _showAddServerDialog() async {
    final nameCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.addServer),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Link (vless/vmess/ss/...)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final ok = await _coreService.addCustomServer(name: nameCtrl.text.trim(), link: linkCtrl.text.trim());
              if (!ctx.mounted || !mounted) return;
              Navigator.of(ctx).pop();
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Не удалось добавить сервер')),
                );
                return;
              }
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Сервер добавлен')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSubscriptionDialog() async {
    final urlCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.addSubscription),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: urlCtrl, decoration: InputDecoration(labelText: s.subUrl)),
              const SizedBox(height: 10),
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: s.subscriptionName)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final result = await _coreService.addSubscription(
                url: urlCtrl.text.trim(),
                customName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
              );
              if (!ctx.mounted || !mounted) return;
              Navigator.of(ctx).pop();
              if (!result.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Не удалось добавить подписку')),
                );
                return;
              }
              setState(() {
                _subscriptionName = result.subscriptionName ?? _subscriptionName;
              });
              widget.onConfigChange({...widget.config, 'subscriptionName': _subscriptionName});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameSubscriptionDialog(SubscriptionGroup group) async {
    final nameCtrl = TextEditingController(text: group.name);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.renameSubscription),
        content: TextField(controller: nameCtrl, decoration: InputDecoration(labelText: s.subscriptionName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _coreService.renameSubscription(group.id, nameCtrl.text.trim());
              if (!ctx.mounted || !mounted) return;
              Navigator.of(ctx).pop();
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _initSystemTray() async {
    try {
      final iconPath = _trayIconPath(Platform.isWindows ? 'assets/shield.ico' : 'assets/shield.png');
      if (iconPath == null) return;
      await _systemTray.initSystemTray(title: "Axis VPN", iconPath: iconPath);
      await _updateTrayMenu();
      _systemTray.registerSystemTrayEventHandler((name) {
        if (name == kSystemTrayEventClick) {
          _appWindow.show();
        } else if (name == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
        }
      });
    } catch (e) { debugPrint("Tray error: $e"); }
  }

  Future<void> _updateTrayIcon() async {
    final connectedIcon = _trayIconPath(Platform.isWindows ? 'assets/shield.ico' : 'assets/shield.png');
    final disconnectedIcon = _trayIconPath(Platform.isWindows ? 'assets/shield.ico' : 'assets/shield.png');
    if (connectedIcon == null || disconnectedIcon == null) return;
    await _systemTray.setImage(_isConnected ? connectedIcon : disconnectedIcon);
  }

  String? _trayIconPath(String assetPath) {
    if (assetPath.isEmpty) return null;
    if (Platform.isMacOS) return assetPath;
    return p.join(
      p.dirname(Platform.resolvedExecutable),
      'data',
      'flutter_assets',
      assetPath,
    );
  }

  Future<void> _updateTrayMenu() async {
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: _isConnected ? s.disconnect : s.connect, onClicked: (_) => _handleConnect()),
      MenuSeparator(),
      MenuItemLabel(label: s.showWindow, onClicked: (_) => _appWindow.show()),
      MenuItemLabel(label: s.exit, onClicked: (_) async {
        await _coreService.stop();
        exit(0);
      }),
    ]);
    await _systemTray.setContextMenu(menu);
    await _updateTrayIcon();
  }

  Future<void> _handleConnect() async {
    if (_isConnected) {
      await _coreService.stop();
      setState(() { _isConnected = false; _ipAddress = s.disconnected; });
    } else {
      if (_coreService.currentMode == 'TUN') {
        final admin = await _coreService.isRunningAsAdmin();
        if (!admin) {
          final relaunched = await _coreService.relaunchAsAdmin();
          if (relaunched) {
            exit(0);
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось запросить права администратора для TUN')),
          );
          return;
        }
      }
      if (_selectedServer == null) {
        final available = await _coreService.getServers();
        if (available.isNotEmpty) {
          final fallbackServer = available.first;
          final selected = await _coreService.selectServer(fallbackServer);
          if (!selected) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Формат ссылки сервера не поддерживается')),
            );
            return;
          }
          _selectedServer = fallbackServer;
          widget.onConfigChange({...widget.config, 'selectedServer': fallbackServer});
        }
      }
      setState(() => _isConnected = true);
      final started = await _coreService.initAndStart();
      if (!started) {
        if (!mounted) return;
        setState(() {
          _isConnected = false;
          _ipAddress = s.disconnected;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось подключиться: проверь формат сервера/подписки')),
        );
        return;
      }
      _ipAddress = await _coreService.fetchPublicIP();
      setState(() {});
      await _showWindowsConnectionNotification();
    }
    await _updateTrayMenu();
  }

  Future<void> _showWindowsConnectionNotification() async {
    if (!Platform.isWindows || !_isConnected) return;
    const script = r'''
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > $null
$template = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>Axis</text>
      <text>Proxy connected successfully</text>
    </binding>
  </visual>
</toast>
"@
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml($template)
$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Axis")
$notifier.Show($toast)
''';
    try {
      await Process.run('powershell', ['-NoProfile', '-Command', script]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            labelType: NavigationRailLabelType.all,
            backgroundColor: cs.surfaceContainerLow,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: [
              NavigationRailDestination(icon: const Icon(Icons.shield_outlined), selectedIcon: const Icon(Icons.shield), label: Text(s.shieldLabel)),
              NavigationRailDestination(icon: const Icon(Icons.lan_outlined), selectedIcon: const Icon(Icons.lan), label: Text(s.proxiesLabel)),
              NavigationRailDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: Text(s.settingsLabel)),
            ],
          ),
          Expanded(
            child: Container(
              color: cs.surface,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: _buildPage(cs),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(ColorScheme cs) {
    switch (_selectedIndex) {
      case 0: return _dashboard(cs);
      case 1: return _servers(cs);
      case 2: return _settings(cs);
      default: return Container();
    }
  }

  Widget _dashboard(ColorScheme cs) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: (_isConnected ? cs.primaryContainer : cs.surfaceContainerHigh).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_isConnected ? Icons.shield_rounded : Icons.shield_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                _isConnected ? s.vpnActive : s.vpnInactive,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            color: _isConnected ? cs.primaryContainer : cs.surfaceContainerHighest,
            boxShadow: _isConnected ? [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 40)] : [],
          ),
          child: Icon(Icons.vpn_lock_rounded, size: 100, color: _isConnected ? cs.primary : cs.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        Card(
          color: cs.secondaryContainer.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), child: Column(children: [
            if (_selectedServer != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((_displayCountryCodeFromRaw(_selectedServer!) ?? '').length == 2)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CountryFlag.fromCountryCode(
                        _displayCountryCodeFromRaw(_selectedServer!)!,
                        theme: const ImageTheme(width: 18, height: 18, shape: Circle()),
                      ),
                    ),
                  Text(_displayServerNameFromRaw(_selectedServer!), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              )
            else
              Text(s.selectServer, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _ipAddress == "..." ? s.disconnected : _ipAddress,
              style: TextStyle(color: cs.primary, fontFamily: Platform.isWindows ? 'Consolas' : 'monospace'),
            ),
          ])),
        ),
        if (_coreService.currentMode == "Просто прокси" && _isConnected)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              color: cs.tertiaryContainer.withValues(alpha: 0.2),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("SOCKS5/HTTP: 127.0.0.1:2080", style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        const SizedBox(height: 48),
        SizedBox(width: 280, height: 72, child: FilledButton.icon(
          onPressed: _handleConnect,
          style: FilledButton.styleFrom(
            backgroundColor: _isConnected ? cs.errorContainer : cs.primary,
            foregroundColor: _isConnected ? cs.onErrorContainer : cs.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          icon: Icon(_isConnected ? Icons.stop_circle_outlined : Icons.power_settings_new_rounded),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _isConnected ? s.disconnect : s.connect,
              key: ValueKey(_isConnected),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        )),
      ]),
    ),
  );

  Widget _servers(ColorScheme cs) => FutureBuilder<List<SubscriptionGroup>>(
    future: _coreService.getSubscriptionGroups(),
    builder: (context, snap) {
      final groups = snap.data ?? const <SubscriptionGroup>[];
      final customFuture = _coreService.getServerEntries();
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _isPingingAll ? null : _pingAllServers,
                  icon: _isPingingAll
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.network_ping_rounded),
                  label: Text(s.pingAll),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _sortByPing = !_sortByPing),
                  icon: Icon(_sortByPing ? Icons.sort : Icons.sort_by_alpha),
                  label: Text(s.sortByPing),
                ),
                OutlinedButton.icon(
                  onPressed: _showAddServerDialog,
                  icon: const Icon(Icons.add),
                  label: Text(s.addServer),
                ),
                OutlinedButton.icon(
                  onPressed: _showAddSubscriptionDialog,
                  icon: const Icon(Icons.playlist_add),
                  label: Text(s.addSubscription),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ServerEntry>>(
              future: customFuture,
              builder: (context, customSnap) {
                final customList = (customSnap.data ?? const <ServerEntry>[]).where((e) => e.source == 'custom').toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...groups.map((group) {
                      final list = [...group.servers];
                      if (_sortByPing) {
                        list.sort((a, b) => (_pingByServer[a.name] ?? 999999).compareTo(_pingByServer[b.name] ?? 999999));
                      }
                      return Card(
                        child: ExpansionTile(
                          title: Text(group.name),
                          subtitle: Text('${group.servers.length} proxies'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showRenameSubscriptionDialog(group),
                          ),
                          children: list.map((entry) => _proxyTile(entry, cs)).toList(),
                        ),
                      );
                    }),
                    if (customList.isNotEmpty)
                      Card(
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: const Text('Custom'),
                          subtitle: Text('${customList.length} proxies'),
                          children: customList.map((entry) => _proxyTile(entry, cs)).toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          )
        ],
      );
    },
  );

  Widget _proxyTile(ServerEntry entry, ColorScheme cs) {
    return ListTile(
      leading: (_displayCountryCode(entry) != null && (_displayCountryCode(entry)?.length == 2))
          ? CountryFlag.fromCountryCode(
              _displayCountryCode(entry)!,
              theme: const ImageTheme(width: 24, height: 24, shape: Circle()),
            )
          : const Icon(Icons.public),
      title: Text(_displayServerName(entry)),
      subtitle: Text(
        _pingByServer[entry.name] != null ? '${_pingByServer[entry.name]} ms' : (entry.source == 'custom' ? 'Custom' : 'Subscription'),
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      trailing: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _selectedServer == entry.name ? 1 : 0,
        child: Icon(Icons.check_circle, color: cs.primary),
      ),
      onTap: () async {
        final previousServer = _selectedServer;
        setState(() => _selectedServer = entry.name);
        final selected = await _coreService.selectServer(entry.name);
        if (!mounted) return;
        if (!selected) {
          setState(() => _selectedServer = previousServer);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось выбрать сервер: неподдерживаемый формат')),
          );
          return;
        }
        if (_isConnected) {
          final started = await _coreService.initAndStart();
          if (!mounted) return;
          if (!started) {
            setState(() {
              _isConnected = false;
              _ipAddress = s.disconnected;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Переключение не удалось: формат сервера не поддерживается')),
            );
            return;
          }
        }
        widget.onConfigChange({...widget.config, 'selectedServer': entry.name});
        _ipAddress = await _coreService.fetchPublicIP();
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  Widget _settings(ColorScheme cs) => ListView(padding: const EdgeInsets.all(24), children: [
    _sectionHeader(s.about, cs),
    Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final Uri url = Uri.parse('https://github.com/swzxu/axis'); 
          if (!await launchUrl(url)) debugPrint("Error launch url");
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.shield_rounded, color: cs.primary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Axis VPN Client", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Version 1.2.0 • GitHub Project", style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              Text(s.author, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ])),
            const Icon(Icons.open_in_new_rounded, size: 20),
          ]),
        ),
      ),
    ),
    const SizedBox(height: 24),
    _sectionHeader(s.proxyMode, cs),
    Card(
      child: RadioGroup<String>(
        groupValue: _coreService.currentMode,
        onChanged: (v) {
          if (_isConnected || v == null) return;
          _coreService.currentMode = v;
          final tunEnabled = v == 'TUN' ? true : (widget.config['tunEnabled'] ?? false);
          _coreService.applySettings(CoreSettings(
            tunEnabled: tunEnabled,
            customDnsEnabled: widget.config['customDnsEnabled'] ?? false,
            dnsPrimary: _dnsPrimaryController.text.trim(),
            dnsSecondary: _dnsSecondaryController.text.trim(),
          ));
          widget.onConfigChange({...widget.config, 'proxyMode': v, 'tunEnabled': tunEnabled});
        },
        child: Column(children: [
          RadioListTile<String>(
            title: Text(s.sysProxy),
            value: "Системный прокси",
          ),
          RadioListTile<String>(
            title: Text(s.simpleProxy),
            value: "Просто прокси",
          ),
          RadioListTile<String>(
            title: Text(s.tunMode),
            value: "TUN",
          ),
        ]),
      ),
    ),
    const SizedBox(height: 24),
    _sectionHeader(s.customDns, cs),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(s.customDns),
              value: widget.config['customDnsEnabled'] ?? false,
              onChanged: (v) {
                widget.onConfigChange({...widget.config, 'customDnsEnabled': v});
                _coreService.applySettings(CoreSettings(
                  tunEnabled: widget.config['tunEnabled'] ?? false,
                  customDnsEnabled: v,
                  dnsPrimary: _dnsPrimaryController.text.trim(),
                  dnsSecondary: _dnsSecondaryController.text.trim(),
                ));
              },
            ),
            TextField(
              controller: _dnsPrimaryController,
              decoration: InputDecoration(labelText: s.primaryDns),
              onChanged: (v) => widget.onConfigChange({...widget.config, 'dnsPrimary': v}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dnsSecondaryController,
              decoration: InputDecoration(labelText: s.secondaryDns),
              onChanged: (v) => widget.onConfigChange({...widget.config, 'dnsSecondary': v}),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 24),
    _sectionHeader(s.pingMode, cs),
    Card(
      child: RadioGroup<String>(
        groupValue: _pingMode,
        onChanged: (v) {
          if (v == null) return;
          setState(() => _pingMode = v);
          widget.onConfigChange({...widget.config, 'pingMode': v});
        },
        child: Column(children: [
          RadioListTile<String>(title: Text(s.pingProxy), value: 'proxy'),
          RadioListTile<String>(title: Text(s.pingTcp), value: 'tcp'),
          RadioListTile<String>(title: Text(s.pingIcmp), value: 'icmp'),
        ]),
      ),
    ),
    const SizedBox(height: 24),
    _sectionHeader(s.config, cs),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          SwitchListTile(
            title: Text(s.autoStart),
            value: widget.config['autoStart'] ?? false,
            onChanged: (v) async {
              await _coreService.setAutoStart(v);
              widget.onConfigChange({...widget.config, 'autoStart': v});
            },
          ),
          SwitchListTile(
            title: Text(s.useWallpaperAccent),
            value: widget.config['useSystemAccent'] ?? false,
            onChanged: (v) => widget.onConfigChange({...widget.config, 'useSystemAccent': v}),
          ),
        ]),
      ),
    ),
    const SizedBox(height: 24),
    _sectionHeader(s.themeMode, cs),
    Card(
      child: RadioGroup<String>(
        groupValue: widget.config['themeMode'] ?? 'system',
        onChanged: (v) {
          if (v == null) return;
          widget.onConfigChange({...widget.config, 'themeMode': v});
        },
        child: Column(children: [
          RadioListTile<String>(title: Text(s.themeSystem), value: 'system'),
          RadioListTile<String>(title: Text(s.themeLight), value: 'light'),
          RadioListTile<String>(title: Text(s.themeDark), value: 'dark'),
        ]),
      ),
    ),
    const SizedBox(height: 24),
    _sectionHeader(s.langSwitch, cs),
    Card(
      child: SwitchListTile(
        title: Text(widget.config['isRussian'] ? "Русский" : "English"),
        value: widget.config['isRussian'],
        onChanged: (v) {
          widget.onConfigChange({...widget.config, 'isRussian': v});
          _updateTrayMenu();
        },
      ),
    ),
    const SizedBox(height: 24),
    _sectionHeader(s.appearance, cs),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          ...[Colors.blue, Colors.green, Colors.orange, Colors.red].map((c) => 
            GestureDetector(onTap: () => widget.onColorChange(c), child: CircleAvatar(backgroundColor: c, radius: 20))),
          IconButton.filledTonal(onPressed: () => _showPicker(cs), icon: const Icon(Icons.colorize)),
        ]),
      ),
    ),
  ]);

  Widget _sectionHeader(String t, ColorScheme cs) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 8), 
    child: Text(t, style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.bold))
  );

  void _showPicker(ColorScheme cs) {
    Color tempColor = cs.primary;
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text(s.appearance),
        content: SingleChildScrollView(child: ColorPicker(pickerColor: cs.primary, onColorChanged: (c) => tempColor = c)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(onPressed: () { widget.onColorChange(tempColor); Navigator.pop(ctx); }, child: const Text("OK")),
        ],
      ),
    );
  }
}
