import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:text_span_thousands/highlight_text/lib/cupertino/cupertino_selection_handle.dart';
import 'package:text_span_thousands/highlight_text/lib/material/material_selection_controllers.dart';
import 'package:text_span_thousands/highlight_text/lib/text_selection_controls.dart';

class SelectedData {
  int baseOffset;
  int extentOffset;

  SelectedData({this.baseOffset, this.extentOffset});
}

class RichTextController extends ChangeNotifier {
  List<TextSpan> _source;

  /// containing the user selection
  List<TextSelection> _selected = [];

  RichTextController(this._source);

  /// call when user choose highlight from the menu
  void addSelection(TextSelection selection) {
    _selected.add(selection);
    getSourceAfterSelected();
    notifyListeners();
  }

  void getSourceAfterSelected() {
    // 1. make a empty variable, which will be returned after the manipulation
    List<TextSpan> res = [];

    // 2. begin the manipulation...
    // 2.1. because we can just directly manipulate the source, we'd better made a copy of it
    res.addAll(_source);

    // 2.2 change the part of the source where it's selected(based on _selected)
    final newestSelection = _selected.last;
    int loopStart = newestSelection.baseOffset;
    int loopEnd = newestSelection.extentOffset;

    for (int highlightIndex = loopStart;
        highlightIndex < loopEnd;
        highlightIndex++) {
      //TODO find out why this doesn't work as expected
      // res[highlightIndex].style.copyWith(backgroundColor: Colors.amberAccent);
      res[highlightIndex] = TextSpan(
        text: res[highlightIndex].text,
        style: TextStyle(
          fontWeight: res[highlightIndex].style?.fontWeight,
          fontStyle: res[highlightIndex].style?.fontStyle,
          backgroundColor: Colors.amberAccent,
        ),
      );
    }

    //3. set the result
    _source = res;
  }

  List<TextSpan> get renderingData => _source;

  List<TextSelection> get selectedText => _selected;
}

class HighlightText extends StatefulWidget {
  /// rendering text, represented as a list of TextSpan
  final List<TextSpan> spans;

  /// function to react when user tap on the highlighted text
  final Function onHighlightedText;

  /// function to react when user choose highlight from the toolbar
  final Function highlightText;

  /// default highlighted text
  final List<SelectedData> defaultHighlightedText;

  /// function to react when user tap on the default highlighted text
  final Function onDefaultHighlightedText;

  const HighlightText({
    Key key,
    this.spans,
    this.onHighlightedText,
    this.highlightText,
    this.defaultHighlightedText,
    this.onDefaultHighlightedText,
  }) : super(key: key);

  @override
  _HighlightTextState createState() => _HighlightTextState();
}

class _HighlightTextState extends State<HighlightText> {
  RichTextController richTextController;

  List<TextSelectionToolbarItem> selectionToolBarItems;

  @override
  void initState() {
    richTextController = RichTextController(widget.spans);

    richTextController.addListener(updateRichText);

    selectionToolBarItems = [
      TextSelectionToolbarItem(
        onPressed: (selectionController) {
          final selection = selectionController.selection;

          print('baseOffset = ${selection.baseOffset}');
          print('extentOffset = ${selection.extentOffset}');

          if (widget.highlightText != null) {
            widget.highlightText(selectionController.selection);
          }

          richTextController.addSelection(selection);
        },
        title: Text('Highlight'),
      ),
      TextSelectionToolbarItem.copy(),
    ];

    super.initState();
  }

  updateRichText() {
    setState(() {
      // Notify rich text changes
    });
  }

  @override
  void didUpdateWidget(HighlightText oldWidget) {
    super.didUpdateWidget(oldWidget);

    //TODO: ASK @Jaime what this does
    if (widget.spans != oldWidget.spans) {
      // richTextController.removeListener(updateRichText);
      // richTextController.dispose();

      //TODO: ...find a way to resolve this
      // richTextController = RichTextController(widget.text);
      // richTextController.addListener(updateRichText);
    }
  }

  @override
  void dispose() {
    richTextController.removeListener(updateRichText);
    richTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(children: richTextController.renderingData),
      cursorColor: Colors.black,
      toolbarOptions: ToolbarOptions(copy: true),
      selectionControls: DefaultTextSelectionControls(
        handle: CupertinoTextSelectionHandle(color: Colors.black),
        toolbar: MaterialSelectionToolbar(
          items: selectionToolBarItems,
          theme: ThemeData.dark(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      onSelectionChanged: (selection, cause) {
        // 1. get the base of the selection, which will be the indication of the
        // tapping point we want to compare if it's fall in the range of one of our selection
        int tappingPoint = selection.baseOffset;

        final selectedText = richTextController.selectedText;

        final defaultSelectedText = widget.defaultHighlightedText;

        // 2. go through the selection we collected and see if it fall in one of the range in the selection
        for (int i = 0; i < selectedText.length; i++) {
          if (tappingPoint >= selectedText[i].baseOffset &&
              tappingPoint <= selectedText[i].extentOffset) {
            // print(selectedText[i]);

            widget.onHighlightedText(selectedText[i]);
          }
        }

        if (defaultSelectedText != null) {
          for (int i = 0; i < defaultSelectedText.length; i++) {
            if (tappingPoint >= defaultSelectedText[i].baseOffset &&
                tappingPoint <= defaultSelectedText[i].extentOffset) {
              widget.onDefaultHighlightedText(defaultSelectedText[i]);
            }
          }
        }
      },
    );
  }
}
