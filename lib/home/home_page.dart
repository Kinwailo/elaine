import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../services/appwrite.dart';
import '../services/cloud_service.dart';
import 'home_store.dart';
import 'thread_list.dart';
import 'post_list.dart';

class HomeModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<CloudService>(AppWrite.new);
    i.addSingleton(HomeStore.new);
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
            final home = Modular.get<HomeStore>();
            final group = r.args.params['group'];
            if (group != null) home.selectGroups([group]);
            return ThreadList();
          },
          transition: TransitionType.noTransition,
          children: [
            ChildRoute(
              '/:thread',
              child: (_) {
                final home = Modular.get<HomeStore>();
                final group = r.args.params['group'];
                final number = int.tryParse(r.args.params['thread']);
                if (group != null && number != null) {
                  home.selectThread(group, number);
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
      child: Stack(
        children: [
          Row(
            children: [
              SizedBox(width: 80),
              Expanded(
                child: Scaffold(
                  key: scaffoldKey,
                  drawer: Drawer(),
                  body: const RouterOutlet(),
                ),
              ),
            ],
          ),
          SizedBox(
            width: 80,
            child: NavigationRail(
              backgroundColor: colorScheme.surfaceContainer,
              selectedIndex: null,
              labelType: NavigationRailLabelType.none,
              leading: IconButton(
                onPressed: () {
                  scaffoldKey.currentState?.openDrawer();
                },
                icon: const Icon(Icons.add),
              ),
              trailing: FilterChipItem(),
              destinations: [],
            ),
          ),
        ],
      ),
    );
  }
}

class FilterChipItem extends HookWidget {
  const FilterChipItem({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipTheme = Theme.of(context).chipTheme;
    final name = useState('chat');
    final enabled = useState(false);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      color: enabled.value
          ? colorScheme.secondaryContainer
          : chipTheme.selectedColor,
      shadowColor: colorScheme.shadow,
      shape: StadiumBorder(
        side: BorderSide(
          color: enabled.value
              ? colorScheme.surface.withValues(alpha: 0.12)
              : colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        onTap: () => enabled.value = !enabled.value,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(name.value),
        ),
      ),
    );
  }
}
