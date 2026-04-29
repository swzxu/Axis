import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:system_tray/system_tray.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:country_flags/country_flags.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'localization.dart';
import 'core_service.dart';

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
  bool _showFirstRunWizard = false;
  bool _isCompletingFirstRun = false;
  bool _firstRunLanguageRussian = false;
  String _firstRunThemeMode = 'system';
  List<String> _favorites = [];
  String _hotkeyToggleConnection = '';
  String _hotkeyToggleWindow = '';
  String _routingRules = '';

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
        final content = await file.readAsString();
        if (content.trim().isEmpty) {
          setState(() => _showFirstRunWizard = true);
          return;
        }
        final data = jsonDecode(content);
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
          _favorites = List<String>.from(data['favorites'] ?? []);
          _hotkeyToggleConnection = data['hotkeyToggleConnection'] ?? '';
          _hotkeyToggleWindow = data['hotkeyToggleWindow'] ?? '';
          _routingRules = data['routingRules'] ?? '';
        });
        await _loadWindowsAccentColor();
      } else {
        setState(() => _showFirstRunWizard = true);
      }
    } catch (e) {
      debugPrint("Load error: $e");
      setState(() => _showFirstRunWizard = true);
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
        'favorites': _favorites,
        'hotkeyToggleConnection': _hotkeyToggleConnection,
        'hotkeyToggleWindow': _hotkeyToggleWindow,
        'routingRules': _routingRules,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  ThemeData _appTheme(Color seedColor, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seedColor,
      brightness: brightness,
      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
    );
  }

  Widget _buildFirstRunWizard() {
    final cs = Theme.of(context).colorScheme;
    final title = _firstRunLanguageRussian ? 'Добро пожаловать в Axis' : 'Welcome to Axis';
    final subtitle = _firstRunLanguageRussian
        ? 'Выберите язык и тему, чтобы продолжить.'
        : 'Choose your language and theme to continue.';
    final languageTitle = _firstRunLanguageRussian ? 'Язык' : 'Language';
    final themeTitle = _firstRunLanguageRussian ? 'Тема' : 'Theme';
    final systemTheme = _firstRunLanguageRussian ? 'Системная' : 'System';
    final lightTheme = _firstRunLanguageRussian ? 'Светлая' : 'Light';
    final darkTheme = _firstRunLanguageRussian ? 'Темная' : 'Dark';
    final continueText = _firstRunLanguageRussian ? 'Продолжить' : 'Continue';
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              color: cs.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(Icons.shield_rounded, size: 48, color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      languageTitle,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('English'), icon: Icon(Icons.language)),
                        ButtonSegment(value: true, label: Text('Русский'), icon: Icon(Icons.translate)),
                      ],
                      selected: {_firstRunLanguageRussian},
                      onSelectionChanged: _isCompletingFirstRun
                          ? null
                          : (selected) => setState(() => _firstRunLanguageRussian = selected.first),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      themeTitle,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'system', label: Text(systemTheme), icon: const Icon(Icons.brightness_auto_rounded)),
                        ButtonSegment(value: 'light', label: Text(lightTheme), icon: const Icon(Icons.light_mode_rounded)),
                        ButtonSegment(value: 'dark', label: Text(darkTheme), icon: const Icon(Icons.dark_mode_rounded)),
                      ],
                      selected: {_firstRunThemeMode},
                      onSelectionChanged: _isCompletingFirstRun
                          ? null
                          : (selected) => setState(() => _firstRunThemeMode = selected.first),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isCompletingFirstRun ? null : () => _selectLanguage(_firstRunLanguageRussian),
                      icon: _isCompletingFirstRun
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(continueText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectLanguage(bool isRussian) async {
    if (_isCompletingFirstRun) return;
    setState(() => _isCompletingFirstRun = true);
    try {
      _isRussian = isRussian;
      _themeMode = _firstRunThemeMode;
      await _saveFullConfig();
      if (!mounted) return;
      setState(() {
        _showFirstRunWizard = false;
        _isCompletingFirstRun = false;
      });
    } catch (e) {
      debugPrint('First run language select failed: $e');
      if (!mounted) return;
      setState(() {
        _isCompletingFirstRun = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));

    if (_showFirstRunWizard) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _appTheme(Colors.blue, Brightness.light),
        home: _buildFirstRunWizard(),
      );
    }

    final brightness = switch (_themeMode) {
      'light' => Brightness.light,
      'dark' => Brightness.dark,
      _ => View.of(context).platformDispatcher.platformBrightness,
    };

    final activeSeed = _useSystemAccent ? (_systemAccentColor ?? _seedColor) : _seedColor;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _appTheme(activeSeed, brightness),
      home: MainNavigation(
        config: {
          'isRussian': _isRussian,
          'seedColor': _seedColor,
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
          'favorites': _favorites,
          'hotkeyToggleConnection': _hotkeyToggleConnection,
          'hotkeyToggleWindow': _hotkeyToggleWindow,
          'routingRules': _routingRules,
        },
        onConfigChange: (newConfig) {
          setState(() {
            _isRussian = newConfig['isRussian'] ?? _isRussian;
            _seedColor = newConfig['seedColor'] ?? _seedColor;
            _proxyMode = newConfig['proxyMode'] ?? _proxyMode;
            _selectedServer = newConfig['selectedServer'];
            _pingMode = newConfig['pingMode'] ?? _pingMode;
            _subscriptionName = newConfig['subscriptionName'] ?? _subscriptionName;
            _tunEnabled = newConfig['tunEnabled'] ?? _tunEnabled;
            _customDnsEnabled = newConfig['customDnsEnabled'] ?? _customDnsEnabled;
            _dnsPrimary = newConfig['dnsPrimary'] ?? _dnsPrimary;
            _dnsSecondary = newConfig['dnsSecondary'] ?? _dnsSecondary;
            _autoStart = newConfig['autoStart'] ?? _autoStart;
            _themeMode = newConfig['themeMode'] ?? _themeMode;
            _useSystemAccent = newConfig['useSystemAccent'] ?? _useSystemAccent;
            _favorites = List<String>.from(newConfig['favorites'] ?? _favorites);
            _hotkeyToggleConnection = newConfig['hotkeyToggleConnection'] ?? _hotkeyToggleConnection;
            _hotkeyToggleWindow = newConfig['hotkeyToggleWindow'] ?? _hotkeyToggleWindow;
            _routingRules = newConfig['routingRules'] ?? _routingRules;
          });
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
  bool _showFavoritesOnly = false;
  Map<String, int?> _pingByServer = {};
  VoidCallback? _settingsPageRefresh;
  
  final CoreService _coreService = CoreService();
  final SystemTray _systemTray = SystemTray();
  final AppWindow _appWindow = AppWindow();
  final TextEditingController _dnsPrimaryController = TextEditingController();
  final TextEditingController _dnsSecondaryController = TextEditingController();

  AxisStrings get s => widget.config['isRussian'] ? AxisStrings.ru : AxisStrings.en;

  void _emitConfigChange(Map<String, dynamic> config) {
    widget.onConfigChange(config);
    _settingsPageRefresh?.call();
  }

  HotKey? _parseHotKey(String hotkeyString) {
    if (hotkeyString.isEmpty) return null;
    
    final parts = hotkeyString.split('+');
    LogicalKeyboardKey? key;
    final modifiers = <HotKeyModifier>[];
    
    final keyMap = {
      'a': LogicalKeyboardKey.keyA,
      'b': LogicalKeyboardKey.keyB,
      'c': LogicalKeyboardKey.keyC,
      'd': LogicalKeyboardKey.keyD,
      'e': LogicalKeyboardKey.keyE,
      'f': LogicalKeyboardKey.keyF,
      'g': LogicalKeyboardKey.keyG,
      'h': LogicalKeyboardKey.keyH,
      'i': LogicalKeyboardKey.keyI,
      'j': LogicalKeyboardKey.keyJ,
      'k': LogicalKeyboardKey.keyK,
      'l': LogicalKeyboardKey.keyL,
      'm': LogicalKeyboardKey.keyM,
      'n': LogicalKeyboardKey.keyN,
      'o': LogicalKeyboardKey.keyO,
      'p': LogicalKeyboardKey.keyP,
      'q': LogicalKeyboardKey.keyQ,
      'r': LogicalKeyboardKey.keyR,
      's': LogicalKeyboardKey.keyS,
      't': LogicalKeyboardKey.keyT,
      'u': LogicalKeyboardKey.keyU,
      'v': LogicalKeyboardKey.keyV,
      'w': LogicalKeyboardKey.keyW,
      'x': LogicalKeyboardKey.keyX,
      'y': LogicalKeyboardKey.keyY,
      'z': LogicalKeyboardKey.keyZ,
      '0': LogicalKeyboardKey.digit0,
      '1': LogicalKeyboardKey.digit1,
      '2': LogicalKeyboardKey.digit2,
      '3': LogicalKeyboardKey.digit3,
      '4': LogicalKeyboardKey.digit4,
      '5': LogicalKeyboardKey.digit5,
      '6': LogicalKeyboardKey.digit6,
      '7': LogicalKeyboardKey.digit7,
      '8': LogicalKeyboardKey.digit8,
      '9': LogicalKeyboardKey.digit9,
      ' ': LogicalKeyboardKey.space,
      'f1': LogicalKeyboardKey.f1,
      'f2': LogicalKeyboardKey.f2,
      'f3': LogicalKeyboardKey.f3,
      'f4': LogicalKeyboardKey.f4,
      'f5': LogicalKeyboardKey.f5,
      'f6': LogicalKeyboardKey.f6,
      'f7': LogicalKeyboardKey.f7,
      'f8': LogicalKeyboardKey.f8,
      'f9': LogicalKeyboardKey.f9,
      'f10': LogicalKeyboardKey.f10,
      'f11': LogicalKeyboardKey.f11,
      'f12': LogicalKeyboardKey.f12,
    };
    
    for (final part in parts) {
      final trimmed = part.trim().toLowerCase();
      if (trimmed == 'shift') {
        modifiers.add(HotKeyModifier.shift);
      } else if (trimmed == 'ctrl' || trimmed == 'control') {
        modifiers.add(HotKeyModifier.control);
      } else if (trimmed == 'alt') {
        modifiers.add(HotKeyModifier.alt);
      } else {
        key = keyMap[trimmed];
      }
    }
    
    if (key == null) return null;
    
    return HotKey(
      key: key,
      modifiers: modifiers,
    );
  }

  Future<void> _registerHotkeys() async {
    final toggleConnStr = widget.config['hotkeyToggleConnection'] as String? ?? '';
    final toggleWinStr = widget.config['hotkeyToggleWindow'] as String? ?? '';

    await HotKeyManager.instance.unregisterAll();

    if (toggleConnStr.isNotEmpty) {
      final hotkey = _parseHotKey(toggleConnStr);
      if (hotkey != null) {
        await HotKeyManager.instance.register(
          hotkey,
          keyDownHandler: (_) => _handleConnect(),
        );
      }
    }

    if (toggleWinStr.isNotEmpty) {
      final hotkey = _parseHotKey(toggleWinStr);
      if (hotkey != null) {
        await HotKeyManager.instance.register(
          hotkey,
          keyDownHandler: (_) => _appWindow.show(),
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config['isRussian'] != widget.config['isRussian']) {
      _updateTrayMenu();
    }
    if (oldWidget.config['hotkeyToggleConnection'] != widget.config['hotkeyToggleConnection'] ||
        oldWidget.config['hotkeyToggleWindow'] != widget.config['hotkeyToggleWindow']) {
      _registerHotkeys();
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
    _startAutoUpdateTask();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBackgroundServices();
    });
  }

  Future<void> _initializeBackgroundServices() async {
    try {
      await _restoreSelectedServer();
    } catch (e) {
      debugPrint('Restore selected server failed: $e');
    }
    try {
      await _initSystemTray();
    } catch (e) {
      debugPrint('System tray init failed: $e');
    }
    try {
      await _registerHotkeys();
    } catch (e) {
      debugPrint('Hotkey registration failed: $e');
    }
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
    _emitConfigChange({...widget.config, 'selectedServer': fallback});
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _dnsPrimaryController.dispose();
    _dnsSecondaryController.dispose();
    HotKeyManager.instance.unregisterAll();
    _coreService.stop();
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
    return entry.name;
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
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: s.name)),
              const SizedBox(height: 10),
              TextField(controller: linkCtrl, decoration: InputDecoration(labelText: s.serverLink)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          FilledButton(
            onPressed: () async {
              final ok = await _coreService.addCustomServer(name: nameCtrl.text.trim(), link: linkCtrl.text.trim());
              if (!ctx.mounted || !mounted) return;
              Navigator.of(ctx).pop();
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.serverAddFailed)),
                );
                return;
              }
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.serverAdded)),
              );
            },
            child: Text(s.add),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
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
                  SnackBar(content: Text(s.subscriptionAddFailed)),
                );
                return;
              }
              setState(() {
                _subscriptionName = result.subscriptionName ?? _subscriptionName;
              });
              _emitConfigChange({...widget.config, 'subscriptionName': _subscriptionName});
            },
            child: Text(s.add),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          FilledButton(
            onPressed: () async {
              await _coreService.renameSubscription(group.id, nameCtrl.text.trim());
              if (!ctx.mounted || !mounted) return;
              Navigator.of(ctx).pop();
              setState(() {});
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  Future<void> _initSystemTray() async {
    try {
      final iconPath = _trayIconPath(Platform.isWindows ? 'assets/tray_disconnected.ico' : 'assets/tray_disconnected.ico');
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
    final connectedIcon = _trayIconPath('assets/tray_connected.ico');
    final disconnectedIcon = _trayIconPath('assets/tray_disconnected.ico');
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

  Future<void> _hideWindowToTray() async {
    try {
      await _appWindow.hide();
    } catch (e) {
      debugPrint('Hide to tray error: $e');
    }
  }

  Future<void> _showWindowsNotification(String title, String message) async {
    if (!Platform.isWindows) return;
    try {
      final connectedIcon = _trayIconPath('assets/tray_connected.ico');
      final disconnectedIcon = _trayIconPath('assets/tray_disconnected.ico');
      final iconPath = _isConnected ? connectedIcon : disconnectedIcon;
      
      final script = r'''
try {
    if (Get-Module -ListAvailable -Name BurntToast) {
        New-BurntToastNotification -Title '{title}' -Body '{message}' -AppLogo '{icon}' -AppId 'Axis'
    } else {
        Add-Type -AssemblyName System.Windows.Forms
        $notify = New-Object System.Windows.Forms.NotifyIcon
        $notify.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('{icon}')
        $notify.Text = 'Axis'
        $notify.BalloonTipTitle = '{title}'
        $notify.BalloonTipText = '{message}'
        $notify.Visible = $true
        $notify.ShowBalloonTip(3000)
        Start-Sleep -Milliseconds 3500
        $notify.Dispose()
    }
} catch {}
'''.replaceAll('{title}', title).replaceAll('{message}', message).replaceAll('{icon}', iconPath ?? '');
      await Process.run('powershell', ['-NoProfile', '-WindowStyle', 'Hidden', '-Command', script]);
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  Future<void> _handleConnect() async {
    if (_isConnected) {
      await _coreService.stop();
      setState(() { _isConnected = false; _ipAddress = s.disconnected; });
      _showWindowsNotification(s.vpnInactive, s.disconnected);
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
            SnackBar(content: Text(s.adminRightsFailed)),
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
              SnackBar(content: Text(s.unsupportedServerFormat)),
            );
            return;
          }
          _selectedServer = fallbackServer;
          _emitConfigChange({...widget.config, 'selectedServer': fallbackServer});
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
          SnackBar(content: Text(s.connectFailed)),
        );
        return;
      }
      _ipAddress = await _coreService.fetchPublicIP();
      _showWindowsNotification(s.vpnActive, _selectedServer ?? s.vpnActive);
      setState(() {});
    }
    await _updateTrayMenu();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = widget.config['isRussian'] ? AxisStrings.ru : AxisStrings.en;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _hideWindowToTray();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              labelType: NavigationRailLabelType.all,
              backgroundColor: cs.surfaceContainerLow,
              leading: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(Icons.shield, size: 32, color: cs.primary),
              ),
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.shield_outlined),
                  selectedIcon: const Icon(Icons.shield),
                  label: Text(s.shieldLabel),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.lan_outlined),
                  selectedIcon: const Icon(Icons.lan),
                  label: Text(s.proxiesLabel),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: Text(s.settingsLabel),
                ),
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
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: (_isConnected ? cs.primaryContainer : cs.surfaceContainerHigh).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_isConnected ? Icons.shield_rounded : Icons.shield_outlined, size: 20),
              const SizedBox(width: 10),
              Text(
                _isConnected ? s.vpnActive : s.vpnInactive,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            color: _isConnected ? cs.primaryContainer : cs.surfaceContainerHighest,
            boxShadow: _isConnected ? [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 48, spreadRadius: 2)] : [],
          ),
          child: Icon(Icons.vpn_lock_rounded, size: 100, color: _isConnected ? cs.primary : cs.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        Card(
          elevation: 0,
          color: cs.secondaryContainer.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), child: Column(children: [
            if (_selectedServer != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((_displayCountryCodeFromRaw(_selectedServer!) ?? '').length == 2)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: CountryFlag.fromCountryCode(
                        _displayCountryCodeFromRaw(_selectedServer!)!,
                        theme: const ImageTheme(width: 24, height: 24, shape: Circle()),
                      ),
                    ),
                  Text(_displayServerNameFromRaw(_selectedServer!), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              )
            else
              Text(s.selectServer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              _ipAddress == "..." ? s.disconnected : _ipAddress,
              style: TextStyle(color: cs.primary, fontFamily: Platform.isWindows ? 'Consolas' : 'monospace', fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ])),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _coreService.currentMode == "Просто прокси" && _isConnected
            ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  elevation: 1,
                  color: cs.tertiaryContainer.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text("SOCKS5/HTTP: 127.0.0.1:2080", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
              )
            : const SizedBox.shrink(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 300, 
          height: 56, 
          child: FilledButton.icon(
            onPressed: _handleConnect,
            style: FilledButton.styleFrom(
              backgroundColor: _isConnected ? cs.errorContainer : cs.primary,
              foregroundColor: _isConnected ? cs.onErrorContainer : cs.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            icon: Icon(_isConnected ? Icons.stop_circle_outlined : Icons.power_settings_new_rounded, size: 22),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _isConnected ? s.disconnect : s.connect,
                key: ValueKey(_isConnected),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ),
      ]),
    ),
  );

  Widget _servers(ColorScheme cs) => FutureBuilder<List<SubscriptionGroup>>(
    future: _coreService.getSubscriptionGroups(),
    builder: (context, snap) {
      final groups = snap.data ?? const <SubscriptionGroup>[];
      final customFuture = _coreService.getServerEntries();
      final favorites = widget.config['favorites'] as List<String>? ?? [];
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: _isPingingAll
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.network_ping_rounded, size: 18),
                  label: Text(s.pingAll),
                  onPressed: _isPingingAll ? null : _pingAllServers,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _sortByPing,
                  label: Text(s.sortByPing),
                  onSelected: (_) => setState(() => _sortByPing = !_sortByPing),
                  avatar: Icon(_sortByPing ? Icons.sort : Icons.sort_by_alpha, size: 18),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(s.addServer),
                  onPressed: _showAddServerDialog,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.playlist_add, size: 18),
                  label: Text(s.addSubscription),
                  onPressed: _showAddSubscriptionDialog,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _showFavoritesOnly,
                  label: Text(s.showFavoritesOnly),
                  onSelected: (_) => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                  avatar: Icon(_showFavoritesOnly ? Icons.star : Icons.star_border, size: 18),
                  checkmarkColor: cs.primary,
                  selectedColor: cs.primaryContainer,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    ...groups.map((group) {
                      final list = [...group.servers];
                      if (_showFavoritesOnly) {
                        list.retainWhere((e) => favorites.contains(e.name));
                      }
                      if (list.isEmpty) return const SizedBox.shrink();
                      if (_sortByPing) {
                        list.sort((a, b) => (_pingByServer[a.name] ?? 999999).compareTo(_pingByServer[b.name] ?? 999999));
                      }
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: ExpansionTile(
                          title: Text(group.name),
                          subtitle: Text('${list.length} proxies'),
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
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: const Text('Custom'),
                          subtitle: Text('${customList.length} proxies'),
                          children: customList.where((e) => !_showFavoritesOnly || favorites.contains(e.name)).map((entry) => _proxyTile(entry, cs)).toList(),
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
    final isSelected = _selectedServer == entry.name;
    final pingMs = _pingByServer[entry.name];
    final favorites = widget.config['favorites'] as List<String>? ?? [];
    final isFavorite = favorites.contains(entry.name);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? cs.primaryContainer : cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: entry.countryCode != null
            ? CountryFlag.fromCountryCode(
                entry.countryCode!,
              )
            : const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.public, size: 28),
              ),
        title: Text(_displayServerName(entry), style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
        subtitle: Text(
          pingMs != null ? '${pingMs} ms' : (entry.source == 'custom' ? 'Custom' : 'Subscription'),
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : cs.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () {
              final newFavorites = List<String>.from(favorites);
              if (isFavorite) {
                newFavorites.remove(entry.name);
              } else {
                newFavorites.add(entry.name);
              }
              _emitConfigChange({...widget.config, 'favorites': newFavorites});
            },
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1 : 0,
            child: Icon(Icons.check_circle, color: cs.primary, size: 20),
          ),
        ],
      ),
      onTap: () async {
        final previousServer = _selectedServer;
        setState(() => _selectedServer = entry.name);
        final selected = await _coreService.selectServer(entry.name);
        if (!mounted) return;
        if (!selected) {
          setState(() => _selectedServer = previousServer);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.unsupportedServerFormat)),
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
              SnackBar(content: Text(s.switchFailed)),
            );
            return;
          }
        }
        _emitConfigChange({...widget.config, 'selectedServer': entry.name});
        _ipAddress = await _coreService.fetchPublicIP();
        if (!mounted) return;
        setState(() {});
      },
    ),
    );
  }

  Widget _settings(ColorScheme cs) => ListView(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), children: [
    _sectionHeader(s.about, cs),
    Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.info_outline, color: cs.primary),
        ),
        title: Text(s.about, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: const Text("Axis v1.3.0"),
        trailing: Icon(Icons.open_in_new_rounded, size: 22, color: cs.onSurfaceVariant),
        onTap: () async {
          final Uri url = Uri.parse('https://github.com/swzxu/axis');
          if (!await launchUrl(url)) debugPrint("Error launch url");
        },
      ),
    ),
    const SizedBox(height: 28),
    _sectionHeader(s.settingsLabel, cs),
    _settingsSectionTile(
      cs: cs,
      icon: Icons.public_rounded,
      title: s.networkSettings,
      subtitle: s.networkSettingsDesc,
      onTap: () => _openSettingsPage(s.networkSettings, Icons.public_rounded, _networkSettings),
    ),
    _settingsSectionTile(
      cs: cs,
      icon: Icons.apps_rounded,
      title: s.appSettings,
      subtitle: s.appSettingsDesc,
      onTap: () => _openSettingsPage(s.appSettings, Icons.apps_rounded, _appSettings),
    ),
    _settingsSectionTile(
      cs: cs,
      icon: Icons.palette_rounded,
      title: s.interfaceSettings,
      subtitle: s.interfaceSettingsDesc,
      onTap: () => _openSettingsPage(s.interfaceSettings, Icons.palette_rounded, _interfaceSettings),
    ),
  ]);

  Widget _settingsSectionTile({
    required ColorScheme cs,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Card(
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: cs.onPrimaryContainer),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
      onTap: onTap,
    ),
  );

  void _openSettingsPage(String title, IconData icon, List<Widget> Function(ColorScheme) childrenBuilder) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        final pageCs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setPageState) {
            _settingsPageRefresh = () => setPageState(() {});
            return Scaffold(
            backgroundColor: pageCs.surface,
            appBar: AppBar(
              title: Row(
                children: [
                  Icon(icon, color: pageCs.primary),
                  const SizedBox(width: 12),
                  Text(title),
                ],
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: childrenBuilder(pageCs),
            ),
          );
          },
        );
      },
    ));
  }

  List<Widget> _networkSettings(ColorScheme cs) => [
    _sectionHeader(s.proxyMode, cs),
    Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          _emitConfigChange({...widget.config, 'proxyMode': v, 'tunEnabled': tunEnabled});
        },
        child: Column(children: [
          RadioListTile<String>(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(s.sysProxy, style: const TextStyle(fontWeight: FontWeight.w500)),
            value: "Системный прокси",
          ),
          RadioListTile<String>(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(s.simpleProxy, style: const TextStyle(fontWeight: FontWeight.w500)),
            value: "Просто прокси",
          ),
          RadioListTile<String>(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(s.tunMode, style: const TextStyle(fontWeight: FontWeight.w500)),
            value: "TUN",
          ),
        ]),
      ),
    ),
    const SizedBox(height: 28),
    _sectionHeader(s.customDns, cs),
    Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.customDns, style: const TextStyle(fontWeight: FontWeight.w500)),
              value: widget.config['customDnsEnabled'] ?? false,
              onChanged: (v) {
                _emitConfigChange({...widget.config, 'customDnsEnabled': v});
                _coreService.applySettings(CoreSettings(
                  tunEnabled: widget.config['tunEnabled'] ?? false,
                  customDnsEnabled: v,
                  dnsPrimary: _dnsPrimaryController.text.trim(),
                  dnsSecondary: _dnsSecondaryController.text.trim(),
                ));
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dnsPrimaryController,
              decoration: InputDecoration(
                labelText: s.primaryDns,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (v) => _emitConfigChange({...widget.config, 'dnsPrimary': v}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dnsSecondaryController,
              decoration: InputDecoration(
                labelText: s.secondaryDns,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (v) => _emitConfigChange({...widget.config, 'dnsSecondary': v}),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 28),
    _sectionHeader(s.pingMode, cs),
    Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: RadioGroup<String>(
        groupValue: _pingMode,
        onChanged: (v) {
          if (v == null) return;
          setState(() => _pingMode = v);
          _emitConfigChange({...widget.config, 'pingMode': v});
        },
        child: Column(children: [
          RadioListTile<String>(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(s.pingProxy, style: const TextStyle(fontWeight: FontWeight.w500)),
            value: 'proxy',
          ),
          RadioListTile<String>(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(s.pingTcp, style: const TextStyle(fontWeight: FontWeight.w500)),
            value: 'tcp',
          ),
          RadioListTile<String>(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(s.pingIcmp, style: const TextStyle(fontWeight: FontWeight.w500)),
            value: 'icmp',
          ),
        ]),
      ),
    ),
    const SizedBox(height: 28),
    _sectionHeader(s.routingRules, cs),
    Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.routingRulesDesc, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showRoutingRulesDialog(),
              icon: const Icon(Icons.edit, size: 18),
              label: Text(s.editRules),
            ),
          ],
        ),
      ),
    ),
  ];

  List<Widget> _appSettings(ColorScheme cs) => [
    _sectionHeader(s.config, cs),
    Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.rocket_launch_rounded),
          title: Text(s.autoStart, style: const TextStyle(fontWeight: FontWeight.w500)),
          value: widget.config['autoStart'] ?? false,
          onChanged: (v) async {
            await _coreService.setAutoStart(v);
            _emitConfigChange({...widget.config, 'autoStart': v});
          },
        ),
      ),
    ),
    const SizedBox(height: 28),
    _sectionHeader(s.langSwitch, cs),
    Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.language_rounded),
          title: Text(widget.config['isRussian'] ? s.russian : s.english, style: const TextStyle(fontWeight: FontWeight.w500)),
          value: widget.config['isRussian'],
          onChanged: (v) {
            _emitConfigChange({...widget.config, 'isRussian': v});
            _updateTrayMenu();
          },
        ),
      ),
    ),
    const SizedBox(height: 28),
    _sectionHeader(s.hotkeys, cs),
    Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.power_settings_new_rounded),
              title: Text(s.toggleConnection, style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.config['hotkeyToggleConnection'] != null && widget.config['hotkeyToggleConnection'].toString().isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _emitConfigChange({...widget.config, 'hotkeyToggleConnection': ''}),
                      tooltip: s.clear,
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _showHotkeyDialog('hotkeyToggleConnection'),
                    child: Text(widget.config['hotkeyToggleConnection'] ?? s.setHotkey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.visibility_rounded),
              title: Text(s.toggleWindow, style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.config['hotkeyToggleWindow'] != null && widget.config['hotkeyToggleWindow'].toString().isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _emitConfigChange({...widget.config, 'hotkeyToggleWindow': ''}),
                      tooltip: s.clear,
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _showHotkeyDialog('hotkeyToggleWindow'),
                    child: Text(widget.config['hotkeyToggleWindow'] ?? s.setHotkey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ];

  List<Widget> _interfaceSettings(ColorScheme cs) => <Widget>[
    _sectionHeader(s.themeMode, cs),
    Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: RadioGroup<String>(
        groupValue: widget.config['themeMode'] ?? 'system',
        onChanged: (v) {
          if (v == null) return;
          _emitConfigChange({...widget.config, 'themeMode': v});
        },
        child: Column(children: [
          RadioListTile<String>(
            secondary: const Icon(Icons.brightness_auto_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(s.themeSystem, style: const TextStyle(fontWeight: FontWeight.w500)),
            value: 'system',
          ),
          RadioListTile<String>(
            secondary: const Icon(Icons.light_mode_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(s.themeLight, style: const TextStyle(fontWeight: FontWeight.w500)),
            value: 'light',
          ),
          RadioListTile<String>(
            secondary: const Icon(Icons.dark_mode_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(s.themeDark, style: const TextStyle(fontWeight: FontWeight.w500)),
            value: 'dark',
          ),
        ]),
      ),
    ),
    const SizedBox(height: 28),
    _sectionHeader(s.config, cs),
    Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.wallpaper_rounded),
          title: Text(s.useWallpaperAccent, style: const TextStyle(fontWeight: FontWeight.w500)),
          value: widget.config['useSystemAccent'] ?? false,
          onChanged: (v) => _emitConfigChange({...widget.config, 'useSystemAccent': v}),
        ),
      ),
    ),
    const SizedBox(height: 28),
    _sectionHeader(s.appearance, cs),
    Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ...[Colors.blue, Colors.green, Colors.orange, Colors.red].map((c) => 
            GestureDetector(
              onTap: () => widget.onColorChange(c), 
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outline.withValues(alpha: 0.3), width: 2),
                ),
              ),
            )),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: () => _showPicker(cs), 
            icon: const Icon(Icons.colorize, size: 20),
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
            ),
          ),
        ]),
      ),
    ),
  ];

  Widget _sectionHeader(String t, ColorScheme cs) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12), 
    child: Text(t, style: TextStyle(color: cs.primary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5))
  );

  void _showPicker(ColorScheme cs) {
    final colors = <Color>[
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.deepOrange,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.blueGrey,
    ];
    Color tempColor = widget.config['seedColor'] as Color? ?? cs.primary;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dialogCs = Theme.of(context).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            icon: Icon(Icons.palette_rounded, color: dialogCs.primary),
            title: Text(s.appearance, style: const TextStyle(fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 72,
                    decoration: BoxDecoration(
                      color: tempColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: dialogCs.outlineVariant),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: colors.map((color) {
                      final selected = color.toARGB32() == tempColor.toARGB32();
                      return InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => setDialogState(() => tempColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? dialogCs.onSurface : dialogCs.outlineVariant,
                              width: selected ? 3 : 1,
                            ),
                          ),
                          child: selected ? Icon(Icons.check_rounded, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.cancel, style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              FilledButton(
                onPressed: () {
                  widget.onColorChange(tempColor);
                  _settingsPageRefresh?.call();
                  Navigator.pop(ctx);
                },
                child: Text(s.ok, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }
  void _showHotkeyDialog(String hotkeyKey) {
    String capturedHotkey = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => RawKeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKey: (event) {
            if (event.runtimeType.toString().contains('Down')) {
              final key = event.logicalKey;
              final modifiers = <String>[];
              if (event.isShiftPressed) modifiers.add('Shift');
              if (event.isControlPressed) modifiers.add('Ctrl');
              if (event.isAltPressed) modifiers.add('Alt');
              final keyName = key.keyLabel;
              if (keyName.isNotEmpty && keyName.length <= 1) {
                capturedHotkey = modifiers.isEmpty ? keyName : '${modifiers.join('+')}+$keyName';
                setState(() {});
              }
            }
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(s.setHotkey, style: const TextStyle(fontWeight: FontWeight.w600)),
            content: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.pressKeys),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      capturedHotkey.isEmpty ? s.pressKeys : capturedHotkey,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: capturedHotkey.isEmpty ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.cancel, style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              FilledButton(
                onPressed: capturedHotkey.isEmpty ? null : () {
                  _emitConfigChange({...widget.config, hotkeyKey: capturedHotkey});
                  Navigator.pop(ctx);
                },
                child: Text(s.ok, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoutingRulesDialog() {
    final controller = TextEditingController(text: widget.config['routingRules'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(s.routingRules, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 600,
          height: 400,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              hintText: '# Example:\n# DOMAIN-SUFFIX,google.com,DIRECT\n# DOMAIN-KEYWORD,github,Proxy\n# IP-CIDR,192.168.0.0/16,DIRECT',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
            ),
            style: TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          FilledButton(
            onPressed: () {
              _emitConfigChange({...widget.config, 'routingRules': controller.text});
              Navigator.pop(ctx);
            },
            child: Text(s.saveRules, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

