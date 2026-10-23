
import 'dart:io';
import 'dart:convert';

const _patterns = <String>[
  "package:http",
  "package:dio",
  "package:web_socket_channel",
  'InternetAddress',
  'Socket(',
  'Process.start',
  'DynamicLibrary',
  'Runtime.getRuntime',
  'Uri.parse(',
  'HttpClient(',
  'firebase',
  'analytics',
  'telemetry',
];

void main() {
  final root = Directory.current.path;
  final pcFile = File(
    '$root${Platform.pathSeparator}.dart_tool${Platform.pathSeparator}package_config.json',
  );

  if (!pcFile.existsSync()) {
    stdout.writeln(
      '⚠️  Chưa thấy .dart_tool/package_config.json — hãy chạy flutter pub get trước.',
    );
    exitCode = 1;
    return;
  }

  final issues = <String>[];
  final config = pcFile.readAsStringSync();
  final json = jsonDecode(config) as Map<String, dynamic>;
  final packages = (json['packages'] as List).cast<Map<String, dynamic>>();

  for (final pkg in packages) {
    final name = pkg['name'] as String? ?? '';
    final rootUri = pkg['rootUri'] as String? ?? '';
    if (!name.contains('cccd_vietnam') &&
        !name.contains('dmrtd') &&
        !name.contains('flutter_nfc_kit')) {
      continue;
    }

    var dirPath = Uri.parse(rootUri).toFilePath();
    dirPath = dirPath.replaceAll('/', Platform.pathSeparator);
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      for (final pattern in _patterns) {
        if (content.contains(pattern)) {
          issues.add(
            '$name :: ${entity.path.replaceAll(root, '.')} -- chứa "$pattern"',
          );
        }
      }
    }
  }

  if (issues.isEmpty) {
    stdout.writeln(
      '✅ Không phát hiện pattern gửi dữ liệu ra mạng trong cccd_vietnam/dmrtd/flutter_nfc_kit.',
    );
  } else {
    stdout.writeln('🔴 Tìm thấy ${issues.length} điểm cần kiểm tra:');
    issues.forEach(stdout.writeln);
    exitCode = 1;
  }
}
