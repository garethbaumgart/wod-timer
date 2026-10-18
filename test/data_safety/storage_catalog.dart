/// Shipped SharedPreferences / UserDefaults shapes that must keep loading.
///
/// Test-only. Lists are oldest → newest; the last entry is the storage shape
/// HEAD must still write. Adding or changing a key requires a **new** fixture
/// directory and a new [ShippedStorageVersion] — never edit an old fixture,
/// and never gate on pubspec `version:` (ship.sh bumps that after the gate).
class StorageCatalog {
  StorageCatalog._();

  /// Phone/tablet SharedPreferences shapes that shipped to the stores.
  ///
  /// 1.0.0 never went live as Mentalmetal. 1.1.1 was internal and wrote the
  /// same keys as 1.1.2. 1.2.1 wrote the same keys as 1.2.0. 1.3.1 was
  /// TestFlight/Play internal; its phone keys match 1.3.0, and production
  /// followed as 2.0.0.
  static const phoneVersions = <ShippedStorageVersion>[
    ShippedStorageVersion(
      appVersion: '1.1.0',
      commitSha: '3876b5bf597cc99732c2be575af79a6b71495373',
      note: 'Untagged live 1.1.0 (store listing restored in d7a39cf).',
    ),
    ShippedStorageVersion(
      appVersion: '1.1.2',
      commitSha: 'c0ffb0a5f772a0dd9efe6df93ff59f695e4ba1f7',
      note: 'First tagged store build.',
    ),
    ShippedStorageVersion(
      appVersion: '1.1.3',
      commitSha: 'b5bba49280726fc83d24a95830f333f0936abfc5',
      note: 'Adds review_* keys.',
    ),
    ShippedStorageVersion(
      appVersion: '1.2.0',
      commitSha: '9379e3a7c7d59f32696fdf5c18cf6c74b3238d15',
      note: 'Adds setup_* keys (no last_mode).',
    ),
    ShippedStorageVersion(
      appVersion: '1.3.0',
      commitSha: '15387695a5eba63e2e3d3da28cd88499ec9f5a87',
      note: 'Adds silent-migration flag and AMRAP hint.',
    ),
    ShippedStorageVersion(
      appVersion: '2.0.0',
      commitSha: 'eac3086474735f719c61049f89e60b035451a9ff',
      note: 'Adds setup_last_mode.',
    ),
    ShippedStorageVersion(
      appVersion: '2.1.0',
      commitSha: '96c5a86b63841966184d45b38089418eaf72cd77',
    ),
    ShippedStorageVersion(
      appVersion: '2.2.0',
      commitSha: 'adfc25275bd8d8deb07c6950ff5c9ea72417231f',
      note: 'Peeled v2.2.0 annotated tag.',
    ),
    ShippedStorageVersion(
      appVersion: '2.2.1',
      commitSha: '998f9e3b81597e228376ed31784a815e209a3591',
    ),
  ];

  /// Apple Watch UserDefaults shapes. Through 1.3.0 the watch only wrote
  /// `recent_workouts`. Voice/setup keys first reached the stores in 2.0.0
  /// (they exist on the 1.3.1 TF commit, which was not a store tag).
  static const watchVersions = <ShippedStorageVersion>[
    ShippedStorageVersion(
      appVersion: '1.1.0',
      commitSha: '3876b5bf597cc99732c2be575af79a6b71495373',
    ),
    ShippedStorageVersion(
      appVersion: '1.1.2',
      commitSha: 'c0ffb0a5f772a0dd9efe6df93ff59f695e4ba1f7',
    ),
    ShippedStorageVersion(
      appVersion: '1.1.3',
      commitSha: 'b5bba49280726fc83d24a95830f333f0936abfc5',
    ),
    ShippedStorageVersion(
      appVersion: '1.2.0',
      commitSha: '9379e3a7c7d59f32696fdf5c18cf6c74b3238d15',
    ),
    ShippedStorageVersion(
      appVersion: '1.3.0',
      commitSha: '15387695a5eba63e2e3d3da28cd88499ec9f5a87',
    ),
    ShippedStorageVersion(
      appVersion: '2.0.0',
      commitSha: 'eac3086474735f719c61049f89e60b035451a9ff',
    ),
    ShippedStorageVersion(
      appVersion: '2.1.0',
      commitSha: '96c5a86b63841966184d45b38089418eaf72cd77',
    ),
    ShippedStorageVersion(
      appVersion: '2.2.0',
      commitSha: 'adfc25275bd8d8deb07c6950ff5c9ea72417231f',
    ),
    ShippedStorageVersion(
      appVersion: '2.2.1',
      commitSha: '998f9e3b81597e228376ed31784a815e209a3591',
    ),
  ];

  /// Wear OS SharedPreferences file `"wharfwod"`. First shipped as
  /// `v2.2.0-wear`, then `v2.2.1`. The phone `v2.2.0` tag (adfc252) has no
  /// wear module.
  static const wearVersions = <ShippedStorageVersion>[
    ShippedStorageVersion(
      appVersion: '2.2.0-wear',
      commitSha: '190a6e4ee87011f786b982e386bf1068127cc2a0',
      note: 'Peeled v2.2.0-wear annotated tag.',
      fixtureFolder: '2.2.0-wear',
    ),
    ShippedStorageVersion(
      appVersion: '2.2.1',
      commitSha: '998f9e3b81597e228376ed31784a815e209a3591',
    ),
  ];

  static ShippedStorageVersion get newestPhone => phoneVersions.last;
  static ShippedStorageVersion get newestWatch => watchVersions.last;
  static ShippedStorageVersion get newestWear => wearVersions.last;
}

/// One storage shape that reached users (or, for Wear, a watch-only tag).
class ShippedStorageVersion {
  const ShippedStorageVersion({
    required this.appVersion,
    required this.commitSha,
    this.note = '',
    this.fixtureFolder,
  });

  final String appVersion;
  final String commitSha;
  final String note;

  /// Directory name under `test/fixtures/data_safety/{phone,watch,wear}/`.
  final String? fixtureFolder;

  String get directory => fixtureFolder ?? appVersion;
}
