import 'package:jiffy/jiffy.dart';

final startSleepTimeCountMark = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 22);
final stopSleepTimeCountMark = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 9);
String hiveSleepKey = Jiffy(DateTime.now()).format('dd-MM-yyyy');