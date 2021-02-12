import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

import '../util/util.dart';
import 'ui.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({
    Key key,
  }) : super(key: key);

  @override
  _LanguagePageState createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> with SingleTickerProviderStateMixin {
  static const double _horizontalHeight = 96;
  static const List<String> options = [
    'Shuffle',
    'Test',
  ];

  final List<Language> selectedLanguages = [
    english,
    german,
    spanish,
    french,
  ];

  bool inReorder = false;

  ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  void onReorderFinished(List<Language> newItems) {
    scrollController.jumpTo(scrollController.offset);
    setState(() {
      inReorder = false;

      selectedLanguages
        ..clear()
        ..addAll(newItems);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examples'),
        backgroundColor: theme.accentColor,
        actions: <Widget>[
          _buildPopupMenuButton(textTheme),
        ],
      ),
      body: ListView(
        controller: scrollController,
        // Prevent the ListView from scrolling when an item is
        // currently being dragged.
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          _buildHeadline('Vertically'),
          const Divider(height: 0),
          _buildVerticalLanguageList(),
          _buildHeadline('Horizontally'),
          _buildHorizontalLanguageList(),
          const SizedBox(height: 500),
        ],
      ),
    );
  }

  // * An example of a vertically reorderable list.
  Widget _buildVerticalLanguageList() {
    final theme = Theme.of(context);

    Widget buildReorderable(
      Language lang,
      Widget Function(Widget tile) transition,
    ) {
      return Reorderable(
        key: ValueKey(lang),
        builder: (context, dragAnimation, inDrag) => AnimatedBuilder(
          animation: dragAnimation,
          builder: (context, child) {
            final tile = Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildTile(lang),
                const Divider(height: 0),
              ],
            );

            return AnimatedBuilder(
              child: tile,
              animation: dragAnimation,
              builder: (context, tile) {
                final t = dragAnimation.value;
                final color = Color.lerp(Colors.white, Colors.grey.shade100, t);

                return Box(
                  color: color,
                  elevation: lerpDouble(0, 8, t),
                  child: transition(tile),
                );
              },
            );
          },
        ),
      );
    }

    return ImplicitlyAnimatedReorderableList<Language>(
      items: selectedLanguages,
      shrinkWrap: true,
      reorderDuration: const Duration(milliseconds: 200),
      liftDuration: const Duration(milliseconds: 300),
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
      onReorderStarted: (item, index) => setState(() => inReorder = true),
      onReorderFinished: (movedLanguage, from, to, newItems) {
        // Update the underlying data when the item has been reordered!
        onReorderFinished(newItems);
      },
      itemBuilder: (context, itemAnimation, lang, index) {
        return buildReorderable(lang, (tile) {
          return SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            animation: itemAnimation,
            child: tile,
          );
        });
      },
      updateItemBuilder: (context, itemAnimation, lang) {
        return buildReorderable(lang, (tile) {
          return FadeTransition(
            opacity: itemAnimation,
            child: tile,
          );
        });
      },
      footer: _buildFooter(context, theme.textTheme),
    );
  }

  Widget _buildHorizontalLanguageList() {
    return Container(
      height: _horizontalHeight,
      alignment: Alignment.center,
      child: ImplicitlyAnimatedReorderableList<Language>(
        items: selectedLanguages,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
        insertDuration: const Duration(milliseconds: 1000),
        removeDuration: const Duration(milliseconds: 1000),
        onReorderStarted: (item, index) => setState(() => inReorder = true),
        onReorderFinished: (item, from, to, newItems) => onReorderFinished(newItems),
        itemBuilder: (context, itemAnimation, item, index) {
          return Reorderable(
            key: ValueKey(item.toString()),
            builder: (context, dragAnimation, inDrag) {
              final t = dragAnimation.value;
              final box = _buildBox(item, t);

              return SizeFlipTransition(
                animation: itemAnimation,
                axis: Axis.horizontal,
                axisAlignment: 1.0,
                curve: Curves.ease,
                child: box,
              );
            },
          );
        },
        updateItemBuilder: (context, itemAnimation, item) {
          return Reorderable(
            key: ValueKey(item.toString()),
            child: FadeTransition(
              opacity: itemAnimation,
              child: _buildBox(item, 0),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTile(Language lang) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final List<Widget> actions = [
      SlideAction(
        closeOnTap: true,
        color: Colors.redAccent,
        onTap: () => setState(() => selectedLanguages.remove(lang)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.delete,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Text(
                'Delete',
                style: textTheme.bodyText2.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return Slidable(
      actionPane: const SlidableBehindActionPane(),
      actions: actions,
      secondaryActions: actions,
      child: Container(
        alignment: Alignment.center,
        // For testing different size item. You can comment this line
        padding: lang.englishName == 'English'
            ? const EdgeInsets.symmetric(vertical: 16.0)
            : EdgeInsets.zero,
        child: ListTile(
          title: Text(
            lang.nativeName,
            style: textTheme.bodyText2.copyWith(
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            lang.englishName,
            style: textTheme.bodyText1.copyWith(
              fontSize: 15,
            ),
          ),
          leading: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                '${selectedLanguages.indexOf(lang) + 1}',
                style: textTheme.bodyText2.copyWith(
                  color: theme.accentColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          trailing: const Handle(
            delay: Duration(milliseconds: 0),
            capturePointer: true,
            child: Icon(
              Icons.drag_handle,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBox(Language item, double t) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final elevation = lerpDouble(0, 8, t);

    return Handle(
      delay: const Duration(milliseconds: 500),
      child: Box(
        height: _horizontalHeight,
        borderRadius: 8,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        elevation: elevation,
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        margin: const EdgeInsets.only(right: 8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                item.nativeName,
                style: textTheme.bodyText2,
              ),
              const SizedBox(height: 8),
              Text(
                item.englishName,
                style: textTheme.bodyText1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, TextTheme textTheme) {
    return Box(
      color: Colors.white,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LanguageSearchPage(),
          ),
        );

        if (result != null && !selectedLanguages.contains(result)) {
          setState(() {
            selectedLanguages.add(result);
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const SizedBox(
              height: 36,
              width: 36,
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Colors.grey,
                ),
              ),
            ),
            title: Text(
              'Add a language',
              style: textTheme.bodyText1.copyWith(
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 0),
        ],
      ),
    );
  }

  Widget _buildHeadline(String headline) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    Widget buildDivider() => Container(
          height: 2,
          color: Colors.grey.shade300,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 16),
        buildDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            headline,
            style: textTheme.bodyText1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        buildDivider(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPopupMenuButton(TextTheme textTheme) {
    return PopupMenuButton<String>(
      padding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onSelected: (value) {
        switch (value) {
          case 'Shuffle':
            setState(selectedLanguages.shuffle);
            break;
          case 'Test':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TestPage(),
              ),
            );
            break;
        }
      },
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(
          value: option,
          child: Text(
            option,
            style: textTheme.bodyText1,
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

class Pair<A, B> {
  final A first;
  final B second;
  Pair(
    this.first,
    this.second,
  );
}
