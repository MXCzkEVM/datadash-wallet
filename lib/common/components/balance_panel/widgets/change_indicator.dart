import 'package:datadashwallet/features/home/home/home_page_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mxc_ui/mxc_ui.dart';

import '../../../common.dart';

class ChangeIndicator extends HookConsumerWidget {
  const ChangeIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenter = ref.read(homeContainer.actions);
    final state = ref.watch(homeContainer.state);
    return state.changeIndicator != null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                state.changeIndicator!.isNegative
                    ? MXCIcons.decrease
                    : MXCIcons.increase,
                color: state.changeIndicator!.isNegative
                    ? ColorsTheme.of(context).systemStatusInActive
                    : ColorsTheme.of(context).systemStatusActive,
                size: 16,
              ),
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: ' ${state.changeIndicator!.toStringAsFixed(2)}%',
                    style: FontTheme.of(context).h7().copyWith(
                          color: state.changeIndicator!.isNegative
                              ? ColorsTheme.of(context).systemStatusInActive
                              : ColorsTheme.of(context).systemStatusActive,
                        )),
                TextSpan(
                    text: '   ${FlutterI18n.translate(context, 'today')}',
                    style: FontTheme.of(context).h7().copyWith(
                        color: ColorsTheme.of(context)
                            .textPrimary
                            .withOpacity(0.32))),
              ]))
            ],
          )
        : Container();
  }
}
