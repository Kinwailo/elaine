import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:url_launcher/link.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../app/utils.dart';
import 'home_store.dart';

class ThreadList extends HookWidget {
  const ThreadList({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Modular.get<HomeStore>();
    final count = home.threads.length;
    final extra = home.noMoreThreads ? 0 : 1;
    final controller = useMemoized(() => ScrollController());
    useListenable(home.threads);
    return Row(
      children: [
        SizedBox(
          width: 400,
          child: Scaffold(
            appBar: AppBar(
              title: Text(''),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1),
              ),
              actionsPadding: EdgeInsets.only(right: 4),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.create),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    home.refreshGroups();
                  },
                  icon: Icon(Icons.refresh),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
            body: Scrollbar(
              controller: controller,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              child: ListView.builder(
                controller: controller,
                padding: EdgeInsets.only(right: 12),
                itemCount: count + extra,
                itemBuilder: (_, index) {
                  return index >= count
                      ? MoreThreads(key: UniqueKey())
                      : ThreadTile(key: ValueKey(home.threads[index]), index);
                },
                itemExtentBuilder: (index, dimensions) {
                  if (index > count) return null;
                  if (index == count) return 4;
                  final style = DefaultTextStyle.of(context).style;
                  final thread = home.threads[index];
                  double height = 16;
                  height += estimateTextHeight(
                    thread.sender,
                    style.merge(senderTextStyle),
                    maxWidth: dimensions.crossAxisExtent - 32,
                  );
                  height += 4;
                  height += estimateTextHeight(
                    thread.subject,
                    style.merge(mainTextStyle),
                    maxWidth: dimensions.crossAxisExtent - 32,
                  );
                  height += 16;
                  return height;
                },
              ),
            ),
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: const RouterOutlet()),
      ],
    );
  }
}

class MoreThreads extends HookWidget {
  const MoreThreads({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Modular.get<HomeStore>();
    final loaded = useState(false);
    return VisibilityDetector(
      key: key!,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !loaded.value) {
          loaded.value = true;
          home.loadMoreThreads();
        }
      },
      child: LinearProgressIndicator(),
    );
  }
}

class ThreadTile extends HookWidget {
  const ThreadTile(this.index, {super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final home = Modular.get<HomeStore>();
    final thread = home.threads[index];
    final number = home.getThreadTile(home.currentThread.number);
    final selected = thread.number == number;
    final color = selected
        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
        : index % 2 == 0
        ? colorScheme.secondary.withValues(alpha: 0.16)
        : colorScheme.tertiary.withValues(alpha: 0.16);
    final date = thread.date;
    final hot = (thread.hot * 100.0 / hotRef).round();
    final link = '/${thread.group}/${thread.number}';
    useListenable(home.currentThreadTile);
    return Link(
      uri: Uri.parse(link),
      builder: (_, follow) => InkWell(
        onTap: () => follow?.call().whenComplete(
          () => home.updateThreadTile(thread.number),
        ),
        child: Container(
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(thread.sender, style: senderTextStyle),
                    const SizedBox(width: 8),
                    TooltipVisibility(
                      visible: date.relative != date.format,
                      child: Tooltip(
                        message: date.format,
                        child: Text(date.relative, style: subTextStyle),
                      ),
                    ),
                    Spacer(),
                    if (hot > 0) Text('🔥$hot', style: subTextStyle),
                    const SizedBox(width: 16),
                    Text('💬${thread.total}', style: subTextStyle),
                  ],
                ),
                const SizedBox(height: 4),
                Text(thread.subject, style: mainTextStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
