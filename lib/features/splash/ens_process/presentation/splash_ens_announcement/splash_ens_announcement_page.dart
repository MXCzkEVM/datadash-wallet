import 'package:datadashwallet/common/common.dart';
import 'package:datadashwallet/core/core.dart';
import 'package:datadashwallet/features/home/home.dart';
import 'package:datadashwallet/features/splash/ens_process/ens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mxc_ui/mxc_ui.dart';

import '../widgets/address_bar.dart';
import '../widgets/cube_bar.dart';
import '../widgets/subdomain_bar.dart';
import 'splash_ens_announcement_presenter.dart';

class SplashENSAnnouncementPage extends HookConsumerWidget {
  const SplashENSAnnouncementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenter = ref.read(splashENSAnnouncementContainer.actions);

    return MxcPage(
      layout: LayoutType.scrollable,
      useSplashBackground: true,
      presenter: presenter,
      appBar: MxcAppBar(
        text: '',
        action: MxcAppBarButton.text(
          FlutterI18n.translate(context, 'skip'),
          onTap: () {
            Navigator.of(context).replaceAll(
              route(const HomePage()),
            );
          },
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: MxcButton.primary(
          key: const ValueKey('chooseMyUsernameButton'),
          title: FlutterI18n.translate(context, 'choose_my_username'),
          onTap: () => Navigator.of(context).push(
            route(
              const SplashENSQueryPage(),
            ),
          ),
        ),
      ),
      children: [
        Image(
          image: ImagesTheme.of(context).mxc,
          width: 61,
          height: 68,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            FlutterI18n.translate(context, 'mxc_zkevm_username'),
            style: FontTheme.of(context).h4.white(),
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          FlutterI18n.translate(context, 'ens_announcement_description'),
          style: FontTheme.of(context).body1.white(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const AddressBar(),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SvgPicture.asset(
            'assets/svg/splash/down_arrow.svg',
            height: 25,
          ),
        ),
        const SubDomainBar(),
      ],
    );
  }
}