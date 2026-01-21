/// Model representing a procurement item returned by the backend API.
class ProcurementItem {
  final String materialDescription;
  final String tdsQty;
  final DateTime cmsRequiredDate;
  final DateTime? goodsAtLocationDate;

  const ProcurementItem({
    required this.materialDescription,
    required this.tdsQty,
    required this.cmsRequiredDate,
    this.goodsAtLocationDate,
  });

  factory ProcurementItem.fromJson(Map<String, dynamic> json) {
    return ProcurementItem(
      materialDescription: json['materialDescription'] as String,
      tdsQty: json['tdsQty'] as String,
      cmsRequiredDate: DateTime.parse(json['cmsRequiredDate'] as String),
      goodsAtLocationDate: json['goodsAtLocationDate'] != null
          ? DateTime.parse(json['goodsAtLocationDate'] as String)
          : null,
    );
  }
}
