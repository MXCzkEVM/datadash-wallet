import 'package:datadashwallet/core/core.dart';
import 'package:favicon/favicon.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mxc_ui/mxc_ui.dart';
import 'package:mxc_logic/mxc_logic.dart';
import '../domain/bookmark_use_case.dart';

final addBookmarkPageContainer = PresenterContainer<AddBookmarkPresenter, void>(
    () => AddBookmarkPresenter());

class AddBookmarkPresenter extends CompletePresenter<void> {
  AddBookmarkPresenter() : super(null);

  late final BookmarkUseCase _bookmarksUseCase =
      ref.read(bookmarksUseCaseProvider);
  late final TextEditingController urlController = TextEditingController();

  Future<void> onSave() async {
    String url = urlController.text;
    url = url.contains('https') || url.contains('http') ? url : 'https://$url';
    loading = true;

    try {
      final response = await http.get(Uri.parse(url));
      final startIndex = response.body.indexOf('<title>');
      final endIndex = response.body.indexOf('</title>');
      String title = startIndex == -1 || endIndex == -1
          ? ''
          : response.body.substring(startIndex + 7, endIndex);

      if (startIndex == -1 || title.isEmpty) {
        title = 'Unknown';
      }

      var iconUrl = await FaviconFinder.getBest(url);

      _bookmarksUseCase.addItem(Bookmark(
        id: DateTime.now().microsecondsSinceEpoch,
        title: title,
        url: url,
        image: iconUrl?.url,
      ));

      BottomFlowDialog.of(context!).close();
    } catch (e, s) {
      addError(e, s);
    } finally {
      loading = false;
    }
  }
}
