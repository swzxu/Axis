class AxisStrings {
  final String shieldLabel, serversLabel, settingsLabel, connect, disconnect,
      selectServer, proxyMode, sysProxy, simpleProxy, about, appearance,
      config, updateSub, langSwitch, showWindow, exit, check, disconnected, switching, autoUpdate, subUrl, vpnActive, vpnInactive;
  final String pingAll, sortByPing, addServer, pingMode, pingProxy, pingTcp, pingIcmp, subscriptionName;
  final String tunMode, customDns, primaryDns, secondaryDns, autoStart, themeMode, themeSystem, themeLight, themeDark, useWallpaperAccent, author;
  final String addSubscription, renameSubscription, proxiesLabel;
  final String welcomeTitle, welcomeSubtitle, selectLanguage, english, russian, continueBtn;
  final String favorites, showFavoritesOnly;
  final String hotkeys, toggleConnection, toggleWindow, setHotkey, pressKeys;
  final String routingRules, routingRulesDesc, editRules, saveRules, clear;
  final String networkSettings, appSettings, interfaceSettings, openSection, back;
  final String networkSettingsDesc, appSettingsDesc, interfaceSettingsDesc;
  final String cancel, ok, add, save, name, serverLink;
  final String serverAddFailed, serverAdded, subscriptionAddFailed, unsupportedServerFormat, switchFailed, adminRightsFailed, connectFailed, noServersAdded;
  final String deleteServer, exportServer, copyLink, qrCode, serverDeleted, serverDeleteFailed, linkCopied;
  final String proxiesCount, customServers, subscriptionSource, syncSubscription, subscriptionSynced, subscriptionSyncFailed, timedOut;
  final String deleteSubscription, subscriptionDeleted, subscriptionDeleteFailed;
  final String noServersHint;

  AxisStrings({
    required this.shieldLabel, required this.serversLabel, required this.settingsLabel,
    required this.connect, required this.disconnect, required this.selectServer,
    required this.proxyMode, required this.sysProxy, required this.simpleProxy,
    required this.about, required this.appearance, required this.config,
    required this.updateSub, required this.langSwitch, required this.showWindow,
    required this.exit, required this.check, required this.disconnected, required this.autoUpdate, required this.switching, required this.subUrl,
    required this.vpnActive, required this.vpnInactive,
    required this.pingAll, required this.sortByPing, required this.addServer, required this.pingMode, required this.pingProxy,
    required this.pingTcp, required this.pingIcmp, required this.subscriptionName,
    required this.tunMode, required this.customDns, required this.primaryDns, required this.secondaryDns,
    required this.autoStart, required this.themeMode, required this.themeSystem, required this.themeLight,
    required this.themeDark, required this.useWallpaperAccent, required this.author, required this.addSubscription,
    required this.renameSubscription, required this.proxiesLabel,
    required this.welcomeTitle, required this.welcomeSubtitle, required this.selectLanguage,
    required this.english, required this.russian, required this.continueBtn,
    required this.favorites, required this.showFavoritesOnly,
    required this.hotkeys, required this.toggleConnection, required this.toggleWindow, required this.setHotkey, required this.pressKeys,
    required this.routingRules, required this.routingRulesDesc, required this.editRules, required this.saveRules, required this.clear,
    required this.networkSettings, required this.appSettings, required this.interfaceSettings, required this.openSection, required this.back,
    required this.networkSettingsDesc, required this.appSettingsDesc, required this.interfaceSettingsDesc,
    required this.cancel, required this.ok, required this.add, required this.save, required this.name, required this.serverLink,
    required this.serverAddFailed, required this.serverAdded, required this.subscriptionAddFailed, required this.unsupportedServerFormat,
    required this.switchFailed, required this.adminRightsFailed, required this.connectFailed, required this.noServersAdded,
    required this.deleteServer, required this.exportServer, required this.copyLink, required this.qrCode,
    required this.serverDeleted, required this.serverDeleteFailed, required this.linkCopied,
    required this.proxiesCount, required this.customServers, required this.subscriptionSource,
    required this.syncSubscription, required this.subscriptionSynced, required this.subscriptionSyncFailed, required this.timedOut,
    required this.deleteSubscription, required this.subscriptionDeleted, required this.subscriptionDeleteFailed,
    required this.noServersHint,
  });

  static AxisStrings en = AxisStrings(
    shieldLabel: 'Axis', serversLabel: 'Servers', settingsLabel: 'Settings',
    connect: 'Connect', disconnect: 'Disconnect', selectServer: 'Select server',
    proxyMode: 'Proxy Mode', sysProxy: 'System Proxy', simpleProxy: 'Proxy',
    about: 'About', appearance: 'Appearance', config: 'Configuration',
    updateSub: 'Update subscription', langSwitch: 'Language', showWindow: 'Show Window',
    exit: 'Exit', check: 'Checking...', disconnected: 'Disconnected', switching: 'Switching...', autoUpdate: 'Auto-update (12h)', subUrl: 'Subscription URL',
    vpnActive: 'Proxy active', vpnInactive: 'Proxy inactive',
    pingAll: 'Ping all', sortByPing: 'Sort by ping', addServer: 'Add server', pingMode: 'Ping mode',
    pingProxy: 'Via proxy', pingTcp: 'TCP', pingIcmp: 'ICMP', subscriptionName: 'Name (optionally)',
    tunMode: 'TUN mode', customDns: 'Custom DNS', primaryDns: 'Primary DNS', secondaryDns: 'Secondary DNS',
    autoStart: 'Auto start with Windows', themeMode: 'Theme mode', themeSystem: 'System', themeLight: 'Light',
    themeDark: 'Dark', useWallpaperAccent: 'Use wallpaper/system accent', author: 'Author: hrdcoreee',
    addSubscription: 'Add subscription', renameSubscription: 'Rename', proxiesLabel: 'Proxies',
    welcomeTitle: 'Welcome to Axis', welcomeSubtitle: 'Choose your preferred language', selectLanguage: 'Select Language',
    english: 'English', russian: 'Русский', continueBtn: 'Continue',
    favorites: 'Favorites', showFavoritesOnly: 'Show favorites only',
    hotkeys: 'Hotkeys', toggleConnection: 'Toggle connection', toggleWindow: 'Toggle window', setHotkey: 'Set hotkey', pressKeys: 'Press keys...',
    routingRules: 'Routing Rules', routingRulesDesc: 'Mihomo format rules (experimental)', editRules: 'Edit Rules', saveRules: 'Save', clear: 'Clear',
    networkSettings: 'Network', appSettings: 'Application', interfaceSettings: 'Interface', openSection: 'Open', back: 'Back',
    networkSettingsDesc: 'Proxy mode, DNS, ping and routing rules',
    appSettingsDesc: 'Autostart, language and global hotkeys',
    interfaceSettingsDesc: 'Theme mode, accent color and appearance',
    cancel: 'Cancel', ok: 'OK', add: 'Add', save: 'Save', name: 'Name', serverLink: 'Link (vless/vmess/ss/...)',
    serverAddFailed: 'Failed to add server', serverAdded: 'Server added', subscriptionAddFailed: 'Failed to add subscription',
    unsupportedServerFormat: 'Unsupported server format', switchFailed: 'Switch failed: unsupported server format', adminRightsFailed: 'Failed to request administrator rights for TUN mode', connectFailed: 'Failed to connect: check server or subscription format', noServersAdded: 'No servers added. Add a server first',
    deleteServer: 'Delete server', exportServer: 'Export server', copyLink: 'Copy link', qrCode: 'QR code',
    serverDeleted: 'Server deleted', serverDeleteFailed: 'Failed to delete server', linkCopied: 'Link copied',
    proxiesCount: 'servers', customServers: 'Custom', subscriptionSource: 'Subscription',
    syncSubscription: 'Sync subscription', subscriptionSynced: 'Subscription synced', subscriptionSyncFailed: 'Failed to sync subscription',
    timedOut: 'timed out',
    deleteSubscription: 'Delete subscription', subscriptionDeleted: 'Subscription deleted', subscriptionDeleteFailed: 'Failed to delete subscription',
    noServersHint: 'Add a subscription or server',
  );

  static AxisStrings ru = AxisStrings(
    shieldLabel: 'Axis', serversLabel: 'Сервера', settingsLabel: 'Настройки',
    connect: 'Подключить', disconnect: 'Отключить', selectServer: 'Сервер не выбран',
    proxyMode: 'Режим прокси', sysProxy: 'Системный прокси', simpleProxy: 'Прокси',
    about: 'О программе', appearance: 'Внешний вид', config: 'Конфигурация',
    updateSub: 'Обновить подписку', langSwitch: 'Язык', showWindow: 'Развернуть',
    exit: 'Выход', check: 'Проверка...', disconnected: 'Отключено', switching: 'Смена...', autoUpdate: 'Автообновление (12ч)',
    subUrl: 'URL подписки',
    vpnActive: 'Прокси активен', vpnInactive: 'Прокси неактивен',
    pingAll: 'Пинг всех', sortByPing: 'Сортировка по пингу', addServer: 'Добавить сервер', pingMode: 'Режим пинга',
    pingProxy: 'Через прокси', pingTcp: 'TCP', pingIcmp: 'ICMP', subscriptionName: 'Имя (необязательно)',
    tunMode: 'TUN режим', customDns: 'Пользовательский DNS', primaryDns: 'Основной DNS', secondaryDns: 'Резервный DNS',
    autoStart: 'Автозапуск с Windows', themeMode: 'Режим темы', themeSystem: 'Системная', themeLight: 'Светлая',
    themeDark: 'Темная', useWallpaperAccent: 'Использовать системный акцент', author: 'Автор: hrdcoreee',
    addSubscription: 'Добавить подписку', renameSubscription: 'Переименовать', proxiesLabel: 'Прокси',
    welcomeTitle: 'Добро пожаловать в Axis', welcomeSubtitle: 'Выберите предпочитаемый язык', selectLanguage: 'Выберите язык',
    english: 'English', russian: 'Русский', continueBtn: 'Продолжить',
    favorites: 'Избранные', showFavoritesOnly: 'Только избранные',
    hotkeys: 'Горячие клавиши', toggleConnection: 'Переключить соединение', toggleWindow: 'Показать окно', setHotkey: 'Назначить', pressKeys: 'Нажмите клавиши...',
    routingRules: 'Правила маршрутизации', routingRulesDesc: 'Правила в формате Mihomo (Экспериментально)', editRules: 'Редактировать', saveRules: 'Сохранить', clear: 'Очистить',
    networkSettings: 'Сеть', appSettings: 'Приложение', interfaceSettings: 'Интерфейс', openSection: 'Открыть', back: 'Назад',
    networkSettingsDesc: 'Режим прокси, DNS, пинг и правила маршрутизации',
    appSettingsDesc: 'Автозапуск, язык и глобальные горячие клавиши',
    interfaceSettingsDesc: 'Тема, акцентный цвет и внешний вид',
    cancel: 'Отмена', ok: 'OK', add: 'Добавить', save: 'Сохранить', name: 'Имя', serverLink: 'Ссылка (vless/vmess/ss/...)',
    serverAddFailed: 'Не удалось добавить сервер', serverAdded: 'Сервер добавлен', subscriptionAddFailed: 'Не удалось добавить подписку',
    unsupportedServerFormat: 'Формат ссылки сервера не поддерживается', switchFailed: 'Переключение не удалось: формат сервера не поддерживается', adminRightsFailed: 'Не удалось запросить права администратора для TUN режима', connectFailed: 'Не удалось подключиться: проверь формат сервера/подписки', noServersAdded: 'Нет ни одного сервера. Сначала импортируйте подписку или добавьте сервер',
    deleteServer: 'Удалить сервер', exportServer: 'Экспорт сервера', copyLink: 'Скопировать ссылку', qrCode: 'QR-код',
    serverDeleted: 'Сервер удалён', serverDeleteFailed: 'Не удалось удалить сервер', linkCopied: 'Ссылка скопирована',
    proxiesCount: 'серверов', customServers: 'Пользовательские', subscriptionSource: 'Подписка',
    syncSubscription: 'Синхронизировать подписку', subscriptionSynced: 'Подписка синхронизирована', subscriptionSyncFailed: 'Не удалось синхронизировать подписку',
    timedOut: 'не отвечает',
    deleteSubscription: 'Удалить подписку', subscriptionDeleted: 'Подписка удалена', subscriptionDeleteFailed: 'Не удалось удалить подписку',
    noServersHint: 'Добавьте подписку или сервер',
  );
}