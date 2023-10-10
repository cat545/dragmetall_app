import 'storage_manager.dart';
import 'package:http/http.dart' as http;

requestNewScreen(page) async{
  String appName = "dragmetall app";
  page = page.toLowerCase();
  String version = "1";
  appName = "$appName;$version";
  String userId = await StorageManager.readDataList("userId");
  String sessionId = await StorageManager.readDataList("sessionId");
  String queryCrypt = "${toCrypt("appName", appName)}*${toCrypt("page", page)}-$sessionId@$userId";
  var url = Uri.https('pozdrav.su', '/helper.php', {'data': queryCrypt});
  http.get(url);
}

toCrypt(itemToCrypt, valueToCrypt){
  var cryptoMap = {};
  switch (itemToCrypt) {
    case "appName":
       cryptoMap  = {'<':'|', '>':'[', '#':'#', 'a':'4', 'b':'5', 'c':'d', 'd':'1', 'e':'l', 'f':'f', 'g':'b', 'h':'p', 'i':'w', 'j':'8', 'k':'g', 'l':'s', 'm':'6', 'n':'i', 'o':'9', 'p':'m', 'q':'3', 'r':'7', 's':'0', 't':'n', 'u':'z', 'v':'t', 'w':'2', 'x':'x', 'y':'a', 'z':'j', '0':'h', '1':'u', '2':'o', '3':'v', '4':'q', '5':'y', '6':'k', '7':'e', '8':'c', '9':'r', '^':'`', ' ':'!', ';':'_', '_':';'};
      break;
    case "page":
      cryptoMap   = {'<':'|', '>':'[', '#':'#', 'a':'r', 'b':'3', 'c':'s', 'd':'m', 'e':'2', 'f':'e', 'g':'c', 'h':'x', 'i':'k', 'j':'5', 'k':'n', 'l':'p', 'm':'o', 'n':'q', 'o':'h', 'p':'j', 'q':'f', 'r':'i', 's':'b', 't':'z', 'u':'9', 'v':'g', 'w':'d', 'x':'4', 'y':'1', 'z':'a', '0':'8', '1':'6', '2':'v', '3':'0', '4':'l', '5':'7', '6':'y', '7':'t', '8':'u', '9':'w', '^':'`', ' ':')', ';':'_', '_':';'};
      break;
  }
  
  String crypted = "";
  if (cryptoMap.isNotEmpty){
    for (int i = 0; i < valueToCrypt.length; i++) {
      String letter = valueToCrypt[i];
      crypted += cryptoMap[letter] == null ? "#" : cryptoMap[letter].toString();
    }
  }else{
    crypted = valueToCrypt;
  }
  return crypted;
}