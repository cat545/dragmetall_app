class DataElement {
  int? id;
  int? lvl;
  String? name;
  String? image;
  String? category;
  String? short_name;
  String? next_name;
  String? prev_name;
  String? way;
  String? content;
  String? note;
  int? favorite;
  String? type;
  String? date;  

  double? gold;
  double? silver;
  double? platinum;
  double? palladium;

  int? saved;
  double saved_trans = 1.0;
  double copy_trans = 1.0;
  double share_trans = 1.0;

  DataElement(this.id, this.lvl, this.name, this.category, this.image, this.short_name, this.next_name, this.prev_name, this.way, this.content, this.note, this.favorite, this.type, this.date, 
    this.gold, this.silver, this.platinum, this.palladium,
    this.saved, this.saved_trans, this.copy_trans, this.share_trans);
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'lvl': lvl,
      'name': name,
      'category': category,
      'image': image,
      'short_name': short_name,
      'next_name': next_name,
      'prev_name': prev_name,
      'way': way,
      'content': content,
      'note': note,
      'favorite': favorite,
      'type': type,
      'date': date,
      'gold': gold,
      'silver': silver,
      'platinum': platinum,
      'palladium': palladium,
    };
    return map;
  }

  DataElement.fromMap(Map<String, dynamic> map) {
    id = int.parse(map['id'].toString());
    name = map['name'].toString();
    category = map['category'].toString();
    image = map['image'].toString();
    short_name = map['short_name'].toString();
    next_name = map['next_name'].toString().replaceAll("null", "");
    prev_name = map['prev_name'].toString().replaceAll("null", "");
    way = map['way'].toString().replaceAll("^null", "").replaceAll("null", "");
    content = map['content'].toString().replaceAll('null', '');
    note = map['note'].toString().replaceAll('null', '');
    saved = int.parse(map['favorite'].toString().replaceAll("null", "0"));
    favorite = int.parse(map['favorite'].toString().replaceAll("null", "0"));
    type = map['type'].toString().replaceAll("null", "");
    date = map['date'].toString().replaceAll("null", "");

    gold = double.parse(map['gold'].toString());
    silver = double.parse(map['silver'].toString());
    platinum = double.parse(map['platinum'].toString());
    palladium = double.parse(map['palladium'].toString());
  }
}

class MPrice{
  String? date;
  int? metall;
  double? price;

  MPrice({this.date, this.metall, this.price});
}

class MPriceCode{
  String? date;
  int? code;
  double? price;

  MPriceCode({this.date, this.code, this.price});
  MPriceCode.fromMap(Map<String, dynamic> map) {
    date = map['date'].toString();
    code = int.parse(map['code'].toString());
    price = double.parse(map['price'].toString());
  }
}