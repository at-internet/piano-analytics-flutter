import 'package:flutter/services.dart';
import 'package:piano_analytics/enums.dart';

class Property {
  final String _name;
  final dynamic _value;
  final PropertyType? _forceType;

  Property.bool(
      {required String name, required bool value, PropertyType? forceType})
      : _name = name,
        _value = value,
        _forceType = forceType;

  Property.int(
      {required String name, required int value, PropertyType? forceType})
      : _name = name,
        _value = value,
        _forceType = forceType;

  Property.double(
      {required String name, required double value, PropertyType? forceType})
      : _name = name,
        _value = value,
        _forceType = forceType;

  Property.string(
      {required String name, required String value, PropertyType? forceType})
      : _name = name,
        _value = value,
        _forceType = forceType;

  Property.date(
      {required String name, required DateTime value, PropertyType? forceType})
      : _name = name,
        _value = value,
        _forceType = forceType;

  Property.intArray(
      {required String name, required List<int> value, PropertyType? forceType})
      : _name = name,
        _value = value,
        _forceType = forceType;

  Property.doubleArray(
      {required String name,
      required List<double> value,
      PropertyType? forceType})
      : _name = name,
        _value = value,
        _forceType = forceType;

  Property.stringArray(
      {required String name,
      required List<String> value,
      PropertyType? forceType})
      : _name = name,
        _value = value,
        _forceType = forceType;
}

class Event {
  final String _name;
  final List<Property>? _properties;

  Event({required String name, List<Property>? properties})
      : _name = name,
        _properties = properties;

  Map<String, dynamic> toMap() {
    return {
      "name": _name,
      "data": _properties != null
          ? {
              for (var property in _properties)
                property._name: {
                  "value": property._value,
                  "forceType": property._forceType?.value
                }
            }
          : null
    };
  }
}

class User {
  final String id;
  final String? category;

  User({required this.id, this.category});
}

class PianoAnalytics {
  static final _pianoAnalyticsChannel = MethodChannel(
      "piano_analytics", StandardMethodCodec(PianoAnalyticsMessageCodec()));

  final Map<String, dynamic> _parameters;
  final MethodChannel _channel;

  bool _initialized = false;

  PianoAnalytics(
      {required int site,
      required String collectDomain,
      VisitorIDType visitorIDType = VisitorIDType.uuid,
      int? storageLifetimeVisitor,
      VisitorStorageMode? visitorStorageMode,
      bool? ignoreLimitedAdvertisingTracking,
      String? visitorId,
      Map<String,String>? headers,
      Map<String,String>? query,
      MethodChannel? channel})
      : _parameters = {
          "site": site,
          "collectDomain": collectDomain,
          "visitorIDType": visitorIDType.value,
          "storageLifetimeVisitor": storageLifetimeVisitor,
          "visitorStorageMode": visitorStorageMode?.value,
          "ignoreLimitedAdvertisingTracking": ignoreLimitedAdvertisingTracking,
          "visitorId": visitorId,
          "headers": headers,
          "query": query
        },
        _channel = channel ?? _pianoAnalyticsChannel;

  Future<void> init() async {
    await _channel.invokeMethod<void>("init", _parameters);
    _initialized = true;
  }

  Future<void> setHeader(
      {required String key, required String? value}) async {
    await _channel.invokeMethod("setHeader",
        {"key": key, "value": value});
  }

  Future<void> setQuery(
      {required String key, required String? value}) async {
    await _channel.invokeMethod("setQuery",
        {"key": key, "value": value});
  }

  Future<void> sendEvents({required List<Event> events}) async {
    _checkInit();
    await _channel.invokeMethod(
        "send", {"events": events.map((event) => event.toMap()).toList()});
  }

  Future<User?> getUser() async {
    _checkInit();
    var user = await _channel.invokeMethod("getUser") as Map<Object?, Object?>?;
    if (user == null) {
      return null;
    }
    return User(
        id: user["id"] as String, category: user["category"] as String?);
  }

  Future<void> setUser(
      {required String id, String? category, bool enableStorage = true}) async {
    _checkInit();
    await _channel.invokeMethod("setUser",
        {"id": id, "category": category, "enableStorage": enableStorage});
  }

  Future<void> deleteUser() async {
    _checkInit();
    await _channel.invokeMethod("deleteUser");
  }

  Future<String?> getVisitorId() async {
    _checkInit();
    return await _channel.invokeMethod("getVisitorId") as String?;
  }

  Future<void> setVisitorId({required String visitorId}) async {
    _checkInit();
    await _channel.invokeMethod("setVisitorId", {"visitorId": visitorId});
  }

  Future<void> privacyIncludeStorageFeatures(
      {required List<PrivacyStorageFeature> features,
      required List<PrivacyMode> modes}) async {
    _checkInit();
    await _channel.invokeMethod("privacyIncludeStorageFeatures", {
      "features": features.map((feature) => feature.value).toList(),
      "modes": modes.map((mode) => mode.value).toList()
    });
  }

  Future<void> privacyExcludeStorageFeatures(
      {required List<PrivacyStorageFeature> features,
      required List<PrivacyMode> modes}) async {
    _checkInit();
    await _channel.invokeMethod("privacyExcludeStorageFeatures", {
      "features": features.map((feature) => feature.value).toList(),
      "modes": modes.map((mode) => mode.value).toList()
    });
  }

  Future<void> privacyIncludeProperties(
      {required List<String> propertyNames,
      required List<PrivacyMode> modes,
      List<String>? eventNames}) async {
    _checkInit();
    await _channel.invokeMethod("privacyIncludeProperties", {
      "propertyNames": propertyNames,
      "modes": modes.map((mode) => mode.value).toList(),
      "eventNames": eventNames
    });
  }

  Future<void> privacyExcludeProperties(
      {required List<String> propertyNames,
      required List<PrivacyMode> modes,
      List<String>? eventNames}) async {
    _checkInit();
    await _channel.invokeMethod("privacyExcludeProperties", {
      "propertyNames": propertyNames,
      "modes": modes.map((mode) => mode.value).toList(),
      "eventNames": eventNames
    });
  }

  Future<void> privacyIncludeEvents(
      {required List<String> eventNames,
      required List<PrivacyMode> modes}) async {
    _checkInit();
    await _channel.invokeMethod("privacyIncludeEvents", {
      "eventNames": eventNames,
      "modes": modes.map((mode) => mode.value).toList()
    });
  }

  Future<void> privacyExcludeEvents(
      {required List<String> eventNames,
      required List<PrivacyMode> modes}) async {
    _checkInit();
    await _channel.invokeMethod("privacyExcludeEvents", {
      "eventNames": eventNames,
      "modes": modes.map((mode) => mode.value).toList()
    });
  }

  void _checkInit() {
    if (!_initialized) {
      throw Error.safeToString("PianoAnalytics not initialized");
    }
  }
}

class PianoAnalyticsMessageCodec extends StandardMessageCodec {
  static const int dateType = 128;

  @override
  void writeValue(WriteBuffer buffer, dynamic value) {
    if (value is DateTime) {
      buffer.putUint8(dateType);
      buffer.putInt64(value.microsecondsSinceEpoch);
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    if (type == dateType) {
      return DateTime.fromMicrosecondsSinceEpoch(buffer.getInt64());
    }
    return super.readValueOfType(type, buffer);
  }
}
