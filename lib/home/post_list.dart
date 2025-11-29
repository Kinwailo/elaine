import 'package:collection/collection.dart';
import 'package:elaine/app/const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../app/utils.dart';
import 'post_store.dart';
import 'thread_store.dart';

class PostList extends HookWidget {
  const PostList({super.key});

  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey('centerPost');
    final threads = Modular.get<ThreadStore>();
    final posts = Modular.get<PostStore>();
    final count = posts.posts.length;
    final extra = posts.reachEnd ? 0 : 1;
    final controller = useScrollController();
    useListenable(posts.posts);
    useListenable(posts.allPostsListenable);
    useListenable(posts.allQuotesListenable);
    useListenable(posts.allQuotesTextListenable);
    useListenable(posts.allImagesListenable);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight - 12,
        title: Text(threads.selected.subject, overflow: TextOverflow.ellipsis),
        titleSpacing: 10,
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
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              key: centerKey,
              padding: EdgeInsets.only(top: 2, right: 12, bottom: 2),
              sliver: SliverVariedExtentList.builder(
                itemCount: count + extra,
                itemBuilder: (_, index) {
                  return index >= count
                      ? MorePosts(key: UniqueKey())
                      : PostTile(key: ValueKey(posts.posts[index]), index);
                },
                itemExtentBuilder: (index, dimensions) {
                  if (index > count) return null;
                  if (index == count) return 8;
                  final style = DefaultTextStyle.of(context).style;
                  final post = posts.posts[index];
                  final body = posts.getPostText(post.msgid);
                  final quote = posts.getQuoteNotifier(post.msgid).value;
                  final images = posts.getFilesNotifier(post.msgid)?.value;
                  final qMsgid = quote?.msgid ?? '';
                  final qText = posts.getPostText(qMsgid);
                  final qFiles = posts.getFilesNotifier(qMsgid)?.value;
                  final maxWidth = dimensions.crossAxisExtent - 40;
                  final qMaxWidth = maxWidth - 12.5;

                  double height = 2 + 16;
                  height += [
                    estimateTextHeight(
                      post.sender,
                      style.merge(senderTextStyle),
                      maxWidth: maxWidth,
                    ),
                    if (quote != null)
                      [
                        4,
                        estimateTextHeight(
                          '${quote.sender}：$qText',
                          style.merge(senderTextStyle),
                          maxLines: 3,
                          maxWidth: qMaxWidth,
                        ),
                        if (qFiles?.isNotEmpty ?? false)
                          estimateWrappedHeight(
                            qFiles!
                                .map((e) => e.value)
                                .map(
                                  (e) => e == null
                                      ? 64
                                      : e.size.width * 100 / e.size.height,
                                ),
                            100,
                            qMaxWidth,
                          ),
                        4,
                      ].sum,
                    if (body.isNotEmpty)
                      estimateTextHeight(
                        body,
                        style.merge(mainTextStyle),
                        maxWidth: maxWidth,
                      ),
                    if (images?.isNotEmpty ?? false)
                      images!
                          .map((e) => e.value?.size)
                          .map(
                            (e) => e == null
                                ? 64
                                : [600, e.width, maxWidth].min /
                                      e.width *
                                      e.height,
                          )
                          .sum,
                  ].separator(8).sum;
                  height += 16 + 2;
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
    final posts = Modular.get<PostStore>();
    final loaded = useState(false);
    return VisibilityDetector(
      key: key!,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !loaded.value) {
          loaded.value = true;
          posts.loadMore();
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
    final posts = Modular.get<PostStore>();
    final post = posts.posts[index];
    final text = posts.getPostText(post.msgid);
    final keys = [post.msgid];
    final quote = useMemoized(() => posts.setQuoteNotifier(post.msgid), keys);
    final files = useMemoized(() => posts.setFilesNotifier(post.msgid), keys);
    final qMsgid = quote.value?.msgid ?? '';
    keys.add(qMsgid);
    final qFiles = useMemoized(() => posts.setFilesNotifier(qMsgid), keys);
    useListenable(files);
    useListenable(posts.getPostNotifier(post.msgid));
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2, right: 4, bottom: 2),
      child: Container(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PostTileHeadbar(index),
              if (quote.value != null) PostTileQuote(qMsgid, quote, qFiles),
              if (text.isNotEmpty) PostTileText(index),
              if (files.isNotEmpty) PostTileImages(files),
            ].separator(const SizedBox(height: 8)),
          ),
        ),
      ),
    );
  }
}

class PostTileText extends HookWidget {
  const PostTileText(this.index, {super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final posts = Modular.get<PostStore>();
    final post = posts.posts[index];
    final listen = posts.getPostNotifier(post.msgid);
    final text = posts.getPostText(post.msgid);
    useListenable(listen);
    return listen?.value.text == null
        ? Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                WidgetSpan(child: SizedBox(width: 4)),
                TextSpan(text: syncBodyText, style: mainTextStyle),
              ],
            ),
          )
        : Text(text, style: mainTextStyle);
  }
}

class PostTileHeadbar extends HookWidget {
  const PostTileHeadbar(this.index, {super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final posts = Modular.get<PostStore>();
    final post = posts.posts[index];
    return Row(
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
    );
  }
}

class PostTileQuote extends HookWidget {
  const PostTileQuote(this.msgid, this.quote, this.qFiles, {super.key});

  final String msgid;
  final QuoteNotifier quote;
  final ImageNotifierList qFiles;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final posts = Modular.get<PostStore>();
    final post = posts.getPostNotifier(msgid);
    final text = posts.getPostText(msgid);
    useListenable(post);
    return Column(
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
                    if (post?.value.text == null) ...[
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        ),
                      ),
                      WidgetSpan(child: SizedBox(width: 4)),
                      TextSpan(text: syncBodyText, style: subTextStyle),
                    ],
                    TextSpan(text: text, style: subTextStyle),
                  ],
                ),
                maxLines: 3,
              ),
              if (qFiles.isNotEmpty) PostTilePreviews(qFiles),
            ],
          ),
        ),
      ],
    );
  }
}

class PostTileImages extends HookWidget {
  const PostTileImages(this.images, {super.key});

  final ImageNotifierList images;

  @override
  Widget build(BuildContext context) {
    useListenable(Listenable.merge(images.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...images.value
            .map((e) => e.value)
            .map(
              (e) => e == null
                  ? SizedBox.square(
                      dimension: 64,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Image.memory(
                      e.data,
                      width: e.size.width > 600 ? 600 : null,
                    ),
            ),
      ],
    );
  }
}

class PostTilePreviews extends HookWidget {
  const PostTilePreviews(this.images, {super.key});

  final ImageNotifierList images;

  @override
  Widget build(BuildContext context) {
    useListenable(Listenable.merge(images.value));
    return Wrap(
      children: [
        ...images.value
            .map((e) => e.value)
            .map(
              (e) => e == null
                  ? SizedBox.square(
                      dimension: 64,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Image.memory(e.data, height: 100, fit: BoxFit.cover),
            ),
      ],
    );
  }
}
