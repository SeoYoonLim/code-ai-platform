// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_register.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeviceRegister extends DeviceRegister {
  @override
  final String fcmToken;
  @override
  final Platform platform;
  @override
  final String? appVersion;
  @override
  final String? locale;

  factory _$DeviceRegister([void Function(DeviceRegisterBuilder)? updates]) =>
      (new DeviceRegisterBuilder()..update(updates))._build();

  _$DeviceRegister._(
      {required this.fcmToken,
      required this.platform,
      this.appVersion,
      this.locale})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        fcmToken, r'DeviceRegister', 'fcmToken');
    BuiltValueNullFieldError.checkNotNull(
        platform, r'DeviceRegister', 'platform');
  }

  @override
  DeviceRegister rebuild(void Function(DeviceRegisterBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceRegisterBuilder toBuilder() =>
      new DeviceRegisterBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceRegister &&
        fcmToken == other.fcmToken &&
        platform == other.platform &&
        appVersion == other.appVersion &&
        locale == other.locale;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fcmToken.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, appVersion.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeviceRegister')
          ..add('fcmToken', fcmToken)
          ..add('platform', platform)
          ..add('appVersion', appVersion)
          ..add('locale', locale))
        .toString();
  }
}

class DeviceRegisterBuilder
    implements Builder<DeviceRegister, DeviceRegisterBuilder> {
  _$DeviceRegister? _$v;

  String? _fcmToken;
  String? get fcmToken => _$this._fcmToken;
  set fcmToken(String? fcmToken) => _$this._fcmToken = fcmToken;

  Platform? _platform;
  Platform? get platform => _$this._platform;
  set platform(Platform? platform) => _$this._platform = platform;

  String? _appVersion;
  String? get appVersion => _$this._appVersion;
  set appVersion(String? appVersion) => _$this._appVersion = appVersion;

  String? _locale;
  String? get locale => _$this._locale;
  set locale(String? locale) => _$this._locale = locale;

  DeviceRegisterBuilder() {
    DeviceRegister._defaults(this);
  }

  DeviceRegisterBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fcmToken = $v.fcmToken;
      _platform = $v.platform;
      _appVersion = $v.appVersion;
      _locale = $v.locale;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeviceRegister other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$DeviceRegister;
  }

  @override
  void update(void Function(DeviceRegisterBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeviceRegister build() => _build();

  _$DeviceRegister _build() {
    final _$result = _$v ??
        new _$DeviceRegister._(
            fcmToken: BuiltValueNullFieldError.checkNotNull(
                fcmToken, r'DeviceRegister', 'fcmToken'),
            platform: BuiltValueNullFieldError.checkNotNull(
                platform, r'DeviceRegister', 'platform'),
            appVersion: appVersion,
            locale: locale);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
