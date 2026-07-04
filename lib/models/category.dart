/// 用途分类模型
class Category {
  int? id;
  String name;
  int sort;

  Category({
    this.id,
    required this.name,
    this.sort = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sort': sort,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      sort: (map['sort'] as int?) ?? 0,
    );
  }
}
