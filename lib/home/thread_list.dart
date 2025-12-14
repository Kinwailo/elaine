import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../app/const.dart';
import '../app/utils.dart';
import '../services/data_store.dart';
import 'group_store.dart';
import 'home_page.dart';
import 'post_store.dart';
import 'thread_store.dart';

class ThreadList extends HookWidget {
  const ThreadList({super.key});

  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey('centerThread');
    final threads = Modular.get<ThreadStore>();
    final countBackward = threads.nItems.length;
    final extraBackward = threads.reachStart ? 0 : 1;
    final countForward = threads.pItems.length;
    final extraForward = threads.reachEnd ? 0 : 1;
    // estimateTextHeight('（）', mainTextStyle);
    final controller = useScrollController();
    final anim = useAnimationController(duration: 200.ms);
    useAnimation(anim);
    useListenable(threads.nItems);
    useListenable(threads.pItems);
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
                center: centerKey,
                controller: controller,
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.only(right: 12),
                    sliver: SuperSliverList.builder(
                      itemCount: countBackward + extraBackward,
                      itemBuilder: (_, index) {
                        return index >= countBackward
                            ? MoreThreads(key: UniqueKey(), prepend: true)
                            : ThreadTile(
                                key: ValueKey(threads.nItems[index]),
                                index + 1,
                                threads.nItems[index],
                              );
                      },
                    ),
                  ),
                  SliverPadding(
                    key: centerKey,
                    padding: EdgeInsets.only(right: 12),
                    sliver: SuperSliverList.builder(
                      itemCount: countForward + extraForward,
                      itemBuilder: (_, index) {
                        return index >= countForward
                            ? MoreThreads(key: UniqueKey())
                            : ThreadTile(
                                key: ValueKey(threads.pItems[index]),
                                index,
                                threads.pItems[index],
                              );
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
    final groups = Modular.get<GroupStore>();
    final refreshing = groups.refreshing.value;
    final syncNew = groups.syncNew.value;
    useListenable(groups.refreshing);
    useListenable(groups.syncNew);
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
        Badge.count(
          count: syncNew,
          backgroundColor: newColor,
          isLabelVisible: syncNew > 0,
          offset: Offset.fromDirection(
            180 / 180 * 3.1415,
            '$syncNew'.length * 4,
          ),
          alignment: AlignmentGeometry.topRight,
          child: IconButton(
            onPressed: () {
              groups.refresh();
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
    final groups = Modular.get<GroupStore>();
    final syncTotal = groups.syncTotal.value;
    final msg = syncTotal > 0
        ? syncOverviewText.format([syncTotal])
        : syncTotal == 0
        ? syncOverviewFinishText
        : syncTimeoutText;
    useValueChanged(
      syncTotal,
      (_, _) => syncTotal > 0
          ? anim.forward()
          : Future.delayed(2.seconds, () => anim.reverse()),
    );
    useListenable(groups.syncTotal);
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
                      style: pinnedTextStyle.merge(
                        syncTotal == -1 ? errorTextStyle : null,
                      ),
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
  const MoreThreads({super.key, this.prepend = false});

  final bool prepend;

  @override
  Widget build(BuildContext context) {
    final threads = Modular.get<ThreadStore>();
    final loaded = useState(false);
    return VisibilityDetector(
      key: key!,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !loaded.value) {
          loaded.value = true;
          threads.loadMore(reverse: prepend);
        }
      },
      child: LinearProgressIndicator(),
    );
  }
}

class ThreadTile extends HookWidget {
  const ThreadTile(this.index, this.thread, {super.key});

  final int index;
  final ThreadData thread;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final groups = Modular.get<GroupStore>();
    final threads = Modular.get<ThreadStore>();
    final posts = Modular.get<PostStore>();
    final number = threads.getTile();
    final selected = thread.data.number == number;
    final color = selected
        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
        : index % 2 == 0
        ? colorScheme.secondary.withValues(alpha: 0.16)
        : colorScheme.tertiary.withValues(alpha: 0.16);
    final date = thread.data.date;
    final showDate = switch (DataValue('settings', 'ui').get<int>('order')) {
      1 => thread.data.latest,
      _ => date,
    };
    final group = groups.get(thread.data.group);
    final lastRefresh = group?.lastRefresh ?? refDateTime;
    final newThread =
        date.isAfter(lastRefresh) || thread.data.create.isAfter(lastRefresh);
    final newReply =
        thread.data.latest.isAfter(lastRefresh) ||
        thread.data.update.isAfter(lastRefresh);
    final unread =
        thread.data.total -
        (posts.postMode.value ? thread.readArray.value : thread.read.value);
    // final hot = (thread.hot * 100.0 / hotRef).round();
    useListenable(threads.tile);
    useListenable(thread.read);
    useListenable(thread.readArray);
    useListenable(posts.postMode.postFrame);
    return AppLink(
      root: thread.data.group,
      paths: [
        '${thread.data.number}',
        if (thread.read.value > 1) '${thread.read.value}',
      ],
      onTap: () => threads.updateTile(thread.data.number),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: !newThread
              ? null
              : Border(
                  left: BorderSide(
                    color: newColor.darken(index % 2 * 10),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
        ),
        child: Opacity(
          opacity: unread == 0 ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(thread.data.sender, style: senderTextStyle),
                    const SizedBox(width: 8),
                    TooltipVisibility(
                      visible: showDate.relative != showDate.format,
                      child: Tooltip(
                        message: showDate.format,
                        child: Text(showDate.relative, style: subTextStyle),
                      ),
                    ),
                    Spacer(),
                    // if (hot > 0) Text('🔥$hot', style: subTextStyle),
                    const SizedBox(width: 16),
                    Text('💬${thread.data.total}', style: subTextStyle),
                  ],
                ),
                const SizedBox(height: 4),
                Badge.count(
                  count: unread,
                  backgroundColor: newReply ? newColor : unreadColor,
                  offset: Offset.fromDirection(-20 / 180 * 3.1415, 12),
                  isLabelVisible:
                      (!newThread && newReply && unread > 0) ||
                      (unread > 0 && unread != thread.data.total),
                  child: Text(thread.data.subject, style: mainTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
