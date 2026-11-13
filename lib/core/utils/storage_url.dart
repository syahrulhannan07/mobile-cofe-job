import '../network/api_config.dart';

String buildStorageUrl(String? raw) {
  if (raw == null) return '';
  final value = raw.trim();
  if (value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api(?:/v\d+)?$'), '');

  if (value.startsWith('/storage/')) return '$base$value';

  final clean = value.startsWith('/') ? value.substring(1) : value;
  if (clean.startsWith('storage/')) return '$base/$clean';

  return '$base/storage/$clean';
}
