// class History_items {
//   int? id;
//   String? element;

//   History_items(this.id, this.element);
//   Map<String, dynamic> toMap() {
//     var map = <String, dynamic>{'id': id};
//     element = map['element'].toString();
//     return map;
//   }

//   History_items.fromMap(Map<String, dynamic> map) {
//     id = int.parse(map['id'].toString());
//     element = map['element'].toString();
//   }
// }