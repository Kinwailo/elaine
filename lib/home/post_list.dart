import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../app/const.dart';
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
    final count = posts.pItems.length;
    final extra = posts.reachEnd ? 0 : 1;
    final controller = useScrollController();
    useListenable(posts.pItems);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight - 12,
        title: SelectionArea(
          child: Text(
            threads.selected?.data.subject ?? '',
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
          physics: ClampingScrollPhysics(),
          slivers: [
            SliverPadding(
              key: centerKey,
              padding: EdgeInsets.only(top: 2, right: 12, bottom: 2),
              sliver: SuperSliverList.builder(
                itemCount: count + extra,
                itemBuilder: (_, index) {
                  return index >= count
                      ? MorePosts(key: UniqueKey())
                      : PostTile(key: ValueKey(posts.pItems[index]), index);
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
    final post = posts.pItems[index];
    useMemoized(() => posts.loadQuote(post), [post.quote.value]);
    useMemoized(() => posts.loadImage(post), [
      ...post.images,
      post.synced.value,
    ]);
    final quote = post.quote.value;
    useListenable(post);
    useListenable(post.quote.value);
    useValueChanged(post.read.value, (_, _) async {
      final threads = Modular.get<ThreadStore>();
      return Future(() => threads.selected?.markRead(index + 1));
    });
    return VisibilityDetector(
      key: key!,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > (56.0 / info.size.height)) {
          post.setVisible(true);
        } else if (info.visibleFraction == 0.0) {
          post.setVisible(false);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 2, right: 4, bottom: 2),
        child: Container(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  PostTileHeadbar(index),
                  if (quote != null) PostTileQuote(quote),
                  if (post.getText().isNotEmpty) PostTileText(index),
                  if (post.images.isNotEmpty) PostTileImages(post),
                ].separator(const SizedBox(height: 8)),
              ),
            ),
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
    final post = posts.pItems[index];
    final GestureRecognizer recognizer = useMemoized(
      () => TapGestureRecognizer()..onTap = () => posts.resync(post),
      [post.error.value],
    );
    useEffect(() => recognizer.dispose, [post.error.value]);
    useListenable(post.error);
    return Text.rich(
      TextSpan(
        children: [
          if (post.syncing.value) ...[
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            WidgetSpan(child: SizedBox(width: 4)),
          ],
          if (post.error.value)
            TextSpan(
              text: post.getText(),
              style: mainTextStyle.merge(errorTextStyle),
              children: [
                WidgetSpan(child: SizedBox(width: 4)),
                TextSpan(
                  text: retryText,
                  recognizer: recognizer,
                  style: mainTextStyle.merge(clickableTextStyle),
                ),
              ],
            )
          else
            post.data.html
                ? WidgetSpan(child: Html(data: post.getText()))
                : TextSpan(text: post.getText(), style: mainTextStyle),
        ],
      ),
    );
  }
}

class PostTileHeadbar extends HookWidget {
  const PostTileHeadbar(this.index, {super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final posts = Modular.get<PostStore>();
    final post = posts.pItems[index];
    return Row(
      children: [
        ...<Widget>[
          Text(post.data.sender, style: senderTextStyle),
          TooltipVisibility(
            visible: post.data.date.relative != post.data.date.format,
            child: Tooltip(
              message: post.data.date.format,
              child: Text(post.data.date.relative, style: subTextStyle),
            ),
          ),
          Spacer(),
          InkWell(
            onTap: () => post.setOriginal(!post.original.value),
            child: Tooltip(
              message: '原文',
              child: Text('📃', style: subTextStyle),
            ),
          ),
          Text('#${index + 1}', style: subTextStyle),
        ].separator(const SizedBox(width: 8)),
      ],
    );
  }
}

class PostTileQuote extends HookWidget {
  const PostTileQuote(this.post, {super.key});

  final PostData post;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  text: '${post.data.sender}: ',
                  style: senderTextStyle,
                  children: [
                    if (post.syncing.value) ...[
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        ),
                      ),
                      WidgetSpan(child: SizedBox(width: 4)),
                    ],
                    TextSpan(
                      text: post.getText(),
                      style: post.error.value ? errorTextStyle : subTextStyle,
                    ),
                  ],
                ),
                maxLines: 3,
              ),
              if (post.images.isNotEmpty) PostTilePreviews(post),
            ],
          ),
        ),
      ],
    );
  }
}

class PostTileImages extends HookWidget {
  const PostTileImages(this.post, {super.key});

  final PostData post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...post.images
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
  const PostTilePreviews(this.post, {super.key});

  final PostData post;

  @override
  Widget build(BuildContext context) {
    useListenable(Listenable.merge(post.images));
    return Wrap(
      children: [
        ...post.images
            .map((e) => e.value)
            .map(
              (e) => e == null
                  ? SizedBox.square(
                      dimension: 64,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Image.memory(e.data, height: 100, fit: BoxFit.cover),
            ),
      ],
    );
  }
}
