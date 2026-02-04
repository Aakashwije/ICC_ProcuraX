/*
  Model representing a procurement item returned by the backend API.
  This model uses DateTime for date fields to support date operations.
*/
class ProcurementItem {
  final String materialDescription;
  final String tdsQty;
  final DateTime cmsRequiredDate;
  final DateTime? goodsAtLocationDate;

  /*
    Creates a typed procurement item with parsed dates.
  */
  const ProcurementItem({
    required this.materialDescription,
    required this.tdsQty,
    required this.cmsRequiredDate,
    this.goodsAtLocationDate,
  });

  /*
    Parses JSON into strongly-typed fields, safely handling null dates.
  */
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
