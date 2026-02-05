/*
  Aggregated view model returned by the procurement API.
  This keeps the page data in one structure for the UI.
*/
class ProcurementView {
  final List<ProcurementItemView> procurementItems;
  final List<DeliverySimpleView> upcomingDeliveries;

  /*
    Constructs the view with the two lists the UI needs.
  */
  const ProcurementView({
    required this.procurementItems,
    required this.upcomingDeliveries,
  });

  /*
    Parses API JSON into typed lists of procurement items and deliveries.
  */
  factory ProcurementView.fromJson(Map<String, dynamic> json) {
    final items = (json['procurementItems'] as List<dynamic>? ?? [])
        .map((e) => ProcurementItemView.fromJson(e as Map<String, dynamic>))
        .toList();
    final deliveries = (json['upcomingDeliveries'] as List<dynamic>? ?? [])
        .map((e) => DeliverySimpleView.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProcurementView(
      procurementItems: items,
      upcomingDeliveries: deliveries,
    );
  }
}

/*
  UI-facing procurement item. All fields are strings so the UI can display
  them directly without additional formatting.
*/
class ProcurementItemView {
  final String materialDescription;
  final String tdsQty;
  final String cmsRequiredDate;
  final String goodsAtLocationDate;
  final String? status;

  /*
    Creates a single procurement item row for the UI list.
  */
  const ProcurementItemView({
    required this.materialDescription,
    required this.tdsQty,
    required this.cmsRequiredDate,
    required this.goodsAtLocationDate,
    this.status,
  });

  /*
    Defensive parsing: convert all values to strings and allow null status.
  */
  factory ProcurementItemView.fromJson(Map<String, dynamic> json) {
    return ProcurementItemView(
      materialDescription: (json['materialDescription'] ?? '').toString(),
      tdsQty: (json['tdsQty'] ?? '').toString(),
      cmsRequiredDate: (json['cmsRequiredDate'] ?? '').toString(),
      goodsAtLocationDate: (json['goodsAtLocationDate'] ?? '').toString(),
      status: json['status']?.toString(),
    );
  }
}

/*
  Compact delivery view used by the upcoming deliveries section.
*/
class DeliverySimpleView {
  final String materialDescription;
  final String goodsAtLocationDate;
  final String? status;

  /*
    Creates a simplified delivery record for quick display.
  */
  const DeliverySimpleView({
    required this.materialDescription,
    required this.goodsAtLocationDate,
    this.status,
  });

  /*
    Parses JSON into a delivery record with string fields.
  */
  factory DeliverySimpleView.fromJson(Map<String, dynamic> json) {
    return DeliverySimpleView(
      materialDescription: (json['materialDescription'] ?? '').toString(),
      goodsAtLocationDate: (json['goodsAtLocationDate'] ?? '').toString(),
      status: json['status']?.toString(),
    );
  }
}
