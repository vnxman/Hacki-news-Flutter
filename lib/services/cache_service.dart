import 'package:hacki/models/models.dart' show Comment;
import 'package:rxdart/rxdart.dart';

class CacheService {
  static final Map<int, Comment> _comments = <int, Comment>{};
  static final Map<int, String> _drafts = <int, String>{};
  static final Map<int, Set<int>> _kids = <int, Set<int>>{};
  static final Set<int> _collapsed = <int>{};
  static final Map<int, Set<int>> _hidden = <int, Set<int>>{};
  final PublishSubject<Map<int, Set<int>>> _hiddenCommentsSubject =
      PublishSubject<Map<int, Set<int>>>();

  Stream<Map<int, Set<int>>> get hiddenComments =>
      _hiddenCommentsSubject.stream;

  void addKid(int commentId, {required int to}) {
    _kids[to] = <int>{...?_kids[to], commentId};
    addIfParentIsHiddenOrCollapsed(commentId, to);
  }

  int collapse(int commentId) {
    _collapsed.add(commentId);

    Set<int> findHiddenComments(int commentId) {
      final Set<int> directKids = <int>{...?_kids[commentId]};
      final Set<int> temp = <int>{...directKids};

      for (final int i in temp) {
        directKids.addAll(findHiddenComments(i));
      }

      return directKids;
    }

    final Set<int> hiddenComments = findHiddenComments(commentId);

    _hidden[commentId] = hiddenComments;

    _hiddenCommentsSubject.add(_hidden);

    return hiddenComments.length;
  }

  void uncollapse(int commentId) {
    _collapsed.remove(commentId);

    _hidden.remove(commentId);

    _hiddenCommentsSubject.add(_hidden);
  }

  bool isHidden(int commentId) {
    for (final Set<int> val in _hidden.values) {
      if (val.contains(commentId)) return true;
    }
    return false;
  }

  void addIfParentIsHiddenOrCollapsed(int commentId, int parentId) {
    for (final int key in _hidden.keys) {
      if (key == parentId || (_hidden[key]?.contains(parentId) ?? false)) {
        _hidden[key]?.add(commentId);
        _hiddenCommentsSubject.add(_hidden);
        return;
      }
    }
  }

  void resetCollapsedComments() {
    _kids.clear();
    _collapsed.clear();
    _hidden.clear();
    _hiddenCommentsSubject.add(_hidden);
  }

  bool isCollapsed(int commentId) => _collapsed.contains(commentId);

  int totalHidden(int commentId) => _hidden[commentId]?.length ?? 0;

  void cacheComment(Comment comment) => _comments[comment.id] = comment;

  Comment? getComment(int id) => _comments[id];

  void resetComments() {
    _comments.clear();
  }

  void removeDraft({required int replyingTo}) => _drafts.remove(replyingTo);

  void cacheDraft({required String text, required int replyingTo}) =>
      _drafts[replyingTo] = text;

  String? getDraft({required int replyingTo}) => _drafts[replyingTo];
}
