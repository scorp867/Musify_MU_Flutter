import 'dart:io';
import 'package:musify_mu/features/home_feed/data/casita_parser.dart';

void main() async {
  final file = File(r'C:\Users\Admin\casita(testing_for_herocards)');
  final bytes = await file.readAsBytes();
  final parser = CasitaParser(bytes);
  final data = parser.parse();
  
  for (final section in data.sections) {
    print('Section: ${section.title} (${section.items.length} items)');
    for (final item in section.items) {
      print('  - ${item.uri}: traits => ${item.traits.keys.toList()}');
    }
  }
}
