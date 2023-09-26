import 'package:datadashwallet/features/dapps/subfeatures/open_dapp/widgets/typed_message_info.dart';
import 'package:flutter/material.dart';
import 'package:mxc_ui/mxc_ui.dart';

Future<bool?> showTypedMessageDialog(
  BuildContext context, {
  String? title,
  required String networkName,
  required String primaryType,
  required Map<String, dynamic> message,
  VoidCallback? onTap,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 44),
      decoration: BoxDecoration(
        color: ColorsTheme.of(context).screenBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MxcAppBarEvenly.title(
            titleText: title ?? '',
            action: Container(
              alignment: Alignment.centerRight,
              child: InkWell(
                child: const Icon(Icons.close),
                onTap: () => Navigator.of(context).pop(false),
              ),
            ),
          ),
          TypeMessageInfo(
            message: message,
            networkName: networkName,
            primaryType: primaryType,
            onTap: onTap,
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}
