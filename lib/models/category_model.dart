class CategoryModel {
  final String id;
  final String name;
  final String type; 
  final String emoji;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.emoji,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: data['name'],
      type: data['type'],
      emoji: data['emoji'] ?? '❓',
    );
  }
}