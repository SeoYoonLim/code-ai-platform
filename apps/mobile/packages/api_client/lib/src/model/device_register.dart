//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/platform.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'device_register.g.dart';

/// DeviceRegister
///
/// Properties:
/// * [fcmToken] 
/// * [platform] 
/// * [appVersion] 
/// * [locale] 
@BuiltValue()
abstract class DeviceRegister implements Built<DeviceRegister, DeviceRegisterBuilder> {
  @BuiltValueField(wireName: r'fcm_token')
  String get fcmToken;

  @BuiltValueField(wireName: r'platform')
  Platform get platform;
  // enum platformEnum {  android,  ios,  };

  @BuiltValueField(wireName: r'app_version')
  String? get appVersion;

  @BuiltValueField(wireName: r'locale')
  String? get locale;

  DeviceRegister._();

  factory DeviceRegister([void updates(DeviceRegisterBuilder b)]) = _$DeviceRegister;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeviceRegisterBuilder b) => b
      ..locale = 'ko-KR';

  @BuiltValueSerializer(custom: true)
  static Serializer<DeviceRegister> get serializer => _$DeviceRegisterSerializer();
}

class _$DeviceRegisterSerializer implements PrimitiveSerializer<DeviceRegister> {
  @override
  final Iterable<Type> types = const [DeviceRegister, _$DeviceRegister];

  @override
  final String wireName = r'DeviceRegister';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeviceRegister object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'fcm_token';
    yield serializers.serialize(
      object.fcmToken,
      specifiedType: const FullType(String),
    );
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(Platform),
    );
    if (object.appVersion != null) {
      yield r'app_version';
      yield serializers.serialize(
        object.appVersion,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.locale != null) {
      yield r'locale';
      yield serializers.serialize(
        object.locale,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DeviceRegister object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeviceRegisterBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'fcm_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fcmToken = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Platform),
          ) as Platform;
          result.platform = valueDes;
          break;
        case r'app_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.appVersion = valueDes;
          break;
        case r'locale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.locale = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeviceRegister deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeviceRegisterBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

