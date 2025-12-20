import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:linkify/linkify.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../app/const.dart';
import '../app/string_utils.dart';
import '../app/utils.dart';
import '../widgets/app_link.dart';
import '../widgets/show_more_box.dart';
import 'group_store.dart';
import 'post_store.dart';
import 'thread_store.dart';

class PostList extends HookWidget {
  const PostList({super.key});

  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey('centerPost');
    final threads = Modular.get<ThreadStore>();
    final posts = Modular.get<PostStore>();
    final countBackward = posts.nItems.length;
    final extraBackward = posts.reachStart ? 0 : 1;
    final countForward = posts.pItems.length;
    final extraForward = posts.reachEnd ? 0 : 1;
    final scrollController = useScrollController();
    final nListController = useMemoized(() => ListController());
    final pListController = useMemoized(() => ListController());
    useListenable(posts.nItems);
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
        controller: scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 8,
        child: CustomScrollView(
          center: centerKey,
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            if (countBackward + extraBackward > 0)
              SliverPadding(
                padding: EdgeInsets.only(top: 4, left: 4, right: 12 + 4),
                sliver: SuperSliverList.separated(
                  listController: nListController,
                  itemCount: countBackward + extraBackward,
                  separatorBuilder: (_, _) => SizedBox(height: 4),
                  itemBuilder: (_, index) {
                    return index >= countBackward
                        ? MorePosts(key: UniqueKey(), prepend: true)
                        : PostTile(
                            key: ValueKey(posts.nItems[index]),
                            posts.nItems[index],
                          );
                  },
                ),
              ),
            SliverPadding(
              key: centerKey,
              padding: EdgeInsets.only(
                top: 4,
                bottom: 4,
                left: 4,
                right: 12 + 4,
              ),
              sliver: SuperSliverList.separated(
                listController: pListController,
                itemCount: countForward + extraForward,
                separatorBuilder: (_, _) => SizedBox(height: 4),
                itemBuilder: (_, index) {
                  return index >= countForward
                      ? MorePosts(key: UniqueKey())
                      : PostTile(
                          key: ValueKey(posts.pItems[index]),
                          posts.pItems[index],
                        );
                },
              ),
            ),
            if (posts.pItems.isNotEmpty && posts.reachEnd)
              SliverToBoxAdapter(
                child: Align(
                  alignment: AlignmentGeometry.topCenter,
                  child: SizedBox(
                    height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton.filledTonal(
                          onPressed: posts.refresh,
                          icon: Icon(Icons.refresh),
                        ),
                        IconButton.filledTonal(
                          onPressed: () {
                            if (posts.index == 0) {
                              final listController = posts.nItems.isEmpty
                                  ? pListController
                                  : nListController;
                              listController.animateToItem(
                                index: 0,
                                scrollController: scrollController,
                                alignment: 0,
                                duration: (_) => 0.1.seconds,
                                curve: (_) => Curves.easeInOut,
                              );
                            } else {
                              final threads = Modular.get<ThreadStore>();
                              final group = threads.selected?.data.group ?? '';
                              final number = threads.selected?.data.number ?? 0;
                              Modular.to.pushNamedAndRemoveUntil(
                                '/$group/$number',
                                ModalRoute.withName('/$group/'),
                              );
                            }
                          },
                          icon: Icon(Icons.arrow_upward),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MorePosts extends HookWidget {
  const MorePosts({super.key, this.prepend = false, this.post});

  final bool prepend;
  final PostData? post;

  @override
  Widget build(BuildContext context) {
    final posts = Modular.get<PostStore>();
    final loaded = useState(false);
    return VisibilityDetector(
      key: key!,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !loaded.value) {
          loaded.value = true;
          post == null
              ? posts.loadMore(reverse: prepend)
              : posts.loadReply(post!);
        }
      },
      child: LinearProgressIndicator(),
    );
  }
}

class PostTile extends HookWidget {
  const PostTile(this.post, {super.key});

  final PostData post;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final groups = Modular.get<GroupStore>();
    final threads = Modular.get<ThreadStore>();
    final posts = Modular.get<PostStore>();
    useMemoized(() => posts.loadQuote(post), [post.quote.value]);
    useMemoized(() => posts.loadImage(post), [
      ...post.images,
      post.synced.value,
    ]);
    useMemoized(() => posts.processLink(post), [
      ...post.urls,
      post.synced.value,
    ]);
    final quote = post.quote.value;

    final group = groups.get(threads.selected?.data.group ?? '');
    final lastRefresh = group?.lastRefresh ?? refDateTime;
    final isUnread = posts.read > 0 && post.data.index >= posts.read;
    final isNew =
        isUnread &&
        posts.read > 0 &&
        posts.read < (threads.selected?.data.total ?? 0) &&
        (post.data.date.isAfter(lastRefresh) ||
            post.data.create.isAfter(lastRefresh));

    final blend = post.level == 0
        ? Colors.transparent
        : Colors.primaries[post.level * 2 % Colors.primaries.length];
    final color = posts.selected == post
        ? colorScheme.secondaryContainer.withValues(alpha: 0.3).blend(blend)
        : colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5)
              .blend(blend);

    useListenable(post);
    useListenable(post.quote.value);
    useValueChanged(post.read, (_, _) async {
      final threads = Modular.get<ThreadStore>();
      return Future(
        () => posts.postMode.value
            ? threads.selected?.markIndexRead(post.data.index)
            : threads.selected?.markRead(post.data.index + 1),
      );
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
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: !isNew && !isUnread
              ? null
              : Border(
                  left: BorderSide(
                    color: isNew ? newColor : unreadColor,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ShowMoreBox(
                maxHeight: 600,
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      PostTileHeadbar(post),
                      if (quote != null) PostTileQuote(quote),
                      if (post.getText().isNotEmpty) PostTileText(post),
                      if (post.images.isNotEmpty) PostTileImages(post),
                    ].separator(const SizedBox(height: 8)),
                  ),
                ),
              ),
            ),
            if (post.folded)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: <Widget>[
                    ...post.children.map((e) => PostTile(key: ValueKey(e), e)),
                    if (post.children.length < post.data.total)
                      MorePosts(key: UniqueKey(), post: post),
                  ].separator(const SizedBox(height: 4)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PostTileText extends HookWidget {
  const PostTileText(this.post, {super.key});

  final PostData post;

  @override
  Widget build(BuildContext context) {
    final posts = Modular.get<PostStore>();
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
            ),
          // else
          //   post.data.html
          //       ? WidgetSpan(child: Html(data: post.getText()))
          //       : TextSpan(text: post.getText(), style: mainTextStyle),
          if (!post.error.value) ...linkifyTextSpan(context, post),
        ],
      ),
    );
  }
}

List<InlineSpan> linkifyTextSpan(BuildContext context, PostData post) {
  final opt = const LinkifyOptions(humanize: false);
  final linkifies = linkify(post.getText(), options: opt);
  final spans = linkifies.expand((e) {
    if (e is! LinkableElement) {
      return [TextSpan(text: e.text, style: mainTextStyle)];
    }
    if (e is EmailElement) {
      return [TextSpan(text: e.text, style: mainTextStyle)];
    }

    final link = post.getLink(e.url);
    final nonNulls = [link?.title, link?.desc, link?.image].nonNulls;
    if (link == null || nonNulls.isEmpty) {
      return [
        if (link == null)
          const WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              padding: EdgeInsets.only(right: 4),
              child: SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          WidgetSpan(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: link.icon == null
                  ? Icon(Icons.link, size: 16)
                  : Image.memory(
                      link.icon!.data,
                      height: 16,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        TextSpan(
          text: e.url.decodeUrl,
          style: mainTextStyle.merge(clickableTextStyle),
          recognizer: TapGestureRecognizer()
            ..onTap = () => launchUrlString(e.url),
        ),
      ];
    } else if (nonNulls.isNotEmpty && nonNulls.first == link.image) {
      var maxWidth = 600.0;
      return [
        WidgetSpan(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Image.memory(
              link.image!.data,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ];
    } else {
      return [WidgetSpan(child: PostTileLinkCard(link))];
    }
  });
  return spans.cast<InlineSpan>().toList();
}

class PostTileLinkCard extends HookWidget {
  const PostTileLinkCard(this.link, {super.key});

  final LinkData link;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    var desc = link.desc ?? '';
    desc += link.image == null ? '' : '\n\n\n';
    return Card(
      color: colorScheme.surfaceContainerHighest,
      margin: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: link.image == null
            ? null
            : const {0: FixedColumnWidth(108)},
        children: [
          TableRow(
            children: [
              if (link.image != null)
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.fill,
                  child: Image.memory(
                    link.image!.data,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              InkWell(
                onTap: () => launchUrlString(link.url),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Ink(
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (link.icon != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Image.memory(
                                link.icon!.data,
                                height: 16,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 3,
                            ),
                            child: Text(
                              link.title ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: subTextStyle.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (desc.isNotEmpty || link.image != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          desc,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: subTextStyle,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      child: Text(
                        link.url.decodeUrl,
                        maxLines: 1,
                        style: subTextStyle.merge(clickableTextStyle),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PostTileHeadbar extends HookWidget {
  const PostTileHeadbar(this.post, {super.key});

  final PostData post;

  @override
  Widget build(BuildContext context) {
    final threads = Modular.get<ThreadStore>();
    final thread = threads.selected?.data;
    final group = thread?.group ?? '';
    final number = thread?.number ?? 0;
    final index = post.data.index + 1;
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
          Tooltip(
            message: '原文',
            child: InkWell(
              onTap: () => post.toggleOriginal(),
              child: Text('📃', style: subTextStyle),
            ),
          ),
          AlignRightSizedBox(
            width: 64,
            show: post.data.total > 0 && thread != null,
            child: AppLink(
              root: group,
              paths: ['$number', 'post', '$index'],
              child: PostTileReplyState(post),
            ),
          ),
          AlignRightSizedBox(
            width: 32,
            show: thread != null,
            child: AppLink(
              root: group,
              paths: ['$number', '$index'],
              child: Text('#$index', style: subTextStyle),
            ),
          ),
        ].separator(const SizedBox(width: 8)),
      ],
    );
  }
}

class PostTileReplyState extends HookWidget {
  const PostTileReplyState(this.post, {super.key});

  final PostData post;

  @override
  Widget build(BuildContext context) {
    final posts = Modular.get<PostStore>();
    final selected = posts.selected?.data;
    final showExpand =
        posts.postMode.value &&
        selected?.msgid != post.data.msgid &&
        !(selected?.ref.contains(post.data.msgid) ?? false);
    return Text.rich(
      TextSpan(
        children: [
          if (showExpand)
            WidgetSpan(
              child: Tooltip(
                message: uiExpand,
                child: InkWell(
                  onTap: () => posts.toggleExpand(post),
                  child: Icon(
                    post.folded
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    size: 16,
                  ),
                ),
              ),
            ),
          TextSpan(text: '🗨️${post.data.total}', style: subTextStyle),
        ],
      ),
    );
  }
}

class AlignRightSizedBox extends StatelessWidget {
  const AlignRightSizedBox({
    super.key,
    this.width,
    this.show = true,
    this.child,
  });

  final double? width;
  final bool show;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: !show
          ? null
          : Align(alignment: AlignmentGeometry.centerRight, child: child),
    );
  }
}

class PostTileQuote extends HookWidget {
  const PostTileQuote(this.post, {super.key});

  final PostData post;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final posts = Modular.get<PostStore>();
    useMemoized(() => posts.loadImage(post), [
      ...post.images,
      post.synced.value,
    ]);
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
          child: ShowMoreBox.mini(
            maxHeight: 100,
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
                ),
                if (post.images.isNotEmpty) PostTilePreviews(post),
              ],
            ),
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
