class ProcurementView {
  final List<ProcurementItemView> procurementItems;
  final List<DeliverySimpleView> upcomingDeliveries;

  const ProcurementView({
    required this.procurementItems,
    required this.upcomingDeliveries,
  });

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

class ProcurementItemView {
  final String materialDescription;
  final String tdsQty;
  final String cmsRequiredDate;
  final String goodsAtLocationDate;
  final String? status;

  const ProcurementItemView({
    required this.materialDescription,
    required this.tdsQty,
    required this.cmsRequiredDate,
    required this.goodsAtLocationDate,
    this.status,
  });

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

class DeliverySimpleView {
  final String materialDescription;
  final String goodsAtLocationDate;
  final String? status;

  const DeliverySimpleView({
    required this.materialDescription,
    required this.goodsAtLocationDate,
    this.status,
  });

  factory DeliverySimpleView.fromJson(Map<String, dynamic> json) {
    return DeliverySimpleView(
      materialDescription: (json['materialDescription'] ?? '').toString(),
      goodsAtLocationDate: (json['goodsAtLocationDate'] ?? '').toString(),
      status: json['status']?.toString(),
    );
  }
}
