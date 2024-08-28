import 'package:flutter/services.dart';

enum PianoConsentProduct {
  pa("PA"),
  dmp("DMP"),
  composer("COMPOSER"),
  id("ID"),
  vx("VX"),
  esp("ESP"),
  socialFlow("SOCIAL_FLOW");

  final String value;

  const PianoConsentProduct(this.value);
}

enum PianoConsentPurpose {
  audienceMeasurement("AM"),
  contentPersonalisation("CP"),
  advertising("AD"),
  personalRelationship("PR");

  final String value;

  const PianoConsentPurpose(this.value);
}

enum PianoConsentMode {
  optIn("opt-in"),
  essential("essential"),
  optOut("opt-out"),
  custom("custom"),
  notAcquired("not-acquired");

  final String value;

  const PianoConsentMode(this.value);
}

class PianoConsents {
  static const _pianoConsentsChannel = MethodChannel("piano_consents");

  final Map<String, dynamic> _parameters;
  final MethodChannel _channel;

  bool _initialized = false;

  PianoConsents(
      {bool requireConsents = false,
      Map<PianoConsentProduct, PianoConsentPurpose>? defaultPurposes,
      MethodChannel? channel})
      : _parameters = {
          "requireConsents": requireConsents,
          "defaultPurposes": defaultPurposes?.map(
              (product, purpose) => MapEntry(product.value, purpose.value))
        },
        _channel = channel ?? _pianoConsentsChannel;

  Future<void> init() async {
    await _channel.invokeMethod("init", _parameters);
    _initialized = true;
  }

  Future<void> set(
      {required PianoConsentPurpose purpose,
      required PianoConsentMode mode,
      List<PianoConsentProduct>? products}) async {
    _checkInit();
    await _channel.invokeMethod("set", {
      "purpose": purpose.value,
      "mode": mode.value,
      "products": products?.map((product) => product.value).toList()
    });
  }

  Future<void> setAll({required PianoConsentMode mode}) async {
    _checkInit();
    await _channel.invokeMethod("setAll", {"mode": mode.value});
  }

  Future<void> clear() async {
    _checkInit();
    await _channel.invokeMethod("clear");
  }

  void _checkInit() {
    if (!_initialized) {
      throw Error.safeToString("PianoConsents not initialized");
    }
  }
}
