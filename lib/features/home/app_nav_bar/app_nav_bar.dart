import 'package:datadashwallet/common/common.dart';
import 'package:datadashwallet/common/layout/layout.dart';
import 'package:datadashwallet/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mxc_ui/mxc_ui.dart';

import 'app_nav_bar_presenter.dart';
import 'app_nav_bar_state.dart';

class AppNavBar extends HookConsumerWidget {
  const AppNavBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenter = ref.read(appNavBarContainer.actions);
    final state = ref.watch(appNavBarContainer.state);

    return PresenterHooks(
      presenter: presenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MxcCircleButton.icon(
              key: const Key("burgerMenuButton"),
              icon: Icons.menu_rounded,
              iconSize: 30,
              onTap: () {},
              color: ColorsTheme.of(context).primaryText,
              iconFillColor: Colors.transparent,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: ColorsTheme.of(context).white.withOpacity(0.16),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(30)),
                      ),
                      child: Row(
                        children: [
                          MXCDropDown<String>(
                            itemList: const ["MXC zkEVM"],
                            onChanged: (String? newValue) {},
                            selectedItem: "MXC zkEVM",
                            icon: const Padding(
                              padding: EdgeInsetsDirectional.only(start: 10),
                            ),
                          ),
                          Container(
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(
                                color:
                                    ColorsTheme.of(context).systemStatusActive,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(FlutterI18n.translate(context, 'online'),
                              style:
                                  FontTheme.of(context).caption1.secondary()),
                        ],
                      ),
                    ),
                    MXCDropDown<String>(
                      itemList: state.accounts
                          .map((i) => Formatter.formatWalletAddress(i))
                          .toList(),
                      onChanged: (String? value) =>
                          presenter.onAccountChange(value!),
                      selectedItem:
                          Formatter.formatWalletAddress(state.currentAccount),
                      textStyle: FontTheme.of(context).subtitle1(),
                      icon: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 0),
                        child: Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 32,
                          color: ColorsTheme.of(context).purpleMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            MxcCircleButton.icon(
              key: const Key("appsButton"),
              icon: MXCIcons.dapps,
              iconSize: 30,
              onTap: () {},
              color: ColorsTheme.of(context).primaryText,
              iconFillColor: ColorsTheme.of(context).secondaryBackground,
            ),
          ],
        ),
      ),
    );
  }
}
