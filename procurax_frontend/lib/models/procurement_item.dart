/*
  Model representing a procurement item returned by the backend API.
  Updated to match enterprise logistics fields.
*/
class ProcurementItem {
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
    Creates a typed procurement item with all logistics fields.
  */
  const ProcurementItem({
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
    Parses JSON into strongly-typed fields, safely handling null values.
  */
  factory ProcurementItem.fromJson(Map<String, dynamic> json) {
    return ProcurementItem(
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
