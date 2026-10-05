import 'dart:io';
import 'package:musify_mu/core/protocol/generated/spotify/casita/resolved.pb.dart' as casita;
import 'package:musify_mu/features/home_feed/data/casita_parser.dart';

void main() async {
  final file = File(r'C:\Users\Admin\casita(testing_for_herocards)');
  final bytes = await file.readAsBytes();
  final home = casita.ResolvedHome.fromBuffer(bytes);

  final typeUrls = <String>{};
  for (final dataArray in home.eagerlyLoadedTraits.traits.extendedMetadata) {
    for (final extData in dataArray.extensionData) {
      if (extData.extensionData.hasTypeUrl()) {
        typeUrls.add(extData.extensionData.typeUrl);
      }
    }
  }
  print('Found typeUrls in eager traits:');
  for (final t in typeUrls) {
    print('  - $t');
  }

  final parser = CasitaParser(bytes);
  final result = await parser.parse();
  
  for (final section in result.homeData.sections) {
    if (section.sectionType != 'imageLink') {
      print('Section [${section.sectionType}]: "${section.title}" (${section.items.length} items)');
      for (final item in section.items) {
        print('  - ${item.uri}: traits => ${item.traits.keys.toList()}');
      }
    }
  }
}
