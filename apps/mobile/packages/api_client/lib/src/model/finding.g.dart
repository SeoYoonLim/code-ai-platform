// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finding.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Finding extends Finding {
  @override
  final String id;
  @override
  final FindingCategory category;
  @override
  final Severity severity;
  @override
  final String title;
  @override
  final String message;
  @override
  final String path;
  @override
  final int startLine;
  @override
  final int endLine;
  @override
  final String? suggestion;
  @override
  final num? confidence;
  @override
  final FeedbackVerdict? feedback;

  factory _$Finding([void Function(FindingBuilder)? updates]) =>
      (new FindingBuilder()..update(updates))._build();

  _$Finding._(
      {required this.id,
      required this.category,
      required this.severity,
      required this.title,
      required this.message,
      required this.path,
      required this.startLine,
      required this.endLine,
      this.suggestion,
      this.confidence,
      this.feedback})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'Finding', 'id');
    BuiltValueNullFieldError.checkNotNull(category, r'Finding', 'category');
    BuiltValueNullFieldError.checkNotNull(severity, r'Finding', 'severity');
    BuiltValueNullFieldError.checkNotNull(title, r'Finding', 'title');
    BuiltValueNullFieldError.checkNotNull(message, r'Finding', 'message');
    BuiltValueNullFieldError.checkNotNull(path, r'Finding', 'path');
    BuiltValueNullFieldError.checkNotNull(startLine, r'Finding', 'startLine');
    BuiltValueNullFieldError.checkNotNull(endLine, r'Finding', 'endLine');
  }

  @override
  Finding rebuild(void Function(FindingBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FindingBuilder toBuilder() => new FindingBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Finding &&
        id == other.id &&
        category == other.category &&
        severity == other.severity &&
        title == other.title &&
        message == other.message &&
        path == other.path &&
        startLine == other.startLine &&
        endLine == other.endLine &&
        suggestion == other.suggestion &&
        confidence == other.confidence &&
        feedback == other.feedback;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, severity.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, path.hashCode);
    _$hash = $jc(_$hash, startLine.hashCode);
    _$hash = $jc(_$hash, endLine.hashCode);
    _$hash = $jc(_$hash, suggestion.hashCode);
    _$hash = $jc(_$hash, confidence.hashCode);
    _$hash = $jc(_$hash, feedback.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Finding')
          ..add('id', id)
          ..add('category', category)
          ..add('severity', severity)
          ..add('title', title)
          ..add('message', message)
          ..add('path', path)
          ..add('startLine', startLine)
          ..add('endLine', endLine)
          ..add('suggestion', suggestion)
          ..add('confidence', confidence)
          ..add('feedback', feedback))
        .toString();
  }
}

class FindingBuilder implements Builder<Finding, FindingBuilder> {
  _$Finding? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  FindingCategory? _category;
  FindingCategory? get category => _$this._category;
  set category(FindingCategory? category) => _$this._category = category;

  Severity? _severity;
  Severity? get severity => _$this._severity;
  set severity(Severity? severity) => _$this._severity = severity;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  String? _path;
  String? get path => _$this._path;
  set path(String? path) => _$this._path = path;

  int? _startLine;
  int? get startLine => _$this._startLine;
  set startLine(int? startLine) => _$this._startLine = startLine;

  int? _endLine;
  int? get endLine => _$this._endLine;
  set endLine(int? endLine) => _$this._endLine = endLine;

  String? _suggestion;
  String? get suggestion => _$this._suggestion;
  set suggestion(String? suggestion) => _$this._suggestion = suggestion;

  num? _confidence;
  num? get confidence => _$this._confidence;
  set confidence(num? confidence) => _$this._confidence = confidence;

  FeedbackVerdict? _feedback;
  FeedbackVerdict? get feedback => _$this._feedback;
  set feedback(FeedbackVerdict? feedback) => _$this._feedback = feedback;

  FindingBuilder() {
    Finding._defaults(this);
  }

  FindingBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _category = $v.category;
      _severity = $v.severity;
      _title = $v.title;
      _message = $v.message;
      _path = $v.path;
      _startLine = $v.startLine;
      _endLine = $v.endLine;
      _suggestion = $v.suggestion;
      _confidence = $v.confidence;
      _feedback = $v.feedback;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Finding other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Finding;
  }

  @override
  void update(void Function(FindingBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Finding build() => _build();

  _$Finding _build() {
    final _$result = _$v ??
        new _$Finding._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Finding', 'id'),
            category: BuiltValueNullFieldError.checkNotNull(
                category, r'Finding', 'category'),
            severity: BuiltValueNullFieldError.checkNotNull(
                severity, r'Finding', 'severity'),
            title: BuiltValueNullFieldError.checkNotNull(
                title, r'Finding', 'title'),
            message: BuiltValueNullFieldError.checkNotNull(
                message, r'Finding', 'message'),
            path:
                BuiltValueNullFieldError.checkNotNull(path, r'Finding', 'path'),
            startLine: BuiltValueNullFieldError.checkNotNull(
                startLine, r'Finding', 'startLine'),
            endLine: BuiltValueNullFieldError.checkNotNull(
                endLine, r'Finding', 'endLine'),
            suggestion: suggestion,
            confidence: confidence,
            feedback: feedback);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
