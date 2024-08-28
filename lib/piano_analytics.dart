import 'package:flutter/services.dart';
import 'package:piano_analytics/piano_consents.dart';

enum PianoAnalyticsVisitorIDType {
  uuid("UUID"),
  adid("ADID");

  final String value;

  const PianoAnalyticsVisitorIDType(this.value);
}

class Property {
  final String _name;
  final dynamic _value;

  Property.bool({required String name, required bool value})
      : _name = name,
        _value = value;

  Property.int({required String name, required int value})
      : _name = name,
        _value = value;

  Property.double({required String name, required double value})
      : _name = name,
        _value = value;

  Property.string({required String name, required String value})
      : _name = name,
        _value = value;

  Property.date({required String name, required DateTime value})
      : _name = name,
        _value = value;

  Property.intArray({required String name, required List<int> value})
      : _name = name,
        _value = value;

  Property.doubleArray({required String name, required List<double> value})
      : _name = name,
        _value = value;

  Property.stringArray({required String name, required List<String> value})
      : _name = name,
        _value = value;
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
          ? {for (var property in _properties) property._name: property._value}
          : null
    };
  }
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
      PianoAnalyticsVisitorIDType visitorIDType =
          PianoAnalyticsVisitorIDType.uuid,
      PianoConsents? consents,
      MethodChannel? channel})
      : _parameters = {
          "site": site,
          "collectDomain": collectDomain,
          "visitorIDType": visitorIDType.value
        },
        _channel = channel ?? _pianoAnalyticsChannel;

  Future<void> init() async {
    await _channel.invokeMethod<void>("init", _parameters);
    _initialized = true;
  }

  Future<void> sendEvents({required List<Event> events}) async {
    _checkInit();
    await _channel.invokeMethod(
        "send", {"events": events.map((event) => event.toMap()).toList()});
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
