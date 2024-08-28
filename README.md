<div id="top"></div>

<br />
<div align="center">
    <h1 align="center">Piano Analytics SDK Flutter</h1>
</div>

## About The Project

The Piano Analytics Apple SDK allows you to collect audience measurement data for the [Piano Analytics](https://piano.io/product/analytics/) solution.
It can be used with Flutter applications.

This SDK makes the implementation of Piano Analytics as simple as possible, while keeping all the flexibility of the solution. By using this plugin in your applications, and using [dedicated and documented methods](https://developers.atinternet-solutions.com/piano-analytics/), you will be able to send powerful events.

## Getting Started

1. Add this to your pubspec.yaml file:
    ```yaml
    dependencies:
      piano_analytics: ^1.x.x
    ```

2. Install the plugin using the command
    ```
    flutter pub get
    ```

## Usage

1. Initialize PianoAnalytics with your site and collect domain in your application initialization
    ```dart
    import 'package:piano_analytics/piano_analytics.dart';

    ...

    class _MyAppState extends State<MyApp> {

      final _pianoAnalytics = PianoAnalytics(
        site: 123456789,
        collectDomain: "xxxxxxx.pa-cd.com"
      );

      @override
      void initState() {
        super.initState();
        initPlugins();
      }

      Future<void> initPlugins() async {
        ...
        await _pianoAnalytics.init();
      }
      ...
    }
    ```

2. Send events
    ```dart
    await _pianoAnalytics.sendEvents(events: [
      Event(name: "page.display", properties: [
        Property.bool(name: "bool", value: true),
        Property.int(name: "int", value: 1),
        Property.int(name: "long", value: 9007199254740992),
        Property.double(name: "double", value: 1.0),
        Property.string(name: "string", value: "value"),
        Property.date(name: "date", value: DateTime.now()),
        Property.intArray(name: "intArray", value: [1, 2, 3]),
        Property.doubleArray(name: "doubleArray", value: [1.0, 2.0, 3.0]),
        Property.stringArray(name: "stringArray", value: ["a", "b", "c"])
      ])
    ]);
    ```

## Consents

> **Important:** Initialize PianoConsents before initializing PianoAnalytics

1. Initialize PianoConsents
    ```dart
    import 'package:piano_analytics/piano_analytics.dart';
    import 'package:piano_analytics/piano_consents.dart';

    ...

    class _MyAppState extends State<MyApp> {
      final _pianoConsents = PianoConsents(
        requireConsents: true,
        defaultPurposes: {
          PianoConsentProduct.pa: PianoConsentPurpose.audienceMeasurement
        }
      );

      final _pianoAnalytics = PianoAnalytics(
        site: 1,
        collectDomain: "piano.io"
      );

      @override
      void initState() {
        super.initState();
        initPlugins();
      }

      Future<void> initPlugins() async {
        ...
        await _pianoConsents.init();
        await _pianoAnalytics.init();
      }
      ...
    }
    ```
2. Set consents
    ```dart
    await _pianoConsents.set(
      purpose: PianoConsentPurpose.audienceMeasurement,
      mode: PianoConsentMode.essential,
      products: [PianoConsentProduct.pa]);
    ```

3. Set all consents
    ```dart
    await _pianoConsents.setAll(mode: PianoConsentMode.essential);
    ```

4. Set default consents
    ```dart
    await _pianoConsents.clear();
    ```