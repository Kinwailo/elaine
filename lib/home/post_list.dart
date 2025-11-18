import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../app/string_utils.dart';
import '../app/utils.dart';
import '../services/cloud_service.dart';
import 'home_store.dart';

class PostList extends HookWidget {
  const PostList({super.key});

  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey('centerKey');
    final home = Modular.get<HomeStore>();
    final cloud = Modular.get<CloudService>();
    final count = cloud.posts.length;
    final extra = cloud.noMorePosts ? 0 : 1;
    final controller = useMemoized(() => ScrollController());
    useListenable(cloud.posts);
    useListenable(home.allPostQuoteListenable);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          cloud.currentThread.subject,
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
        child: CustomScrollView(
          center: centerKey,
          controller: controller,
          slivers: [
            SliverPadding(
              key: centerKey,
              padding: EdgeInsets.only(top: 2, right: 12, bottom: 2),
              sliver: SliverVariedExtentList.builder(
                itemCount: count + extra,
                itemBuilder: (_, index) => index >= count
                    ? MorePosts(key: UniqueKey())
                    : PostTile(key: ValueKey(index), index),
                itemExtentBuilder: (index, dimensions) {
                  if (index > count) return null;
                  if (index == count) return 8;
                  final style = DefaultTextStyle.of(context).style;
                  final post = cloud.posts[index];
                  double height = 18;
                  height += estimateTextHeight(
                    post.sender,
                    style.merge(senderTextStyle),
                    maxWidth: dimensions.crossAxisExtent - 40,
                  );
                  height += 8;
                  final quote = home.getPostQuote(index);
                  if (quote.value != null) {
                    height += estimateTextHeight(
                      quote.value!.sender,
                      style.merge(senderTextStyle),
                      maxWidth: dimensions.crossAxisExtent - 40,
                    );
                    height += 8;
                  }
                  height += estimateTextHeight(
                    post.text ?? syncBodyText,
                    style.merge(mainTextStyle),
                    maxWidth: dimensions.crossAxisExtent - 40,
                  );
                  height += 18;
                  return height;
                },
              ),
            ),
          ],
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
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 2, right: 4, bottom: 2),
        child: LinearProgressIndicator(),
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
    final home = Modular.get<HomeStore>();
    final cloud = Modular.get<CloudService>();
    final post = cloud.posts[index];
    final quote = home.getPostQuote(index);
    home.setPostQuote(index, useMemoized(() => cloud.getQuote(index), [post]));
    final files = home.getPostFiles(index);
    home.setPostFiles(
      index,
      useMemoized(() => post.files.map((e) => cloud.getFile(e)).toList(), [
        post,
      ]),
    );
    useListenable(quote);
    useListenable(Listenable.merge(home.getPostFiles(index)));
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
                  Text(post.sender, style: senderTextStyle),
                  const SizedBox(width: 8),
                  TooltipVisibility(
                    visible: post.date.relative != post.date.format,
                    child: Tooltip(
                      message: post.date.format,
                      child: Text(post.date.relative, style: subTextStyle),
                    ),
                  ),
                  Spacer(),
                  Text('#${index + 1}', style: subTextStyle),
                ],
              ),
              const SizedBox(height: 8),
              if (quote.value != null)
                Text(quote.value!.sender, style: senderTextStyle),
              if (quote.value != null) const SizedBox(height: 8),
              if (post.text == null)
                Text(syncBodyText, style: mainTextStyle)
              else if (post.text!.isNotEmpty)
                Text(post.text!.stripAll, style: mainTextStyle),
              if (files.isNotEmpty)
                ...files.map(
                  (e) => e.value == null
                      ? Center(
                          child: SizedBox.square(
                            dimension: 50,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Align(
                          alignment: AlignmentGeometry.centerLeft,
                          child: Image.memory(
                            e.value!,
                            width: 600,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
