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
                  final quote = home.getQuoteNotifier(post.msgid);
                  final images = home.getFilesNotifier(post.msgid);
                  final qFiles = home.getFilesNotifier(
                    quote.value?.msgid ?? '',
                  );
                  final maxWidth = dimensions.crossAxisExtent - 40;
                  final qMaxWidth = maxWidth - 12.5;

                  double height = 2 + 16;
                  height += [
                    estimateTextHeight(
                      post.sender,
                      style.merge(senderTextStyle),
                      maxWidth: maxWidth,
                    ),
                    if (quote.value != null)
                      [
                        4,
                        estimateTextHeight(
                          '${quote.value!.sender}: ${quote.value?.text ?? syncBodyText}',
                          style.merge(senderTextStyle),
                          maxLines: 3,
                          maxWidth: qMaxWidth,
                        ),
                        if (qFiles.isNotEmpty)
                          estimateWrappedHeight(
                            qFiles
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
                    if (post.text?.isNotEmpty ?? true)
                      estimateTextHeight(
                        post.text ?? syncBodyText,
                        style.merge(mainTextStyle),
                        maxWidth: maxWidth,
                      ),
                    if (images.isNotEmpty)
                      images
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
    final keys = [post.msgid];
    final quote = useMemoized(() => home.setQuoteNotifier(post.msgid), keys);
    final files = useMemoized(() => home.setFilesNotifier(post.msgid), keys);
    final qMsgid = quote.value?.msgid ?? '';
    keys.add(qMsgid);
    final qFiles = useMemoized(() => home.setFilesNotifier(qMsgid), keys);
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
              if (quote.value != null) PostTileQuote(quote, qFiles),
              if (post.text?.isNotEmpty ?? true) PostTileText(index),
              if (files.isNotEmpty) PostTileImages(files),
            ].separator(const SizedBox(height: 8)),
          ),
        ),
      ),
    );
  }
}

class PostTileText extends StatelessWidget {
  const PostTileText(this.index, {super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final home = Modular.get<HomeStore>();
    final post = home.posts[index];
    return post.text == null
        ? Text(syncBodyText, style: mainTextStyle)
        : Text(post.text!, style: mainTextStyle);
  }
}

class PostTileHeadbar extends HookWidget {
  const PostTileHeadbar(this.index, {super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final home = Modular.get<HomeStore>();
    final post = home.posts[index];
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
  const PostTileQuote(this.quote, this.qFiles, {super.key});

  final NullablePostNotifier quote;
  final ImageNotifierList qFiles;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    useListenable(quote);
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
                    TextSpan(
                      text: quote.value!.text ?? syncBodyText,
                      style: subTextStyle,
                    ),
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
    useListenable(Listenable.merge(images));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...images
            .map((e) => e.value)
            .map(
              (e) => e == null
                  ? SizedBox.square(
                      dimension: 64,
                      child: CircularProgressIndicator(),
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
    useListenable(Listenable.merge(images));
    return Wrap(
      children: [
        ...images
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
                  : Image.memory(e.data, height: 100, fit: BoxFit.cover),
            ),
      ],
    );
  }
}
