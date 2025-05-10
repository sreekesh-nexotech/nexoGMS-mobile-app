import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final mainProvider = StateNotifierProvider<MainController, String>((ref) {
  return MainController();
});

class MainController extends StateNotifier<String> {
  MainController() : super('Member');

  Future<void> loadCustomerName(String fallbackName) async {
    try {
      final box = await Hive.openBox('auth');
      final cachedName = box.get('customer_name') as String?;
      state = cachedName ?? fallbackName;
    } catch (e) {
      state = fallbackName;
    }
  }
}
