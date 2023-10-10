class Favorite_items {
  int? id;
  String? element;
  String? grade;

  Favorite_items(this.id, this.element, this.grade);
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{'id': id};
    element = map['element'].toString();
    grade = map['grade'].toString();
    return map;
  }

  Favorite_items.fromMap(Map<String, dynamic> map) {
    id = int.parse(map['id'].toString());
    element = map['element'].toString();
    grade = map['grade'].toString();
  }
}