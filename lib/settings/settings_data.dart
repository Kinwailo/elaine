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
      {
        'name': '同步後再重新整理一遍',
        'setting': 'refreshAfterSync',
        'enabledBy': 'waitSync',
        'default': true,
      },
    ],
  },
  {
    'name': '主題整理',
    'setting': 'ui',
    'data': [
      {
        'name': '閱讀歷史儲存天數：',
        'setting': 'readHistoryDay',
        'default': 7,
        'step': 1,
        'min': 2,
        'max': 30,
      },
      {'name': '啟用屏蔽功能', 'setting': 'enableBlock', 'default': true},
      {
        'name': '屏蔽人員名單：',
        'setting': 'blockList',
        'enabledBy': 'enableBlock',
        'default': <String>[],
      },
    ],
  },
  {
    'name': '發文顯示',
    'setting': 'ui',
    'data': [
      {'name': '選擇主題後以階層形式顯示討論串', 'setting': 'openHierarchy', 'default': false},
      {'name': '選擇主題後跳至最後已閱讀的發文', 'setting': 'openLastRead', 'default': true},
      {
        'name': '啟用「顯示更多」若內文長度大於：',
        'setting': 'contentMaxHeight',
        'default': 600,
        'step': 50,
        'min': 200,
        'max': 5000,
      },
      {
        'name': '啟用「顯示更多」若引文長度大於：',
        'setting': 'quoteMaxHeight',
        'default': 100,
        'step': 10,
        'min': 50,
        'max': 500,
      },
      {
        'name': '顯示圖片時闊度不大於：',
        'setting': 'imageMaxWidth',
        'default': 600,
        'step': 50,
        'min': 200,
        'max': 5000,
      },
      {'name': '以縮圖形式顯示內文圖片', 'setting': 'imagePreview', 'default': false},
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
