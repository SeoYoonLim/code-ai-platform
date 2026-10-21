// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finding_feedback.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FindingFeedback extends FindingFeedback {
  @override
  final FeedbackVerdict verdict;
  @override
  final String? comment;
  @override
  final String? editedSuggestion;

  factory _$FindingFeedback([void Function(FindingFeedbackBuilder)? updates]) =>
      (new FindingFeedbackBuilder()..update(updates))._build();

  _$FindingFeedback._(
      {required this.verdict, this.comment, this.editedSuggestion})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        verdict, r'FindingFeedback', 'verdict');
  }

  @override
  FindingFeedback rebuild(void Function(FindingFeedbackBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FindingFeedbackBuilder toBuilder() =>
      new FindingFeedbackBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FindingFeedback &&
        verdict == other.verdict &&
        comment == other.comment &&
        editedSuggestion == other.editedSuggestion;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, verdict.hashCode);
    _$hash = $jc(_$hash, comment.hashCode);
    _$hash = $jc(_$hash, editedSuggestion.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FindingFeedback')
          ..add('verdict', verdict)
          ..add('comment', comment)
          ..add('editedSuggestion', editedSuggestion))
        .toString();
  }
}

class FindingFeedbackBuilder
    implements Builder<FindingFeedback, FindingFeedbackBuilder> {
  _$FindingFeedback? _$v;

  FeedbackVerdict? _verdict;
  FeedbackVerdict? get verdict => _$this._verdict;
  set verdict(FeedbackVerdict? verdict) => _$this._verdict = verdict;

  String? _comment;
  String? get comment => _$this._comment;
  set comment(String? comment) => _$this._comment = comment;

  String? _editedSuggestion;
  String? get editedSuggestion => _$this._editedSuggestion;
  set editedSuggestion(String? editedSuggestion) =>
      _$this._editedSuggestion = editedSuggestion;

  FindingFeedbackBuilder() {
    FindingFeedback._defaults(this);
  }

  FindingFeedbackBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _verdict = $v.verdict;
      _comment = $v.comment;
      _editedSuggestion = $v.editedSuggestion;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FindingFeedback other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$FindingFeedback;
  }

  @override
  void update(void Function(FindingFeedbackBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FindingFeedback build() => _build();

  _$FindingFeedback _build() {
    final _$result = _$v ??
        new _$FindingFeedback._(
            verdict: BuiltValueNullFieldError.checkNotNull(
                verdict, r'FindingFeedback', 'verdict'),
            comment: comment,
            editedSuggestion: editedSuggestion);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
