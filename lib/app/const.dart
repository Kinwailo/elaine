import 'package:flutter/material.dart';

const uiOrder = '順序';
const uiOrderTitle = '最新主題';
const uiOrderReply = '最近回覆';
const uiOrderHot = '熱門討論';
const uiGroup = '群組';
const uiExpand = '展開';
const uiCollapse = '收起';

const emptyText = '無內文';
const syncBodyText = '載入發文內容中…';
const syncOverviewText = '從新聞組同步%s封發文中…';
const syncOverviewFinishText = '同步完成，請重新整理以觀看。';
const syncTimeoutText = '等候逾時，請稍後再嘗試。';
const retryText = '重新載入';

const mainTextStyle = TextStyle(fontSize: 18);
const subTextStyle = TextStyle(color: Colors.grey, fontSize: 14);
const senderTextStyle = TextStyle(color: Colors.blueAccent, fontSize: 14);
const pinnedTextStyle = TextStyle(fontSize: 16);
const errorTextStyle = TextStyle(color: Colors.redAccent);
const clickableTextStyle = TextStyle(
  color: Colors.blueAccent,
  decoration: TextDecoration.underline,
  decorationColor: Colors.blueAccent,
);

const unreadColor = Colors.blueAccent;
const newColor = Colors.redAccent;

final refDateTime = DateTime.fromMillisecondsSinceEpoch(0);
