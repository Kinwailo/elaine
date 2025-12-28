import 'package:collection/collection.dart';

import '../services/data_store.dart';

typedef SettingsItem = Map<String, dynamic>;

final dataValueMap = <String, DataValue>{};
final settingsGroupMap = <String, List<SettingsItem>>{};

SettingsItem? _getSettingsItem(String group, String setting) {
  final groupItems = settingsGroupMap.putIfAbsent(
    group,
    () => settingsData
        .where((e) => e['setting'] == group)
        .expand((e) => e['data'] as List<SettingsItem>)
        .toList(),
  );
  final data = groupItems.firstWhereOrNull((e) => e['setting'] == setting);
  return data;
}

T getSetting<T>(String group, String setting) {
  final data = _getSettingsItem(group, setting);
  final def = data?['default'];
  final dv = dataValueMap.putIfAbsent(
    group,
    () => DataValue('settings', group),
  );
  return dv.get<T>(setting) ?? def;
}

void setSetting<T>(String group, String setting, T value) {
  final dv = dataValueMap.putIfAbsent(
    group,
    () => DataValue('settings', group),
  );
  dv.set(setting, value);
}

const settingsData = <SettingsItem>[
  {
    'name': '重新整理',
    'setting': 'ui',
    'data': [
      {'name': '同步前先重新整理一遍', 'setting': 'refreshBeforeSync', 'default': true},
      {'name': '等待伺服器同步新聞組資料', 'setting': 'waitSync', 'default': true},
      {'name': '同步後再重新整理一遍', 'setting': 'refreshAfterSync', 'default': true},
    ],
  },
  {
    'name': '圖片顯示',
    'setting': 'ui',
    'data': [
      {
        'name': '顯示圖片時闊度不大於：',
        'setting': 'imageMaxWidth',
        'default': 600,
        'step': 50,
        'min': 200,
        'max': 5000,
      },
      {'name': '以縮圖形式顯示圖片', 'setting': 'imagePreview', 'default': true},
      {
        'name': '顯示縮圖時高度不大於：',
        'setting': 'previewMaxHeight',
        'default': 100,
        'step': 10,
        'min': 50,
        'max': 500,
      },
    ],
  },
];
