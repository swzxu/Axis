import 'dart:io';
import 'package:path/path.dart' as p;

/// Единая точка определения директории данных приложения.
///
/// Обычный режим: `%LOCALAPPDATA%\Axis`.
/// Портативный режим (`-portable` в аргументах запуска): подпапка `data_config`
/// рядом с exe, чтобы конфиги жили вместе с программой и переносились с ней.
class AppPaths {
  AppPaths._();

  /// Включается в `main()`, если exe запущен с `-portable` / `--portable`.
  static bool portable = false;

  /// Каноничный флаг портативного режима (пробрасывается при автозапуске и
  /// перезапуске с правами администратора, чтобы дочерняя копия тоже читала
  /// конфиги из папки программы).
  static const String portableFlag = '-portable';

  /// Имя аргумента запуска, включающего портативный режим.
  static bool isPortableArg(String arg) =>
      arg == '-portable' || arg == '--portable';

  /// Аргументы запуска, которые нужно пробросить дочерним копиям процесса
  /// (автозапуск, перезапуск под админом). В обычном режиме пусто.
  static List<String> get launchArgs => portable ? const [portableFlag] : const [];

  /// Директория для хранения конфигов/данных. Создаётся при первом обращении.
  static Future<Directory> dataDir() async {
    final String base;
    if (portable) {
      // Директория с программой (рядом с Axis.exe). Подпапка, чтобы не смешивать
      // конфиги с exe и папкой ассетов `data`.
      base = p.join(p.dirname(Platform.resolvedExecutable), 'data_config');
    } else {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      base = p.join(localAppData, 'Axis');
    }
    final dir = Directory(base);
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Путь к файлу внутри директории данных.
  static Future<File> file(String name) async {
    final dir = await dataDir();
    return File(p.join(dir.path, name));
  }
}
