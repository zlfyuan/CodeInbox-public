import 'package:url_launcher/url_launcher.dart';

abstract class IOpenUrl {
  Future<void> open(String url);
}

class UrlLauncherOpenUrl implements IOpenUrl {
  @override
  Future<void> open(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception('Could not open browser');
  }
}

class RecordingOpenUrl implements IOpenUrl {
  final List<String> opened = [];

  @override
  Future<void> open(String url) async => opened.add(url);
}
