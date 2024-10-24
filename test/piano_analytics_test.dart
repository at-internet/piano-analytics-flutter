import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_analytics/enums.dart';
import 'package:piano_analytics/piano_analytics.dart';

PianoAnalytics getPianoAnalytics(MethodChannel channel) {
  return PianoAnalytics(
      site: 123456789, collectDomain: "xxxxxxx.pa-cd.com", channel: channel);
}

var testFeatures = [
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

var testPropertyNames = ["test_property_1", "test_property_2"];

var testEventNames = ["page.display", "click.action"];

main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannel channel = MethodChannel(
      "piano_analytics", StandardMethodCodec(PianoAnalyticsMessageCodec()));

  MethodCall? call;

  void checkItemsWithExpand<T>(
      dynamic actual, List<T> expected, Object? Function(T) expand) {
    var actualList = actual as List<Object?>;
    expect(actualList.length, expected.length);
    for (var item in expected) {
      expect(actualList.contains(expand(item)), true);
    }
  }

  void checkItems<T>(dynamic actual, List<T> expected) {
    checkItemsWithExpand(actual, expected, (item) => item);
  }

  void testProperty(dynamic actual, dynamic matcher,
      {PropertyType? forceType}) {
    var property = actual as Map<Object?, Object?>;
    expect(property["value"], matcher);
    if (forceType != null) {
      expect(property["forceType"], forceType.value);
    }
  }

  Future<void> testChangeStorageFeatures(
      String method,
      Function(PianoAnalytics pa, List<PrivacyStorageFeature> features,
              List<PrivacyMode> modes)
          invoke) async {
    var pianoAnalytics = getPianoAnalytics(channel);
    await pianoAnalytics.init();
    await invoke(pianoAnalytics, testFeatures, testModes);

    expect(call?.method, method);

    var arguments = call?.arguments as Map<Object?, Object?>;

    checkItemsWithExpand(
        arguments["features"], testFeatures, (feature) => feature.value);
    checkItemsWithExpand(arguments["modes"], testModes, (mode) => mode.value);
  }

  Future<void> testChangeProperties(
      String method,
      Function(PianoAnalytics pa, List<String> propertyNames,
              List<PrivacyMode> modes, List<String>? eventNames)
          invoke) async {
    var pianoAnalytics = getPianoAnalytics(channel);
    await pianoAnalytics.init();
    await invoke(pianoAnalytics, testPropertyNames, testModes, testEventNames);

    expect(call?.method, method);

    var arguments = call?.arguments as Map<Object?, Object?>;

    checkItems(arguments["propertyNames"], testPropertyNames);
    checkItemsWithExpand(arguments["modes"], testModes, (mode) => mode.value);
    checkItems(arguments["eventNames"], testEventNames);
  }

  Future<void> testChangeEvents(
      String method,
      Function(PianoAnalytics pa, List<String> eventNames,
              List<PrivacyMode> modes)
          invoke) async {
    var pianoAnalytics = getPianoAnalytics(channel);
    await pianoAnalytics.init();
    await invoke(pianoAnalytics, testEventNames, testModes);

    expect(call?.method, method);

    var arguments = call?.arguments as Map<Object?, Object?>;

    checkItems(arguments["eventNames"], testEventNames);
    checkItemsWithExpand(arguments["modes"], testModes, (mode) => mode.value);
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
        Property.bool(
            name: "bool_force", value: true, forceType: PropertyType.bool),
        Property.int(name: "int", value: 1),
        Property.int(name: "int_force", value: 1, forceType: PropertyType.int),
        Property.double(name: "double", value: 1.0),
        Property.double(
            name: "double_force", value: 1.0, forceType: PropertyType.float),
        Property.string(name: "string", value: "value"),
        Property.string(
            name: "string_force",
            value: "value",
            forceType: PropertyType.string),
        Property.date(name: "date", value: DateTime(2000)),
        Property.intArray(name: "intArray", value: [1, 2, 3]),
        Property.intArray(
            name: "intArray_force",
            value: [1, 2, 3],
            forceType: PropertyType.intArray),
        Property.doubleArray(name: "doubleArray", value: [1.0, 2.0, 3.0]),
        Property.doubleArray(
            name: "doubleArray_force",
            value: [1.0, 2.0, 3.0],
            forceType: PropertyType.floatArray),
        Property.stringArray(name: "stringArray", value: ["a", "b", "c"]),
        Property.stringArray(
            name: "stringArray_force",
            value: ["a", "b", "c"],
            forceType: PropertyType.stringArray)
      ])
    ]);

    expect(call?.method, "send");

    var arguments = call?.arguments as Map<Object?, Object?>;

    var events = arguments["events"] as List<Object?>;
    expect(events.length, 1);

    var event = events[0] as Map<Object?, Object?>;
    expect(event["name"], "page.display");

    var properties = event["data"] as Map<Object?, Object?>;
    testProperty(properties["bool"], true);
    testProperty(properties["bool_force"], true, forceType: PropertyType.bool);
    testProperty(properties["int"], 1);
    testProperty(properties["int_force"], 1, forceType: PropertyType.int);
    testProperty(properties["double"], 1.0);
    testProperty(properties["double_force"], 1.0,
        forceType: PropertyType.float);
    testProperty(properties["string"], "value");
    testProperty(properties["string_force"], "value",
        forceType: PropertyType.string);
    testProperty(properties["date"], DateTime(2000));
    testProperty(properties["intArray"], [1, 2, 3]);
    testProperty(properties["intArray_force"], [1, 2, 3],
        forceType: PropertyType.intArray);
    testProperty(properties["doubleArray"], [1.0, 2.0, 3.0]);
    testProperty(properties["doubleArray_force"], [1.0, 2.0, 3.0],
        forceType: PropertyType.floatArray);
    testProperty(properties["stringArray"], ["a", "b", "c"]);
    testProperty(properties["stringArray_force"], ["a", "b", "c"],
        forceType: PropertyType.stringArray);
  });

  test("privacyIncludeStorageFeatures", () async {
    await testChangeStorageFeatures(
        "privacyIncludeStorageFeatures",
        (pa, features, modes) =>
            pa.privacyIncludeStorageFeatures(features: features, modes: modes));
  });

  test("privacyExcludeStorageFeatures", () async {
    await testChangeStorageFeatures(
        "privacyExcludeStorageFeatures",
        (pa, features, modes) =>
            pa.privacyExcludeStorageFeatures(features: features, modes: modes));
  });

  test("privacyIncludeProperties", () async {
    await testChangeProperties(
        "privacyIncludeProperties",
        (pa, propertyNames, modes, eventNames) => pa.privacyIncludeProperties(
            propertyNames: propertyNames,
            modes: modes,
            eventNames: eventNames));
  });

  test("privacyExcludeProperties", () async {
    await testChangeProperties(
        "privacyExcludeProperties",
        (pa, propertyNames, modes, eventNames) => pa.privacyExcludeProperties(
            propertyNames: propertyNames,
            modes: modes,
            eventNames: eventNames));
  });

  test("privacyIncludeEvents", () async {
    await testChangeEvents(
        "privacyIncludeEvents",
        (pa, eventNames, modes) =>
            pa.privacyIncludeEvents(eventNames: eventNames, modes: modes));
  });

  test("privacyExcludeEvents", () async {
    await testChangeEvents(
        "privacyExcludeEvents",
        (pa, eventNames, modes) =>
            pa.privacyExcludeEvents(eventNames: eventNames, modes: modes));
  });
}
