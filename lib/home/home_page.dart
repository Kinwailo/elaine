import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../services/appwrite.dart';
import '../services/cloud_service.dart';
import 'group_store.dart';
import 'post_store.dart';
import 'thread_list.dart';
import 'post_list.dart';
import 'thread_store.dart';

class HomeModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<CloudService>(AppWrite.new);
    i.addSingleton(GroupStore.new);
    i.addSingleton(ThreadStore.new);
    i.addSingleton(PostStore.new);
  }

  @override
  void routes(r) {
    r.child(
      '/',
      child: (context) => HomePage(),
      children: [
        ChildRoute(
          '/groups',
          child: (_) => ThreadList(),
          transition: TransitionType.noTransition,
        ),
        ChildRoute(
          '/settings',
          child: (_) => ThreadList(),
          transition: TransitionType.noTransition,
        ),
        ChildRoute(
          '/:group',
          child: (_) {
            final groups = Modular.get<GroupStore>();
            final group = r.args.params['group'];
            if (group != null) groups.select(group);
            return ThreadList();
          },
          transition: TransitionType.noTransition,
          children: [
            ChildRoute(
              '/:thread',
              child: (_) {
                final threads = Modular.get<ThreadStore>();
                final group = r.args.params['group'];
                final number = int.tryParse(r.args.params['thread']);
                if (group != null && number != null) {
                  threads.select(group, number);
                }
                return PostList();
              },
              transition: TransitionType.noTransition,
            ),
          ],
        ),
      ],
    );
  }
}

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldKey = GlobalKey<ScaffoldState>();
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
                      SizedBox(width: 80),
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
                    width: 80,
                    child: NavigationRail(
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      selectedIndex: null,
                      labelType: NavigationRailLabelType.none,
                      leading: IconButton(
                        onPressed: () {
                          scaffoldKey.currentState?.openDrawer();
                        },
                        icon: const Icon(Icons.add),
                      ),
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
    final group = groups.selected.value;
    useListenable(groups.selected);
    return Visibility(
      visible: group != null,
      child: ChipItem(group?.data.name ?? ''),
    );
  }
}

class ChipItem extends HookWidget {
  const ChipItem(this.name, {super.key, this.onPress});

  final String name;
  final void Function()? onPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = useState(false);

    return Card(
      elevation: 2,
      margin: const EdgeInsetsGeometry.symmetric(vertical: 4, horizontal: 16),
      color: selected.value
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
      shadowColor: colorScheme.shadow,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected.value
              ? colorScheme.secondary.withValues(alpha: 0.5)
              : colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onPress,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(name, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
