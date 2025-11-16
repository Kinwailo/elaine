import 'package:elaine/app/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:url_launcher/link.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../services/cloud_service.dart';
import 'home_store.dart';

class ThreadList extends HookWidget {
  const ThreadList({super.key});

  @override
  Widget build(BuildContext context) {
    final cloud = Modular.get<CloudService>();
    final count = cloud.threads.length;
    final extra = cloud.noMoreThreads ? 0 : 1;
    final controller = useMemoized(() => ScrollController());
    useListenable(cloud.threads);
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
                    cloud.refreshGroups();
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
                itemBuilder: (_, index) => index >= count
                    ? MoreThreads(key: UniqueKey())
                    : ThreadTile(key: ValueKey(index), index),
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
    final cloud = Modular.get<CloudService>();
    final loaded = useState(false);
    return VisibilityDetector(
      key: key!,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !loaded.value) {
          loaded.value = true;
          cloud.loadMoreThreads();
        }
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox.square(
            dimension: 50,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
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
    final cloud = Modular.get<CloudService>();
    final thread = cloud.threads[index];
    final number = home.getThreadTile(cloud.currentThread['num']);
    final selected = thread['num'] == number;
    final color = selected
        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
        : index % 2 == 0
        ? colorScheme.secondary.withValues(alpha: 0.1)
        : colorScheme.tertiary.withValues(alpha: 0.1);
    final date = DateTime.parse(
      thread['date'] ?? DateTime.fromMillisecondsSinceEpoch(0).toString(),
    ).toLocal();
    final hot =
        ((thread['hot'] ?? 0.0 as num) *
                100.0 /
                DateTime.now().difference(DateTime(2025, 10, 1)).inSeconds)
            .round();
    final link = '/${thread['group']}/${thread['num']}';
    useListenable(home.currentThreadTile);
    return Link(
      uri: Uri.parse(link),
      builder: (_, follow) => InkWell(
        onTap: () => follow?.call().whenComplete(
          () => home.updateThreadTile(thread['num']),
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
                    Text(
                      ((thread['sender'] ?? 'Null') as String).trim(),
                      style: TextStyle(color: Colors.blueAccent, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    TooltipVisibility(
                      visible: date.relative != date.format,
                      child: Tooltip(
                        message: date.format,
                        child: Text(
                          date.relative,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ),
                    Spacer(),
                    if (hot > 0)
                      Text(
                        '🔥$hot',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    const SizedBox(width: 16),
                    Text(
                      '💬${thread['total'] ?? 1}',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ((thread['subject'] ?? 'Null') as String).trim(),
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
