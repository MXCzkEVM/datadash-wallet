import 'package:datadashwallet/features/dapps/presentation/dapps_presenter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mxc_logic/mxc_logic.dart';
import 'package:mxc_ui/mxc_ui.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../dapps_state.dart';
import 'card_item.dart';
import 'dapp_loading.dart';
import 'dapp_utils.dart';
import 'new_dapp_card.dart';

class DappCardLayout extends HookConsumerWidget {
  const DappCardLayout({
    super.key,
    this.crossAxisCount = CardCrossAxisCount.mobile,
  });

  final int crossAxisCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appsPagePageContainer.state);
    final actions = ref.read(appsPagePageContainer.actions);
    final dapps = state.orderedDapps;

    if (state.loading && DappUtils.loadingOnce) {
      return DAppLoading(
        crossAxisCount: crossAxisCount,
      );
    }

    if (dapps.isEmpty) return Container();

    return LayoutBuilder(
      builder: (context, constraint) {
        actions.initializeViewPreferences(constraint.maxWidth);
        final itemWidth = actions.getItemWidth();
        return Stack(
          children: [
            ReorderableWrapperWidget(
              child: GridView(
                gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  mainAxisExtent: constraint.maxWidth, 
                ),
                scrollDirection: Axis.horizontal,
                physics: const PageScrollPhysics(),
                controller: actions.scrollController,
                children: getList(dapps, actions, state, itemWidth),
              ),
              // the drag and drop index is from (index passed to ReorderableItemView)
              onReorder: (dragIndex, dropIndex) {
                var item = dapps.removeAt(dragIndex);
                dapps.insert(dropIndex, item);
              },
              onDragUpdate: (dragIndex, position, delta) =>
                  actions.handleOnDragUpdate(position),
            ),
          ],
        );
      },
    );
  }
}

List<Widget> getList(List<Dapp> dapps, DAppsPagePresenter actions,
    DAppsState state, double itemWidth) {
  List<Widget> dappCards = [];

  for (int i = 0; i < dapps.length; i++) {
    final item = dapps[i];
    final dappCard = item is Bookmark
        ? NewDAppCard(
            index: i,
            width: itemWidth,
            dapp: item,
            isEditMode: state.isEditMode,
            onTap: state.isEditMode ? null : () => actions.openDapp(item.url),
            onLongPress: () => actions.changeEditMode(),
            onRemoveTap: (item) => actions.removeBookmark(item as Bookmark),
          )
        : NewDAppCard(
            index: i,
            width: itemWidth,
            dapp: item,
            isEditMode: state.isEditMode,
            onTap: state.isEditMode
                ? null
                : () async {
                    await actions.requestPermissions(item);
                    actions.openDapp(
                      item.app!.url!,
                    );
                  },
            onLongPress: () => actions.changeEditMode(),
            onRemoveTap: null,
          );
    dappCards.add(dappCard);
  }

  return dappCards;
}
