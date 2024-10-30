enum VisitorIDType {
  uuid("UUID"),
  adid("ADID"),
  custom("CUSTOM");

  final String value;

  const VisitorIDType(this.value);
}

enum VisitorStorageMode {
  fixed("fixed"),
  relative("relative");

  final String value;

  const VisitorStorageMode(this.value);
}

enum PropertyType {
  bool("b"),
  int("n"),
  float("f"),
  string("s"),
  date("d"),
  intArray("a:n"),
  floatArray("a:f"),
  stringArray("a:s");

  final String value;

  const PropertyType(this.value);
}

enum PrivacyMode {
  optIn("opt-in"),
  optOut("opt-out"),
  exempt("exempt"),
  custom("custom"),
  noConsent("no-consent"),
  noStorage("no-storage");

  final String value;

  const PrivacyMode(this.value);
}

enum PrivacyStorageFeature {
  visitor("VISITOR"),
  crash("CRASH"),
  lifecycle("LIFECYCLE"),
  privacy("PRIVACY"),
  user("USER");

  final String value;

  const PrivacyStorageFeature(this.value);
}
