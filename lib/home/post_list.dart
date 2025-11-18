import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../app/utils.dart';
import 'home_store.dart';

class PostList extends HookWidget {
  const PostList({super.key});

  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey('centerKey');
    final home = Modular.get<HomeStore>();
    final count = home.posts.length;
    final extra = home.noMorePosts ? 0 : 1;
    final controller = useMemoized(() => ScrollController());
    useListenable(home.posts);
    useListenable(home.allQuotesListenable);
    useListenable(home.allImagesListenable);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          home.currentThread.subject,
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
                itemBuilder: (_, index) {
                  return index >= count
                      ? MorePosts(key: UniqueKey())
                      : PostTile(key: ValueKey(home.posts[index]), index);
                },
                itemExtentBuilder: (index, dimensions) {
                  if (index > count) return null;
                  if (index == count) return 8;
                  final style = DefaultTextStyle.of(context).style;
                  final post = home.posts[index];
                  double height = 18;
                  height += estimateTextHeight(
                    post.sender,
                    style.merge(senderTextStyle),
                    maxWidth: dimensions.crossAxisExtent - 40,
                  );
                  height += 8;
                  final quote = home.getQuoteNotifier(post.msgid);
                  if (quote.value != null) {
                    height += estimateTextHeight(
                      '${quote.value!.sender}: ${quote.value?.text ?? syncBodyText}',
                      style.merge(senderTextStyle),
                      maxWidth: dimensions.crossAxisExtent - 40,
                    );
                    height += 8;
                    final qFiles = home.getFilesNotifier(quote.value!.msgid);
                    if (qFiles.isNotEmpty) {
                      height += 100;
                    }
                    height += 8;
                  }
                  height += estimateTextHeight(
                    post.text ?? syncBodyText,
                    style.merge(mainTextStyle),
                    maxWidth: dimensions.crossAxisExtent - 40,
                  );
                  final images = home.getFilesNotifier(post.msgid);
                  if (images.isNotEmpty) {
                    height +=
                        images.map((e) => e.value?.size ?? Size(50, 50)).map((
                          e,
                        ) {
                          if (e.width <= 600) {
                            return e.height;
                          } else {
                            return 600.0 / e.width * e.height;
                          }
                        }).sum -
                        25;
                  }
                  height += 18 - 2;
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
    final home = Modular.get<HomeStore>();
    final loaded = useState(false);
    return VisibilityDetector(
      key: key!,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !loaded.value) {
          loaded.value = true;
          home.loadMorePosts();
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
    final post = home.posts[index];
    final keys = [post];
    final quote = useMemoized(() => home.setQuoteNotifier(post.msgid), keys);
    final files = useMemoized(() => home.setFilesNotifier(post.msgid), keys);
    final qMsgid = quote.value?.msgid ?? '';
    final qFiles = useMemoized(() => home.setFilesNotifier(qMsgid), keys);
    useListenable(quote);
    useListenable(Listenable.merge(files));
    useListenable(Listenable.merge(qFiles));
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsetsGeometry.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        border: Border(
                          left: BorderSide(
                            color: colorScheme.tertiaryFixedDim,
                            width: 4,
                            style: BorderStyle.solid,
                          ),
                          right: BorderSide(
                            color: colorScheme.tertiaryFixedDim,
                            width: 0.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: '${quote.value!.sender}: ',
                              style: senderTextStyle,
                              children: [
                                TextSpan(
                                  text: quote.value!.text ?? syncBodyText,
                                  style: subTextStyle,
                                ),
                              ],
                            ),
                            maxLines: 3,
                          ),
                          if (qFiles.isNotEmpty)
                            ...qFiles.map(
                              (e) => e.value == null
                                  ? SizedBox.square(
                                      dimension: 50,
                                      child: CircularProgressIndicator(),
                                    )
                                  : Image.memory(
                                      e.value!.data,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              if (quote.value != null) const SizedBox(height: 8),
              if (post.text == null)
                Text(syncBodyText, style: mainTextStyle)
              else if (post.text!.isNotEmpty)
                Text(post.text!, style: mainTextStyle),
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
                            e.value!.data,
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
