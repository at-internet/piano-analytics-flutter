<div id="top"></div>

<br />
<div align="center">
    <h1 align="center">Piano Analytics SDK Flutter</h1>
</div>

## About The Project

The Piano Analytics Flutter SDK allows you to collect audience measurement data for the [Piano Analytics](https://piano.io/product/analytics/) solution.
It can be used with Flutter applications.

This SDK makes the implementation of Piano Analytics as simple as possible, while keeping all the flexibility of the solution. By using this plugin in your applications, and using [dedicated and documented methods](https://developers.atinternet-solutions.com/piano-analytics/), you will be able to send powerful events.

## Getting Started

1. Add this to your pubspec.yaml file:
    ```yaml
    dependencies:
      piano_analytics: ^1.0.2
    ```

2. Install the plugin using the command
    ```
    flutter pub get
    ```

## Usage

Initialize PianoAnalytics with your site and collect domain in your application initialization
  ```dart
  import 'package:piano_analytics/piano_analytics.dart';
  import 'package:piano_analytics/enums.dart';
  ...

  class _MyAppState extends State<MyApp> {

    final _pianoAnalytics = PianoAnalytics(
      site: 123456789,
      collectDomain: "xxxxxxx.pa-cd.com",
      visitorIDType: VisitorIDType.uuid,
      storageLifetimeVisitor: 395,
      visitorStorageMode: VisitorStorageMode.fixed,
      ignoreLimitedAdvertisingTracking: true,
      visitorId: "WEB-192203AJ",
      headers: {"X-Request-Id": "123456789"},
      query: {"request_id": "123456789"}
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

### Set HTTP parameters

Headers:
```dart
await _pianoAnalytics.setHeader(key: "X-User-Id", value: "WEB-192203AJ")
```

Query string parameters:
```dart
await _pianoAnalytics.setQuery(key: "user_id", value: "WEB-192203AJ")
```

### Send events
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

## User
You can get/set/delete a user

### Get user
  ```dart
  var user = await _pianoAnalytics.getUser();
  ```

### Set user
  ```dart
  await _pianoAnalytics.setUser(
    id: "WEB-192203AJ",
    category: "premium",
    enableStorage: false
  );
  ```

### Delete user
  ```dart
  await _pianoAnalytics.deleteUser();
  ```

## Visitor ID
You can get/set visitor ID (*only for `VisitorIDType.custom`*)

### Get visitor ID
  ```dart
  var user = await _pianoAnalytics.getVisitorId();
  ```

### Set visitor ID
  ```dart
  await _pianoAnalytics.setVisitorId(
    visitorId: "WEB-192203AJ"
  );
  ```

## Privacy
You can change privacy parameters

### Include storage features
  ```dart
   await _pianoAnalytics.privacyIncludeStorageFeatures(
    features: [
      PrivacyStorageFeature.crash,
      PrivacyStorageFeature.visitor
    ],
    modes: [
      PrivacyMode.custom
    ]
  );
  ```

### Exclude storage features
  ```dart
  await _pianoAnalytics.privacyExcludeStorageFeatures(
    features: [
      PrivacyStorageFeature.crash,
      PrivacyStorageFeature.visitor
    ],
    modes: [
      PrivacyMode.custom
    ]
  );
  ```

### Include properties
  ```dart
  await _pianoAnalytics.privacyIncludeProperties(
    propertyNames: [
      "allowed_property_1",
      "allowed_property_2"
    ],
    modes: [
      PrivacyMode.custom
    ],
    eventNames: [
      "page.display",
      "click.action"
    ]
  );
  ```

### Exclude properties
  ```dart
  await _pianoAnalytics.privacyExcludeProperties(
    propertyNames: [
      "forbidden_property_1",
      "forbidden_property_2"
    ],
    modes: [
      PrivacyMode.custom
    ]
  );
  ```

### Include events
  ```dart
  await _pianoAnalytics.privacyIncludeEvents(
    eventNames: ["page.display"],
    modes: [PrivacyMode.custom]
  );
  ```

### Exclude events
  ```dart
  await _pianoAnalytics.privacyExcludeEvents(
    eventNames: ["click.action"],
    modes: [PrivacyMode.custom]
  );
  ```

## Consents

> **Important:** Initialize PianoConsents before initializing PianoAnalytics

*Use the **[piano_consents](https://pub.dev/packages/piano_consents)** package*