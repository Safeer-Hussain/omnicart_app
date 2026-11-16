class DarkStoreHub {
  final String id;
  final String name;
  final String code;
  final double latitude;
  final double longitude;
  final String address;
  final int activePickers;
  final double coldZoneTempCelsius;

  const DarkStoreHub({
    required this.id,
    required this.name,
    required this.code,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.activePickers = 12,
    this.coldZoneTempCelsius = 3.6,
  });

  static const DarkStoreHub defaultHub = DarkStoreHub(
    id: 'hub_central_a1',
    name: 'Gulberg Central Dark-Store A1',
    code: 'HUB-GLB-01',
    latitude: 31.5204,
    longitude: 74.3587,
    address: 'Main Boulevard, Gulberg III, Lahore',
    activePickers: 14,
    coldZoneTempCelsius: 3.5,
  );

  static const List<DarkStoreHub> networkHubs = [
    defaultHub,
    DarkStoreHub(
      id: 'hub_dha_b2',
      name: 'DHA Phase 6 Micro-Fulfillment B2',
      code: 'HUB-DHA-02',
      latitude: 31.4580,
      longitude: 74.4210,
      address: 'Main Boulevard, DHA Phase 6, Lahore',
      activePickers: 18,
      coldZoneTempCelsius: 3.2,
    ),
    DarkStoreHub(
      id: 'hub_johar_c3',
      name: 'Johar Town Express Quick-Hub C3',
      code: 'HUB-JHR-03',
      latitude: 31.4690,
      longitude: 74.2980,
      address: 'G1 Market, Johar Town, Lahore',
      activePickers: 11,
      coldZoneTempCelsius: 3.8,
    ),
  ];
}
