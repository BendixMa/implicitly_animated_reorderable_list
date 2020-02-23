import 'package:flutter/foundation.dart';

import '../src.dart';

// This implementation of the MyersDiff algorithm was originally written by David Bota
// over here https://gitlab.com/otsoaUnLoco/animated-stream-list.

class _DiffArguments<E> {
  final List<E> oldList;
  final List<E> newList;

  _DiffArguments(this.oldList, this.newList);
}

class DiffUtil<E> {
  static ItemDiffUtil eq;
  static ItemDiffUtil cq;

  static const int ISOLATE_THRESHOLD = 1500;

  static Future<List<Diff>> withCallback<E>(DiffCallback<E> cb) {
    return diff<E>(cb.newList, cb.oldList, areItemsTheSame: cb.areItemsTheSame);
  }

  static Future<List<Diff>> diff<E>(
    List<E> newList,
    List<E> oldList, {
    @required ItemDiffUtil<E> areItemsTheSame,
  }) {
    eq = areItemsTheSame;
    cq = areItemsTheSame;

    final args = _DiffArguments<E>(oldList, newList);

    // We can significantly improve the performance by not spawning a new
    // isolate for shorter lists.
    if ((newList.length * oldList.length) > ISOLATE_THRESHOLD) {
      return compute(_myersDiff, args);
    }

    return Future.value(_myersDiff(args));
  }
}

List<Diff> _myersDiff<E>(_DiffArguments<E> args) {
  final List<E> oldList = args.oldList;
  final List<E> newList = args.newList;

  if (oldList == null) throw ArgumentError('oldList is null');
  if (newList == null) throw ArgumentError('newList is null');

  if (oldList == newList) return [];

  final oldSize = oldList.length;
  final newSize = newList.length;

  if (oldSize == 0) {
    return [Insertion(0, newSize, newList)];
  }

  if (newSize == 0) {
    return [Deletion(0, oldSize)];
  }

  final equals = DiffUtil.eq != null ? DiffUtil.eq : (a, b) => a == b;
  final path = _buildPath(oldList, newList, equals);
  final diffs = _buildPatch(path, oldList, newList)..sort();
  return diffs.reversed.toList(growable: true);
}

PathNode _buildPath<E>(List<E> oldList, List<E> newList, ItemDiffUtil<E> equals) {
  final oldSize = oldList.length;
  final newSize = newList.length;

  final int max = oldSize + newSize + 1;
  final int size = (2 * max) + 1;
  final int middle = size ~/ 2;
  final List<PathNode> diagonal = List(size);

  diagonal[middle + 1] = Snake(0, -1, null);
  for (int d = 0; d < max; d++) {
    for (int k = -d; k <= d; k += 2) {
      final int kmiddle = middle + k;
      final int kplus = kmiddle + 1;
      final int kminus = kmiddle - 1;
      PathNode prev;

      int i;
      if ((k == -d) || (k != d && diagonal[kminus].originIndex < diagonal[kplus].originIndex)) {
        i = diagonal[kplus].originIndex;
        prev = diagonal[kplus];
      } else {
        i = diagonal[kminus].originIndex + 1;
        prev = diagonal[kminus];
      }

      diagonal[kminus] = null;

      int j = i - k;

      PathNode node = DiffNode(i, j, prev);

      while (i < oldSize && j < newSize && equals(oldList[i], newList[j])) {
        i++;
        j++;
      }

      if (i > node.originIndex) {
        node = Snake(i, j, node);
      }

      diagonal[kmiddle] = node;

      if (i >= oldSize && j >= newSize) {
        return diagonal[kmiddle];
      }
    }
    diagonal[middle + d - 1] = null;
  }

  throw Exception();
}

List<Diff> _buildPatch<E>(PathNode path, List<E> oldList, List<E> newList) {
  if (path == null) throw ArgumentError('path is null');

  final List<Diff> diffs = [];

  if (path.isSnake) {
    // ignore: parameter_assignments
    path = path.previousNode;
  }

  while (path != null && path.previousNode != null && path.previousNode.revisedIndex >= 0) {
    if (path.isSnake) throw Exception();

    final i = path.originIndex;
    final j = path.revisedIndex;

    // ignore: parameter_assignments
    path = path.previousNode;
    final iAnchor = path.originIndex;
    final jAnchor = path.revisedIndex;

    final List<E> original = oldList.sublist(iAnchor, i);
    final List<E> revised = newList.sublist(jAnchor, j);

    if (original.isEmpty && revised.isNotEmpty) {
      diffs.add(Insertion(iAnchor, revised.length, revised));
    } else if (original.isNotEmpty && revised.isEmpty) {
      diffs.add(Deletion(iAnchor, original.length));
    } else {
      diffs.add(Modification(iAnchor, original.length, revised));
    }

    if (path.isSnake) {
      // ignore: parameter_assignments
      path = path.previousNode;
    }
  }

  return diffs;
}
