
import 'package:dragmetal_app/sqlite/models/data.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io' as io;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;
  static const String DB_NAME = 'database.db';

  Future<Database?> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();
    return _db;
  }

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, DB_NAME);
    var exists = await databaseExists(path);
    if (!exists) {
      try {
        await io.Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      // Copy from asset
      ByteData data = await rootBundle.load(join("assets", "db/database.db"));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await io.File(path).writeAsBytes(bytes, flush: true);
    }
    var db = await openDatabase(path, readOnly: false);
    return db;
  }

  //   // ignore: non_constant_identifier_names
  //   Future db_delAllFavorites() async{
  //   var dbClient = await db;
  //   await dbClient!.rawDelete("DELETE FROM storage WHERE storage_type = 'favorite';");
  // }

  // ignore: no_leading_underscores_for_local_identifiers, non_constant_identifier_names
  Future db_delFavorite(wayString) async{
    var dbClient = await db;
    await dbClient!.rawDelete("DELETE FROM storage WHERE way = '$wayString' AND storage_type = 'favorite';");
  }

  Future db_setFavorite(element) async{
    
    String nextName = element.prev_name == element.name ? "" : element.name;

    String query = 
    """INSERT INTO storage 
    (id,name, next_name, prev_name, way, note, gold, silver, platinum, palladium, type, storage_type) 
    VALUES 
    ('${element.id}', '${element.prev_name}', '$nextName', 'Избранное', '${element.way}', '${element.note}', '${element.gold}', '${element.silver}', '${element.platinum}', '${element.palladium}', 'fv_${element.type}', 'favorite');""";
    var dbClient = await db;
    await dbClient!.rawInsert(query);
  }

    Future db_delAllFavorites() async{
    var dbClient = await db;
    await dbClient!.rawDelete("DELETE FROM storage WHERE storage_type = 'favorite';");
  }

  // ignore: non_constant_identifier_names
  Future db_getFavorites() async{
    String query = "SELECT * FROM storage WHERE storage_type = 'favorite'";
    var dbClient = await db;
    List<DataElement> result = [];
    List<Map<String, dynamic>> maps;
    maps = await dbClient!.rawQuery(query);
    if(maps.isNotEmpty){
      for(int i = 0; i < maps.length; i++){
        result.add(DataElement.fromMap(maps[i]));
      }
    }
    return result;
  }

  // ignore: non_constant_identifier_names
  Future  db_setPrices(mPriceList) async {
    var dbClient = await db;
    await dbClient!.transaction((txn) async {
        for (var i = 0; i < mPriceList.length; i++) {
          await txn.rawInsert("INSERT INTO prices (code, date, price) VALUES (${mPriceList[i].metall}, '${mPriceList[i].date}', ${mPriceList[i].price});");
        }
    });
  }

  // ignore: non_constant_identifier_names
  Future db_getPricesList() async{
    String query = "SELECT date, code, price FROM prices;";
    var dbClient = await db;
    List<MPriceCode> result = [];
    List<Map<String, dynamic>> maps;
    maps = await dbClient!.rawQuery(query);
    if(maps.isNotEmpty){
      for(int i = 0; i < maps.length; i++){
        result.add(MPriceCode.fromMap(maps[i]));
      }
    }
    return result;
  }


  // ignore: non_constant_identifier_names
  Future db_getFavoriteList(limit, MAXLEVEL) async{
    String qPart = "";
    String concatWay = "";
    for(int i = 0; i < MAXLEVEL; i++) {
      qPart = "${qPart}lvl${i + 1}, ";  
      concatWay = "${concatWay}COALESCE(lvl${i + 1}, 'null')||'^'||";  
    }
    qPart = qPart.substring(0, qPart.length - 2);
    concatWay = "${concatWay.substring(0, concatWay.length - 7)} AS way ";
    var dbClient = await db;
    String query =
    """
    SELECT storage.id, storage.datetime AS date, data.content, $concatWay, 'favorite_card' AS type FROM storage
    LEFT JOIN data ON storage.id = data.id  AND storage.storage_type = 'favorites';
    """;
    List<DataElement> result = [];
    List<Map<String, dynamic>> maps;
    maps = await dbClient!.rawQuery(query);
    if(maps.isNotEmpty){
      for(int i = 0; i < maps.length; i++){
        result.add(DataElement.fromMap(maps[i]));
        result[i].name = result[i].way!.replaceAll(RegExp(r"^.*\^"), "");
      }
    }
    return result;
  }

  // ignore: non_constant_identifier_names
  set_del_Favorite (id, action) async{
    var dbClient = await db;
    if (action == 1){
      String date = DateTime.now().toString().substring(0, 19);
      await dbClient!.rawUpdate("INSERT INTO storage (id, storage_type, datetime) VALUES ($id, 'favorites', '$date');");
    }else{
      await dbClient!.rawUpdate("DELETE FROM storage WHERE id=$id AND storage_type='favorites';");
    }
  }

  //Возвращвет список элементов, если isEnd, тогда это последний элемент Контент.
  // ignore: non_constant_identifier_names
  Future db_getElementsList(limit, wayString, MAXLEVEL, isEnd) async{
    wayString = wayString.replaceAll("'","''");
    var way0 = wayString == "" ? [] : wayString.split("^");
    String qPart = way0.length == 0 ? "" : "WHERE";
    for(int i = 0; i < way0.length; i++) {
      qPart = "$qPart lvl${i + 1} = '${way0[i]}' AND";
    }
    qPart = way0.length == 0 ? "WHERE lvl2 <> 'Short Birthday wishes'" : "${qPart.substring(0, qPart.length - 4)} AND lvl2 <> 'Short Birthday wishes'";
    String nextName = isEnd ? "null" : 1 + way0.length >= MAXLEVEL ? "null" : "lvl${2 + way0.length}";
    String prevName = isEnd ? ", null AS prev_name , storage.id AS favorite" : way0.length > 0 ?  ", lvl${way0.length} AS prev_name" : "";
    String groupBy = isEnd ? "" : "GROUP BY lvl${1 + way0.length}";
    String name = isEnd ? "null" : "lvl${1 + way0.length}";
    String shortName = isEnd ? "null" : "sh_lvl${1 + way0.length}";
    String content = isEnd ? "content" : "null AS content";
    String metallPrices = "gold AS gold, silver AS silver, platinum AS platinum, palladium AS palladium,";
    String favorites = isEnd ? "LEFT JOIN storage ON data.id = storage.id AND storage.storage_type = 'favorites'" : "";
    String type = isEnd ? "'card' AS type" : "'element' AS type" ;
    String way = "'$wayString' AS way" ;
    // String imageJoin = way0.length  == 1 ? "LEFT JOIN settings ON short_name = settings.key " : "";
    // String image = imageJoin != "" ? "settings.img AS image," : "";
    String imageJoin = "";
    String image = "";
    String query = 
    """
    SELECT $image data.id AS id, lvl1 AS category, $name AS name, $metallPrices $way, $type, $nextName AS next_name $prevName
    FROM data $imageJoin $favorites $qPart 
    $groupBy
    ORDER BY id
    LIMIT ${limit[0]}, ${limit[1]};
    """ ;
    var dbClient = await db;
    List<DataElement> result = [];
    List<Map<String, dynamic>> maps;
    maps = await dbClient!.rawQuery(query);
    if(maps.isNotEmpty){
      for(int i = 0; i < maps.length; i++){
        result.add(DataElement.fromMap(maps[i]));
        result[i].lvl = way0.length;
      }
    }
    return result;
  }

  Future db_getSingleElement(element) async{
    String wayString = element.way + "^" + element.name;
    String query = """
    SELECT id, '${element.name}' AS name, null AS next_name, '${element.name}' AS prev_name, note, gold, silver, platinum, palladium,
    (SELECT 1 FROM storage WHERE way = '$wayString' AND storage_type = 'favorite') AS favorite
    FROM data WHERE id = ${element.id};
    """;
    var dbClient = await db;
    List<DataElement> result = [];
    List<Map<String, dynamic>> maps;
    maps = await dbClient!.rawQuery(query);
    if(maps.isNotEmpty){
      for(int i = 0; i < maps.length; i++){
        result.add(DataElement.fromMap(maps[i]));
        result[i].way = wayString;
        result[i].type = "element";
      }
    }
    return result;
  }

  // ignore: non_constant_identifier_names
  Future db_getElementsListSearch(limit, searchQuery) async{
      String query = "SELECT id, name, next_name, way, '' AS note, gold, silver, platinum, palladium, 'category' AS type FROM search WHERE (gold > 0.0 OR silver > 0.0 OR platinum > 0.0 OR palladium > 0.0) AND name like '%$searchQuery%' LIMIT ${limit[0]}, ${limit[1]}";
      var dbClient = await db;
      List<DataElement> result = [];
      List<Map<String, dynamic>> maps;
      maps = await dbClient!.rawQuery(query);
      if(maps.isNotEmpty){
        for(int i = 0; i < maps.length; i++){
          result.add(DataElement.fromMap(maps[i]));
        }
      }
      return result;
    }  





































    Future db_getLastElement(limit, element) async{
    String wayString = element.type.contains("fv_") || element.type.contains("hs_") ? element.way : element.way + "^" + element.name;

    var way = wayString == "" ? [] : wayString.split("^");
    String qPart = way.isEmpty ? "" : "WHERE";
    for(int i = 0; i < way.length; i++){
      qPart = "$qPart lvl${i + 1} = '${way[i]}' AND";
    }
    qPart = way.length == 0 ? "" : qPart.substring(0, qPart.length - 4);
    
    String query = """
    SELECT id, '${element.name}' AS name, content, null AS next_name, '${element.name}' AS prev_name,
    (SELECT 1 FROM storage WHERE way = '$wayString' AND storage_type = 'favorite') AS favorite
    FROM data $qPart;
    """;
    var dbClient = await db;
    List<DataElement> result = [];
    List<Map<String, dynamic>> maps;
    maps = await dbClient!.rawQuery(query);
    if(maps.isNotEmpty){
      for(int i = 0; i < maps.length; i++){
        result.add(DataElement.fromMap(maps[i]));
        result[i].way = wayString;
        result[i].type = "element";
      }
    }
    return result;
  } 
}