import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:url_launcher/link.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app/const.dart';
import '../app/utils.dart';
import 'home_store.dart';

class ThreadList extends HookWidget {
  const ThreadList({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Modular.get<HomeStore>();
    final count = home.threads.length;
    final extra = home.noMoreThreads ? 0 : 1;
    estimateTextHeight('（）', mainTextStyle);
    final controller = useScrollController();
    final anim = useAnimationController(duration: 200.ms);
    useAnimation(anim);
    useListenable(home.threads);
    return Row(
      children: [
        SizedBox(
          width: 400,
          child: Scaffold(
            appBar: ThreadAppBar(anim),
            body: Scrollbar(
              controller: controller,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.only(right: 12),
                    sliver: SliverVariedExtentList.builder(
                      itemCount: count + extra,
                      itemBuilder: (_, index) {
                        return index >= count
                            ? MoreThreads(key: UniqueKey())
                            : ThreadTile(
                                key: ValueKey(home.threads[index]),
                                index,
                              );
                      },
                      itemExtentBuilder: (index, dimensions) {
                        if (index > count) return null;
                        if (index == count) return 4;
                        final style = DefaultTextStyle.of(context).style;
                        final thread = home.threads[index];
                        final maxWidth = dimensions.crossAxisExtent - 32;
                        double height = 16;
                        height += estimateTextHeight(
                          thread.sender,
                          style.merge(senderTextStyle),
                          maxWidth: maxWidth,
                        );
                        height += 4;
                        height += estimateTextHeight(
                          thread.subject,
                          style.merge(mainTextStyle),
                          maxWidth: maxWidth,
                        );
                        height += 16;
                        return height;
                      },
                    ),
                  ),
                ],
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

class ThreadAppBar extends HookWidget implements PreferredSizeWidget {
  ThreadAppBar(this.anim, {super.key});

  final AnimationController anim;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight - 12 + _syncStateBar.preferredSize.height);

  late final SyncStateBar _syncStateBar = SyncStateBar(anim);

  @override
  Widget build(BuildContext context) {
    final home = Modular.get<HomeStore>();
    final refreshing = home.refreshing.value;
    useListenable(home.refreshing);
    return AppBar(
      toolbarHeight: kToolbarHeight - 12,
      title: Text('', style: mainTextStyle),
      titleSpacing: 10,
      bottom: _syncStateBar,
      actionsPadding: EdgeInsets.only(right: 2),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.create),
          padding: EdgeInsetsGeometry.all(0),
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
          icon: refreshing
              ? Icon(Icons.refresh)
                    .animate(onPlay: (anim) => anim.repeat())
                    .rotate(duration: 1.seconds)
              : Icon(Icons.refresh),
          padding: EdgeInsetsGeometry.all(0),
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
    );
  }
}

class SyncStateBar extends HookWidget implements PreferredSizeWidget {
  const SyncStateBar(this.anim, {super.key});

  final AnimationController anim;

  @override
  Size get preferredSize => Size.fromHeight(1 + anim.value * 41);

  @override
  Widget build(BuildContext context) {
    final home = Modular.get<HomeStore>();
    final syncTotal = home.syncTotal.value;
    final msg = syncTotal > 0
        ? syncOverviewText.format([syncTotal])
        : syncTotal == 0
        ? syncOverviewFinishText
        : syncOverviewTimeoutText;
    useValueChanged(
      syncTotal,
      (_, _) => syncTotal > 0
          ? anim.forward()
          : Future.delayed(2.seconds, () => anim.reverse()),
    );
    useListenable(home.syncTotal);
    return Column(
      children: [
        Divider(height: 1),
        if (anim.value > 0)
          SizedBox(
            height: anim.value * 40,
            child: Align(
              alignment: AlignmentGeometry.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Text(
                      msg,
                      style: syncTotal == -1 ? errorTextStyle : pinnedTextStyle,
                    ),
                    Spacer(),
                    AnimatedOpacity(
                      opacity: syncTotal > 0 && anim.value == 1 ? 1 : 0,
                      duration: 200.ms,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        constraints: BoxConstraints.expand(width: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (anim.value > 0) Divider(height: anim.value * 1),
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
    final number = home.getThreadTile(home.thread.number);
    final selected = thread.number == number;
    final color = selected
        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
        : index % 2 == 0
        ? colorScheme.secondary.withValues(alpha: 0.16)
        : colorScheme.tertiary.withValues(alpha: 0.16);
    final date = thread.date;
    // final hot = (thread.hot * 100.0 / hotRef).round();
    final link = '/${thread.group}/${thread.number}';
    useListenable(home.threadTile);
    return Link(
      uri: Uri.parse(link),
      builder: (_, follow) => InkWell(
        onTap: () async {
          Modular.to.pushNamedAndRemoveUntil(
            link,
            ModalRoute.withName('/${thread.group}/'),
          );
          home.updateThreadTile(thread.number);
        },
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
                    // if (hot > 0) Text('🔥$hot', style: subTextStyle),
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
