import 'package:flutter/material.dart';
import 'package:mxc_ui/mxc_ui.dart';

class RecipientItem extends StatelessWidget {
  const RecipientItem({
    super.key,
    required this.name,
    required this.address,
    this.onTap,
  });

  final String name;
  final String address;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: FontTheme.of(context).body1.primary().copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    address,
                    style: FontTheme.of(context).subtitle1().copyWith(
                          color: ColorsTheme.of(context).white200,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ColorsTheme.of(context).white400,
            ),
          ],
        ),
      ),
    );
  }
}
