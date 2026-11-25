import 'dart:io';

void main() {
  final pubCache = Platform.environment['PUB_CACHE'] ?? 
                   '${Platform.environment['LOCALAPPDATA']}\\Pub\\Cache';
  final dir = Directory('$pubCache\\hosted\\pub.dev');
  if (dir.existsSync()) {
    final cccdDirs = dir.listSync().where((e) => e.path.contains('cccd_vietnam'));
    for (var d in cccdDirs) {
      print(d.path);
    }
  } else {
    print('Pub cache not found at $pubCache');
  }
}
