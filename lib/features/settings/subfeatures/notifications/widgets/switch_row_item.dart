import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:mxc_ui/mxc_ui.dart';

class SwitchRowItem extends StatelessWidget {
  final String title;
  final bool value;
  final void Function(bool)? onChanged;
  final bool enabled;
  final Widget? textTrailingWidget;
  final EdgeInsets? paddings;
  final Color? switchActiveColor;
  const SwitchRowItem(
      {super.key,
      required this.title,
      required this.value,
      this.onChanged,
      required this.enabled,
      this.textTrailingWidget,
      this.paddings,
      this.switchActiveColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: paddings ?? EdgeInsets.zero,
      child: Row(
        children: [
          Text(
            title,
            style: FontTheme.of(context).body2.primary(),
          ),
          if (textTrailingWidget != null) ...[
            const SizedBox(
              width: Sizes.spaceXSmall,
            ),
            textTrailingWidget!
          ],
          const Spacer(),
          const SizedBox(
            width: Sizes.spaceNormal,
          ),
          CupertinoSwitch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: switchActiveColor,
          ),
        ],
      ),
    );
  }
}
