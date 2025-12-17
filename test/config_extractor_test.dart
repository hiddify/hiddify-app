// ignore_for_file: avoid_print
import 'package:hiddify/features/config/logic/config_extractor.dart';

void main() {
  const sampleText = '''
ShadowProxy66, [12/1/2025 6:27 PM]
🇮🇪
ss://YWVzLTEyOC1nY206dThncDE0OGl6OTBkZG9vNm1zMzdAMTQ2LjcwLjkwLjE5NjoxNzQ1NA==#Channel+id%3A+%40ShadowProxy66+%F0%9F%87%AE%F0%9F%87%AA
🇨🇭
ss://YWVzLTEyOC1nY206dnZ0OHVyMmJqanpiMm44emU1M2xAODYuMTA2Ljg0LjE5NjoxMzI2Mw==#Channel+id%3A+%40ShadowProxy66+%F0%9F%87%A8%F0%9F%87%AD
تست
🤩@ShadowProxy66

ShadowProxy66, [12/2/2025 8:48 AM]
🇩🇪
vless://4a0ced83-c4f2-4946-aa90-d9ce633d43a7@tormentedsoul.fonixapp.org:11487?security=reality#Channel%20id%3A%20%40ShadowProxy66
🤩@ShadowProxy66
''';

  print('=== ConfigExtractor Test ===\n');
  final hasConfigs = ConfigExtractor.containsConfig(sampleText);
  print('✓ Contains configs: $hasConfigs');
  final count = ConfigExtractor.countConfigs(sampleText);
  print('✓ Config count: $count');
  print('\n--- Extracted Configs ---');
  final configs = ConfigExtractor.extractConfigs(
    sampleText,
    source: 'telegram',
  );

  for (var i = 0; i < configs.length; i++) {
    final config = configs[i];
    print('${i + 1}. [${config.type.toUpperCase()}] ${config.name}');
    print('   URL: ${config.content.substring(0, 50)}...');
    print('   Source: ${config.source}');
    print('');
  }
  print('--- Raw URLs ---');
  final urls = ConfigExtractor.extractConfigUrls(sampleText);
  for (final url in urls) {
    print('  • ${url.substring(0, 50)}...');
  }
  print('\n--- Separated Content ---');
  final result = ConfigExtractor.separateConfigsFromText(sampleText);
  print('Configs found: ${result.configs.length}');
  print('Remaining text:\n${result.remainingText}');
  print('\n--- Unique Configs ---');
  final uniqueConfigs = ConfigExtractor.extractUniqueConfigs(sampleText);
  print('Unique count: ${uniqueConfigs.length}');

  print('\n=== Test Complete ===');
}
