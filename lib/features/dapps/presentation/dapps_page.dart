import 'package:datadashwallet/common/common.dart';
import 'package:datadashwallet/features/dapps/presentation/widgets/default_app_bar.dart';
import 'package:datadashwallet/features/dapps/presentation/widgets/edit_mode_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mxc_ui/mxc_ui.dart';

import 'dapps_presenter.dart';
import 'dapps_state.dart';
import 'responsive_layout/responsive_layout.dart';

class DAppsPage extends HookConsumerWidget {
  const DAppsPage({Key? key}) : super(key: key);

  @override
  ProviderBase<DAppsPagePresenter> get presenter =>
      appsPagePageContainer.actions;

  @override
  ProviderBase<DAppsState> get state => appsPagePageContainer.state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dappsPresenter = ref.watch(presenter);
    return MxcPage(
      layout: LayoutType.column,
      useContentPadding: false,
      childrenPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.spaceSmall, vertical: Sizes.spaceNormal),
      backgroundGradient: const LinearGradient(
        colors: [
          Color(0xFF0E1629),
          Color(0xFF333333),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      presenter: ref.watch(presenter),
      appBar: Column(
        children: [
          ref.watch(state).isEditMode
              ? const EditModeAppBar()
              : const DefaultAppBar(),
        ],
      ),
      children: const [
        Expanded(
          child: Center(
            child: ResponsiveLayout(),
          ),
        )
      ],
    );
  }
}
