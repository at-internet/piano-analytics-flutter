import 'package:flutter/material.dart';
import 'package:piano_analytics/enums.dart';

import 'package:piano_analytics/piano_analytics.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

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
      query: {"request_id": "123456789"});

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
          child: SingleChildScrollView(
            child: Column(
            children: [
              // Set header
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.setHeader(
                        key: "X-User-Id",
                        value: "WEB-192203AJ");
                  },
                  child: const Text("Set header")),
              // Remove header
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.setHeader(key: "X-User-Id", value: null);
                  },
                  child: const Text("Remove header")),
              // Set query
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.setQuery(
                        key: "user_id",
                        value: "WEB-192203AJ");
                  },
                  child: const Text("Set query")),
              // Remove query
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.setQuery(key: "user_id", value: null);
                  },
                  child: const Text("Remove query")),
              // Send events
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
                  child: const Text("Send events")),
              // Get user
              FilledButton(
                  onPressed: () async {
                    var user = await _pianoAnalytics.getUser();
                    if (context.mounted) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("User inforamtion"),
                              content: user != null
                                  ? Text(
                                      "ID: ${user.id}, Category: ${user.category ?? "-"}")
                                  : const Text("-"),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.pop(context, 'OK'),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          });
                    }
                  },
                  child: const Text("Get user")),
              // Set user
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.setUser(
                        id: "WEB-192203AJ",
                        category: "premium",
                        enableStorage: false);
                  },
                  child: const Text("Set user")),
              // Delete user
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.deleteUser();
                  },
                  child: const Text("Delete user")),
              // Get visitor ID
              FilledButton(
                  onPressed: () async {
                    var visitorId = await _pianoAnalytics.getVisitorId();
                    if (context.mounted) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Visitor ID"),
                              content: visitorId != null
                                  ? Text(visitorId)
                                  : const Text("-"),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.pop(context, 'OK'),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          });
                    }
                  },
                  child: const Text("Get visitor ID")),
              // Set visitor ID
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.setVisitorId(
                        visitorId: "WEB-192203AJ");
                  },
                  child: const Text("Set visitor ID")),
              // Include storage features (privcy)
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
                  child: const Text("Include storage features (privcy)")),
              // Exclude storage features (privcy)
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
                  child: const Text("Exclude storage features (privcy)")),
              // Include properties (privcy)
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
                  child: const Text("Include properties (privcy)")),
              // Exclude properties (privcy)
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
                  child: const Text("Exclude properties (privcy)")),
              // Include events (privcy)
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.privacyIncludeEvents(
                        eventNames: ["page.display"],
                        modes: [PrivacyMode.custom]);
                  },
                  child: const Text("Include events (privcy)")),
              // Exclude events (privcy)
              FilledButton(
                  onPressed: () async {
                    await _pianoAnalytics.privacyExcludeEvents(
                        eventNames: ["click.action"],
                        modes: [PrivacyMode.custom]);
                  },
                  child: const Text("Exclude events (privcy)"))
            ],
          ),
          )
        ),
      ),
    );
  }
}
