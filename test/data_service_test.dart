import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/data_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('DataService', () {
    late DataService dataService;
    
    setUp(() async {
      // Initialize Supabase
      await Supabase.initialize(
        url: 'https://your-project-url.supabase.co',
        anonKey: 'your-anon-key',
      );
      dataService = DataService();
    });
    
    test('getEquipment includes category names', () async {
      // Fetch equipment with joins
      final equipment = await dataService.getEquipment();
      
      // Verify that at least one item was returned
      expect(equipment, isNotEmpty);
      
      // Log the first item for inspection using test framework output
      final first = equipment.first;
      addTearDown(() {
        debugPrint('Test results for first equipment item:');
        debugPrint('  ID: ${first.id}');
        debugPrint('  Name: ${first.name}');
        debugPrint('  Category ID: ${first.categoryId}');
        debugPrint('  Category Name: ${first.categoryName}');
      });
      
      // Check if category info is present
      for (final item in equipment) {
        if (item.categoryId != null) {
          expect(item.categoryName, isNotNull);
        }
      }
    });
  });
}