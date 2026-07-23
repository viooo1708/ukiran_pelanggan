class AttributeModel {
  final int id;
  final String type;
  final String value;

  AttributeModel({
    required this.id,
    required this.type,
    required this.value,
  });

  factory AttributeModel.fromJson(Map<String, dynamic> json) {
    return AttributeModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      value: json['value'] ?? '',
    );
  }
}