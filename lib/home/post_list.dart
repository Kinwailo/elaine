import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../app/string_utils.dart';
import '../app/utils.dart';
import '../services/cloud_service.dart';

class PostList extends HookWidget {
  const PostList({super.key});

  @override
  Widget build(BuildContext context) {
    final cloud = Modular.get<CloudService>();
    final count = cloud.posts.length;
    final extra = cloud.noMorePosts ? 0 : 1;
    final controller = useMemoized(() => ScrollController());
    useListenable(cloud.posts);
    useListenable(cloud.currentThread);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          cloud.currentThread['subject'] ?? '',
          overflow: TextOverflow.ellipsis,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 8,
        child: ListView.builder(
          controller: controller,
          padding: EdgeInsets.only(top: 2, right: 12, bottom: 2),
          itemCount: count + extra,
          itemBuilder: (_, index) => index >= count
              ? MorePosts(key: UniqueKey())
              : PostTile(key: ValueKey(index), index),
        ),
      ),
    );
  }
}

class MorePosts extends HookWidget {
  const MorePosts({super.key});

  @override
  Widget build(BuildContext context) {
    final appwrite = Modular.get<CloudService>();
    final loaded = useState(false);
    return VisibilityDetector(
      key: key!,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !loaded.value) {
          loaded.value = true;
          appwrite.loadMorePosts();
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

class PostTile extends HookWidget {
  const PostTile(this.index, {super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cloud = Modular.get<CloudService>();
    final post = cloud.posts.value[index];
    final date = DateTime.parse(
      post['date'] ?? DateTime.fromMillisecondsSinceEpoch(0).toString(),
    ).toLocal();
    final text = ((post['text'] ?? '') as String).stripAll;
    final quote = useMemoized(() => futureToNotifier(cloud.getQuote(index)), [
      post,
    ]);
    final files = useMemoized(
      () => ((post['files'] ?? []) as List)
          .map((e) => cloud.getFile(e))
          .map((e) => futureToNotifier(e))
          .toList(),
      [post],
    );
    useListenable(quote);
    useListenable(Listenable.merge(files));
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2, right: 4, bottom: 2),
      child: Container(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    ((post['sender'] ?? 'Null') as String).trim(),
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
                  Text(
                    '#${index + 1}',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (quote.value != null)
                Text(
                  ((quote.value!['sender'] ?? 'Null') as String).trim(),
                  style: TextStyle(fontSize: 18),
                ),
              if (quote.value != null) const SizedBox(height: 8),
              if (post['text'] == null)
                Text('文章正從新聞組同步中…', style: TextStyle(fontSize: 18))
              else if (text.isNotEmpty)
                Text(text, style: TextStyle(fontSize: 18)),
              if (files.isNotEmpty)
                ...files.map(
                  (e) => e.value == null
                      ? Center(
                          child: SizedBox.square(
                            dimension: 50,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Image.memory(e.value!, fit: BoxFit.cover),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
