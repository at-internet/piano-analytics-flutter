import 'package:flutter/material.dart';
import 'package:piano_analytics/enums.dart';

import 'package:piano_analytics/piano_analytics.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _pianoAnalytics =
      PianoAnalytics(site: 123456789, collectDomain: "xxxxxxx.pa-cd.com");

  @override
  void initState() {
    super.initState();
    initPlugins();
  }

  Future<void> initPlugins() async {
    await _pianoAnalytics.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Piano analytics'),
        ),
        body: Center(
          child: Column(
            children: [
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.sendEvents(events: [
                      Event(name: "page.display", properties: [
                        Property.bool(name: "bool", value: true),
                        Property.int(name: "int", value: 1),
                        Property.int(name: "long", value: 9007199254740992),
                        Property.double(name: "double", value: 1.0),
                        Property.string(name: "string", value: "value"),
                        Property.date(name: "date", value: DateTime.now()),
                        Property.intArray(name: "intArray", value: [1, 2, 3]),
                        Property.doubleArray(
                            name: "doubleArray", value: [1.0, 2.0, 3.0]),
                        Property.stringArray(
                            name: "stringArray", value: ["a", "b", "c"])
                      ])
                    ]);
                  },
                  child: const Text("Send")),
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.privacyIncludeStorageFeatures(
                        features: [
                          PrivacyStorageFeature.crash,
                          PrivacyStorageFeature.visitor
                        ],
                        modes: [
                          PrivacyMode.custom
                        ]);
                  },
                  child: const Text("Include storage features")),
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.privacyExcludeStorageFeatures(
                        features: [
                          PrivacyStorageFeature.crash,
                          PrivacyStorageFeature.visitor
                        ],
                        modes: [
                          PrivacyMode.custom
                        ]);
                  },
                  child: const Text("Exclude storage features")),
              FilledButton(
                  onPressed: () async {
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
                        ]);
                  },
                  child: const Text("Include properties")),
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.privacyExcludeProperties(
                        propertyNames: [
                          "forbidden_property_1",
                          "forbidden_property_2"
                        ],
                        modes: [
                          PrivacyMode.custom
                        ]);
                  },
                  child: const Text("Exclude properties")),
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.privacyIncludeEvents(
                        eventNames: ["page.display"],
                        modes: [PrivacyMode.custom]);
                  },
                  child: const Text("Include events")),
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.privacyExcludeEvents(
                        eventNames: ["click.action"],
                        modes: [PrivacyMode.custom]);
                  },
                  child: const Text("Exclude events"))
            ],
          ),
        ),
      ),
    );
  }
}
