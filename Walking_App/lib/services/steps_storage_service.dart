import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class StepStorageService {
  static final Box<int> _box = Hive.box<int>('steps');

  static String _getTodayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static int getTodaySteps() {
    return _box.get(_getTodayKey(), defaultValue: 0) ?? 0;
  }

  static void saveTodaySteps(int steps) {
    _box.put(_getTodayKey(), steps);
  }

  static void resetIfNewDay() {
    final today = _getTodayKey();
    final keys = _box.keys.cast<String>();
    for (final key in keys) {
      if (key != today) {
        _box.delete(key); // Xoá ngày cũ (tuỳ bạn có thể giữ lại nếu cần history)
      }
    }
  }
}
