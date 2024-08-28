import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_analytics/piano_consents.dart';

PianoConsents getPianoConsents(MethodChannel channel) {
  return PianoConsents(
      requireConsents: true,
      defaultPurposes: {
        PianoConsentProduct.pa: PianoConsentPurpose.audienceMeasurement
      },
      channel: channel);
}

main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel("piano_consents");

  MethodCall? call;

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
    await getPianoConsents(channel).init();

    expect(call?.method, "init");

    var arguments = call?.arguments as Map<Object?, Object?>;
    expect(arguments["requireConsents"], true);

    var purposes = arguments["defaultPurposes"] as Map<Object?, Object?>;
    expect(purposes[PianoConsentProduct.pa.value],
        PianoConsentPurpose.audienceMeasurement.value);
  });

  test("set", () async {
    var pianoConsents = getPianoConsents(channel);
    await pianoConsents.init();
    await pianoConsents.set(
        purpose: PianoConsentPurpose.audienceMeasurement,
        mode: PianoConsentMode.optIn,
        products: [PianoConsentProduct.pa]);

    expect(call?.method, "set");

    var arguments = call?.arguments as Map<Object?, Object?>;

    expect(arguments["purpose"], PianoConsentPurpose.audienceMeasurement.value);
    expect(arguments["mode"], PianoConsentMode.optIn.value);
    expect((arguments["products"] as List<Object?>).first,
        PianoConsentProduct.pa.value);
  });

  test("setAll", () async {
    var pianoConsents = getPianoConsents(channel);
    await pianoConsents.init();
    await pianoConsents.setAll(mode: PianoConsentMode.optIn);

    expect(call?.method, "setAll");

    var arguments = call?.arguments as Map<Object?, Object?>;

    expect(arguments["mode"], PianoConsentMode.optIn.value);
  });

  test("clear", () async {
    var pianoConsents = getPianoConsents(channel);
    await pianoConsents.init();
    await pianoConsents.clear();

    expect(call?.method, "clear");
  });
}
