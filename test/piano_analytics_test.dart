import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_analytics/enums.dart';
import 'package:piano_analytics/piano_analytics.dart';

PianoAnalytics getPianoAnalytics(MethodChannel channel) {
  return PianoAnalytics(
      site: 123456789, collectDomain: "xxxxxxx.pa-cd.com", channel: channel);
}

main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannel channel = MethodChannel(
      "piano_analytics", StandardMethodCodec(PianoAnalyticsMessageCodec()));

  MethodCall? call;

  Future<void> testStorageFeatures(
      String method,
      Function(PianoAnalytics pa, List<PrivacyStorageFeature> features,
              List<PrivacyMode> modes)
          invoke) async {
    var pianoAnalytics = getPianoAnalytics(channel);
    await pianoAnalytics.init();

    var testFeatures = [
      PrivacyStorageFeature.all,
      PrivacyStorageFeature.crash,
      PrivacyStorageFeature.lifecycle,
      PrivacyStorageFeature.privacy,
      PrivacyStorageFeature.user,
      PrivacyStorageFeature.visitor
    ];

    var testModes = [
      PrivacyMode.custom,
      PrivacyMode.exempt,
      PrivacyMode.noConsent,
      PrivacyMode.noStorage,
      PrivacyMode.optIn,
      PrivacyMode.optOut
    ];

    await invoke(pianoAnalytics, testFeatures, testModes);

    expect(call?.method, method);

    var arguments = call?.arguments as Map<Object?, Object?>;

    var features = arguments["features"] as List<Object?>;
    expect(features.length, testFeatures.length);
    for (var feature in testFeatures) {
      expect(features.contains(feature.value), true);
    }

    var modes = arguments["modes"] as List<Object?>;
    expect(modes.length, testModes.length);
    for (var mode in testModes) {
      expect(modes.contains(mode.value), true);
    }
  }

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      call = methodCall;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    call = null;
  });

  test("init", () async {
    await getPianoAnalytics(channel).init();

    expect(call?.method, "init");

    var arguments = call?.arguments as Map<Object?, Object?>;

    expect(arguments["site"], 123456789);
    expect(arguments["collectDomain"], "xxxxxxx.pa-cd.com");
    expect(arguments["visitorIDType"], VisitorIDType.uuid.value);
  });

  test("send", () async {
    var pianoAnalytics = getPianoAnalytics(channel);
    await pianoAnalytics.init();
    await pianoAnalytics.sendEvents(events: [
      Event(name: "page.display", properties: [
        Property.bool(name: "bool", value: true),
        Property.int(name: "int", value: 1),
        Property.double(name: "double", value: 1.0),
        Property.string(name: "string", value: "value"),
        Property.date(name: "date", value: DateTime(2000)),
        Property.intArray(name: "intArray", value: [1, 2, 3]),
        Property.doubleArray(name: "doubleArray", value: [1.0, 2.0, 3.0]),
        Property.stringArray(name: "stringArray", value: ["a", "b", "c"])
      ])
    ]);

    expect(call?.method, "send");

    var arguments = call?.arguments as Map<Object?, Object?>;

    var events = arguments["events"] as List<Object?>;
    expect(events.length, 1);

    var event = events[0] as Map<Object?, Object?>;
    expect(event["name"], "page.display");

    var properties = event["data"] as Map<Object?, Object?>;
    expect(properties["bool"], true);
    expect(properties["int"], 1);
    expect(properties["double"], 1.0);
    expect(properties["string"], "value");
    expect(properties["date"], DateTime(2000));
    expect(properties["intArray"], [1, 2, 3]);
    expect(properties["doubleArray"], [1.0, 2.0, 3.0]);
    expect(properties["stringArray"], ["a", "b", "c"]);
  });

  test("privacyIncludeStorageFeatures", () async {
    await testStorageFeatures(
        "privacyIncludeStorageFeatures",
        (pa, features, modes) =>
            pa.privacyIncludeStorageFeatures(features: features, modes: modes));
  });

  test("privacyExcludeStorageFeatures", () async {
    await testStorageFeatures(
        "privacyExcludeStorageFeatures",
        (pa, features, modes) =>
            pa.privacyExcludeStorageFeatures(features: features, modes: modes));
  }); 
}
