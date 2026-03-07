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

  Enterprise logistics fields:
  - materialList: Item name (Column B)
  - responsibility: Contractor/Supplier (Column D)
  - openingLC: Letter of Credit opening date (Column J)
  - etd: Estimated Time of Departure (Column K)
  - eta: Estimated Time of Arrival (Column L)
  - boiApproval: Board of Investment approval (Column M)
  - revisedDeliveryToSite: Final delivery date (Column O)
  - requiredDateCMS: Required date as CMS/Site Programme (Column P)
*/
class ProcurementItemView {
  final String materialList;
  final String responsibility;
  final String openingLC;
  final String etd;
  final String eta;
  final String boiApproval;
  final String revisedDeliveryToSite;
  final String requiredDateCMS;
  final String? status;

  /*
    Creates a single procurement item row for the UI list.
  */
  const ProcurementItemView({
    required this.materialList,
    required this.responsibility,
    required this.openingLC,
    required this.etd,
    required this.eta,
    required this.boiApproval,
    required this.revisedDeliveryToSite,
    required this.requiredDateCMS,
    this.status,
  });

  /*
    Defensive parsing: convert all values to strings and allow null status.
  */
  factory ProcurementItemView.fromJson(Map<String, dynamic> json) {
    return ProcurementItemView(
      materialList: (json['materialList'] ?? '').toString(),
      responsibility: (json['responsibility'] ?? '').toString(),
      openingLC: (json['openingLC'] ?? '').toString(),
      etd: (json['etd'] ?? '').toString(),
      eta: (json['eta'] ?? '').toString(),
      boiApproval: (json['boiApproval'] ?? '').toString(),
      revisedDeliveryToSite: (json['revisedDeliveryToSite'] ?? '').toString(),
      requiredDateCMS: (json['requiredDateCMS'] ?? '').toString(),
      status: json['status']?.toString(),
    );
  }
}

/*
  Compact delivery view used by the upcoming deliveries section.
*/
class DeliverySimpleView {
  final String materialList;
  final String revisedDeliveryToSite;
  final String? status;

  /*
    Creates a simplified delivery record for quick display.
  */
  const DeliverySimpleView({
    required this.materialList,
    required this.revisedDeliveryToSite,
    this.status,
  });

  /*
    Parses JSON into a delivery record with string fields.
  */
  factory DeliverySimpleView.fromJson(Map<String, dynamic> json) {
    return DeliverySimpleView(
      materialList: (json['materialList'] ?? '').toString(),
      revisedDeliveryToSite: (json['revisedDeliveryToSite'] ?? '').toString(),
      status: json['status']?.toString(),
    );
  }
}
