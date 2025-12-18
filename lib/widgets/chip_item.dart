import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ChipItem extends HookWidget {
  const ChipItem(
    this.name, {
    super.key,
    this.selected = false,
    this.selectable = false,
    this.onPress,
    this.onSelect,
  });

  final String name;
  final bool selected;
  final bool selectable;
  final void Function()? onPress;
  final bool Function(bool value)? onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final select = useState(selected);
    useValueChanged(selected, (_, _) => select.value = selected);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: select.value
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
      shadowColor: colorScheme.shadow,
      shape: StadiumBorder(
        side: BorderSide(
          color: select.value
              ? colorScheme.secondary.withValues(alpha: 0.5)
              : colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: !selectable
            ? onPress
            : () {
                select.value = !select.value;
                select.value = onSelect?.call(select.value) ?? select.value;
              },
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Text(name, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
