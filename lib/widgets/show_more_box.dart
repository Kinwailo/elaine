import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../app/const.dart';

class ShowMoreBox extends HookWidget {
  const ShowMoreBox({super.key, required this.maxHeight, required this.child})
    : mini = false;
  const ShowMoreBox.mini({
    super.key,
    required this.maxHeight,
    required this.child,
  }) : mini = true;

  final bool mini;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final more =
        scrollController.hasClients &&
        scrollController.position.viewportDimension >= maxHeight;
    if (more) scrollController.jumpTo(0);
    final showMore = useState(false);
    final text = showMore.value ? uiShowLess : uiShowMore;
    useListenable(scrollController);
    return Stack(
      alignment: AlignmentGeometry.bottomCenter,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: showMore.value ? double.infinity : maxHeight,
          ),
          child: ScrollConfiguration(
            behavior: MaterialScrollBehavior().copyWith(scrollbars: false),
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [
                    more && !showMore.value
                        ? mini
                              ? 0.5
                              : 0.8
                        : 1.0,
                    1.0,
                  ],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: showMore.value
                        ? mini
                              ? 18
                              : 48
                        : 0,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
        if (more || showMore.value)
          Padding(
            padding: EdgeInsets.only(bottom: mini ? 0 : 8),
            child: mini
                ? InkWell(
                    onTap: () => showMore.value = !showMore.value,
                    child: Text(
                      text,
                      style: miniTextStyle.merge(clickableTextStyle),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () => showMore.value = !showMore.value,
                    child: Text(text),
                  ),
          ),
      ],
    );
  }
}
