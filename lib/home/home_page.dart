import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../app/const.dart';
import '../app/utils.dart';
import '../services/cloud_service.dart';
import '../services/data_store.dart';
import '../widgets/chip_item.dart';
import 'group_store.dart';
import 'post_store.dart';
import 'thread_list.dart';
import 'post_list.dart';
import 'thread_store.dart';

class HomeModule extends Module {
  @override
  void binds(i) {
    i.addSingleton(CloudService.new);
    i.addSingleton(GroupStore.new);
    i.addSingleton(ThreadStore.new);
    i.addSingleton(PostStore.new);
  }

  @override
  void routes(r) {
    r.child(
      '/',
      child: (context) => const HomePage(key: ValueKey('HomePage')),
      children: [
        ChildRoute(
          '/groups',
          child: (_) => const ThreadList(key: ValueKey('ThreadList')),
          transition: TransitionType.noTransition,
        ),
        ChildRoute(
          '/settings',
          child: (_) => const ThreadList(key: ValueKey('ThreadList')),
          transition: TransitionType.noTransition,
        ),
        ChildRoute(
          '/:group',
          child: (_) {
            final groups = Modular.get<GroupStore>();
            final group = r.args.params['group'];
            if (group != null) groups.select(group);
            return const ThreadList(key: ValueKey('ThreadList'));
          },
          transition: TransitionType.noTransition,
          children: [
            ChildRoute(
              '/:thread',
              child: (_) {
                select(r, false);
                return const PostList(key: ValueKey('PostList'));
              },
              transition: TransitionType.noTransition,
            ),
            ChildRoute(
              '/:thread/:post',
              child: (_) {
                select(r, false);
                return const PostList(key: ValueKey('PostList'));
              },
              transition: TransitionType.noTransition,
            ),
            ChildRoute(
              '/:thread/post/:post',
              child: (_) {
                select(r, true);
                return const PostList(key: ValueKey('PostList'));
              },
              transition: TransitionType.noTransition,
            ),
          ],
        ),
      ],
    );
  }

  void select(RouteManager r, bool postMode) {
    final threads = Modular.get<ThreadStore>();
    final group = r.args.params['group'];
    final thread = int.tryParse(r.args.params['thread'] ?? '');
    final post = int.tryParse(r.args.params['post'] ?? '');
    if (group != null && thread != null) {
      threads.select(group, thread, (post ?? 1) - 1, postMode);
    }
  }
}

final scaffoldKey = GlobalKey<ScaffoldState>();

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        color: colorScheme.surfaceContainer,
        child: Align(
          alignment: AlignmentGeometry.topCenter,
          child: ClipRect(
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: 800, maxWidth: 1200),
              child: Stack(
                children: [
                  Row(
                    children: [
                      SizedBox(width: 108),
                      Expanded(
                        child: Scaffold(
                          key: scaffoldKey,
                          drawer: Drawer(width: 120, child: GroupList()),
                          body: const RouterOutlet(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 108,
                    child: NavigationRail(
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      selectedIndex: null,
                      labelType: NavigationRailLabelType.none,
                      trailing: SideBar(),
                      destinations: [],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GroupList extends HookWidget {
  const GroupList({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = Modular.get<GroupStore>();
    useListenable(groups.items);
    return ListView(
      padding: EdgeInsetsGeometry.symmetric(vertical: 8),
      children: groups.items.value
          .map(
            (e) => ChipItem(
              e.data.name,
              onPress: () {
                groups.select(e.data.group);
                Navigator.of(context).pop();
              },
            ),
          )
          .toList(),
    );
  }
}

class SideBar extends HookWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = Modular.get<GroupStore>();
    final threads = Modular.get<ThreadStore>();
    final group = groups.selected.value;
    final dv = useMemoized(() => DataValue('settings', 'ui'));
    useListenable(groups.selected);
    useListenable(dv);
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
          SideBarGroup(
            name: uiOrder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChipItem(
                  uiOrderTitle,
                  selectable: true,
                  selected: dv.get<int>('order') == 0,
                  onSelect: (v) {
                    if (v) dv.set('order', 0);
                    threads.refresh();
                    return dv.get<int>('order') == 0;
                  },
                ),
                ChipItem(
                  uiOrderReply,
                  selectable: true,
                  selected: dv.get<int>('order') == 1,
                  onSelect: (v) {
                    if (v) dv.set('order', 1);
                    threads.refresh();
                    return dv.get<int>('order') == 1;
                  },
                ),
                if (false)
                  ChipItem(
                    uiOrderHot,
                    selectable: true,
                    selected: dv.get<int>('order') == 2,
                    onSelect: (v) {
                      if (v) dv.set('order', 2);
                      threads.refresh();
                      return dv.get<int>('order') == 2;
                    },
                  ),
              ],
            ),
          ),
          SideBarGroup(
            name: uiGroup,
            child: Visibility(
              visible: group != null,
              child: ChipItem(
                group?.data.name ?? '',
                onPress: () => scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ),
        ].separator(const SizedBox(height: 8)),
      ),
    );
  }
}

class SideBarGroup extends HookWidget {
  const SideBarGroup({super.key, required this.name, required this.child});

  final String name;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.secondaryContainer.withValues(alpha: 0.5);
    final surface = colorScheme.surfaceContainerLow.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Center(child: Text(name)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
