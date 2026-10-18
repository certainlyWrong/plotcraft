import 'package:easy_localization/easy_localization.dart';

/// Translates `<key>` or `<key>_one` (when [count] is 1) with `{count}` filled.
String countLabel(String key, int count) =>
    (count == 1 ? '${key}_one' : key).tr(namedArgs: {'count': '$count'});
