class AxisStrings {
  final String shieldLabel, serversLabel, settingsLabel, connect, disconnect,
      selectServer, proxyMode, sysProxy, simpleProxy, about, appearance,
      config, updateSub, langSwitch, showWindow, exit, check, disconnected, switching, autoUpdate, subUrl, vpnActive, vpnInactive;
  final String pingAll, sortByPing, addServer, pingMode, pingProxy, pingTcp, pingIcmp, subscriptionName;
  final String tunMode, customDns, primaryDns, secondaryDns, autoStart, themeMode, themeSystem, themeLight, themeDark, useWallpaperAccent, author;
  final String addSubscription, renameSubscription, proxiesLabel;

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
  });

  static AxisStrings en = AxisStrings(
    shieldLabel: 'Axis', serversLabel: 'Servers', settingsLabel: 'Settings',
    connect: 'CONNECT', disconnect: 'DISCONNECT', selectServer: 'SELECT SERVER',
    proxyMode: 'Proxy Mode', sysProxy: 'System Proxy', simpleProxy: 'Proxy',
    about: 'ABOUT', appearance: 'APPEARANCE', config: 'CONFIGURATION',
    updateSub: 'UPDATE SUBSCRIPTION', langSwitch: 'Language', showWindow: 'Show Window',
    exit: 'Exit', check: 'Checking...', disconnected: 'Disconnected', switching: 'Switching...', autoUpdate: 'Auto-update (12h)', subUrl: 'Subscription URL',
    vpnActive: 'Proxy active', vpnInactive: 'Proxy inactive',
    pingAll: 'Ping all', sortByPing: 'Sort by ping', addServer: 'Add server', pingMode: 'Ping mode',
    pingProxy: 'Via proxy', pingTcp: 'TCP', pingIcmp: 'ICMP', subscriptionName: 'Subscription',
    tunMode: 'TUN mode', customDns: 'Custom DNS', primaryDns: 'Primary DNS', secondaryDns: 'Secondary DNS',
    autoStart: 'Auto start with Windows', themeMode: 'Theme mode', themeSystem: 'System', themeLight: 'Light',
    themeDark: 'Dark', useWallpaperAccent: 'Use wallpaper/system accent', author: 'Author: hrdcoreee',
    addSubscription: 'Add subscription', renameSubscription: 'Rename', proxiesLabel: 'Proxies',
  );

  static AxisStrings ru = AxisStrings(
    shieldLabel: 'Axis', serversLabel: 'Сервера', settingsLabel: 'Настройки',
    connect: 'ПОДКЛЮЧИТЬ', disconnect: 'ОТКЛЮЧИТЬ', selectServer: 'ВЫБРАТЬ СЕРВЕР',
    proxyMode: 'Режим прокси', sysProxy: 'Системный прокси', simpleProxy: 'Прокси',
    about: 'О ПРОГРАММЕ', appearance: 'ВНЕШНИЙ ВИД', config: 'КОНФИГУРАЦИЯ',
    updateSub: 'ОБНОВИТЬ ПОДПИСКУ', langSwitch: 'Язык', showWindow: 'Развернуть',
    exit: 'Выход', check: 'Проверка...', disconnected: 'Отключено', switching: 'Смена...', autoUpdate: 'Автообновление (12ч)',
    subUrl: 'URL подписки',
    vpnActive: 'Прокси активен', vpnInactive: 'Прокси неактивен',
    pingAll: 'Пинг всех', sortByPing: 'Сортировка по пингу', addServer: 'Добавить сервер', pingMode: 'Режим пинга',
    pingProxy: 'Через прокси', pingTcp: 'TCP', pingIcmp: 'ICMP', subscriptionName: 'Подписка',
    tunMode: 'TUN режим', customDns: 'Пользовательский DNS', primaryDns: 'Основной DNS', secondaryDns: 'Резервный DNS',
    autoStart: 'Автозапуск с Windows', themeMode: 'Режим темы', themeSystem: 'Системная', themeLight: 'Светлая',
    themeDark: 'Темная', useWallpaperAccent: 'Использовать системный акцент', author: 'Автор: hrdcoreee',
    addSubscription: 'Добавить подписку', renameSubscription: 'Переименовать', proxiesLabel: 'Прокси',
  );
}