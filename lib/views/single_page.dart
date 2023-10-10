import 'package:dragmetal_app/services/analytic.dart';
import 'package:dragmetal_app/sqlite/db_helper.dart';
import 'package:dragmetal_app/sqlite/models/data.dart';
import 'package:dragmetal_app/views/favorites_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:core';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:url_launcher/url_launcher.dart';

class SinglePage extends StatefulWidget {
  
  String? way;
  String? titlePage;
  DataElement? singleElement;
  SinglePage({Key? key, this.way, this.titlePage, this.singleElement}) : super(key: key);

  bool isPageOpen = false;

  @override
  State<SinglePage> createState() => _SinglePageState();
}

class _SinglePageState extends State<SinglePage> {
  final ScrollController scrollcontroller = ScrollController();

  int limit_step = 20;
  late List<int> limit;
  bool isLoading = false;

  Future<dynamic>? prices;
  var pricesList;

  double? width;

  var elements;
  var elementsList;
  final int _MAX_LEVEL = 3;

  int? current_index;

  @override
  void initState() {
    requestNewScreen("<single page>");
    startElementsList();
    getPriceList();
    super.initState();
  }

  startElementsList() async {
    limit = [0, limit_step];
    getElementsList();
  }

  getMetallPrices() async {
    var mPriceList = [];
    var url = Uri.https('pozdrav.su', '/metall-prices.php', {'q': '{http}'});
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        try {
          var allData = (convert.jsonDecode(response.body) as Map)['data'] as Map<String, dynamic>;
          allData.forEach((String key, dynamic value) {
            double? priceDouble = double.tryParse(value['price'].toString());
            if (priceDouble != null){
              var record = MPrice(date: value['date'], metall: value['code'], price: priceDouble);
              mPriceList.add(record);
            }
          });
          if (mPriceList.isNotEmpty){
              print("Перед записью цен");
              await DBHelper().db_setPrices(mPriceList);
            }
        } on FormatException catch (e) {
          print('The provided string is not valid JSON');
        }
      }
    } on SocketException catch (_) {
      print('Not connected');
    }
  }

  Future getPriceList() async{
    pricesList = [];
    prices = DBHelper().db_getPricesList();
    prices!.then((data) {
      pricesList = data;
    });
  }

  getElementsList() {
    if (scrollcontroller.hasClients) {
      scrollcontroller.jumpTo(0.0);
    }
    elementsList = [];
    //elements = DBHelper().db_getElementsList(limit, widget.way, _MAX_LEVEL, false);
    elements = DBHelper().db_getSingleElement(widget.singleElement);
    elements.then((data) {
      elementsList = data;
      isLoading = false;
    });
  }

  Future<void> launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage('assets/images/dragmetals.jpg'))),
              child: Container(),
            ),
            ListTile(
              leading: Icon(Icons.poll_outlined, color: Colors.orange[500]),
              title: Text('Курсы ЦБ на драгметаллы',
                  style: TextStyle(color: Colors.blue[900], fontSize: 18)),
              onTap: () async{
                requestNewScreen("<price form page>");
                await showPriceFrom(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.verified_user, color: Colors.green[600]),
              title: Text('Private Policy',
                  style: TextStyle(color: Colors.blue[900], fontSize: 18)),
              onTap: () async {
                Navigator.pop(context); 
                final Uri url = Uri.parse('https://pozdrav.su/privacy-policy/');
                  launchInBrowser(url);
                },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.stars, color: Colors.blue[900]),
              title:
                  Text('Избраннное', style: TextStyle(color: Colors.blue[900], fontSize: 18)),
              onTap: () async{
                Navigator.pop(context);
                
                var result = await Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesPage(fromSingle: true)));
                if (result != null){
                  widget.titlePage = result["titlePage"];
                  widget.way = result["way"];
                  widget.singleElement = result["singleElement"];
                }
                  await getElementsList();
                  setState(() { });
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.blue[600],
      body: Builder(
          builder: (context) => SafeArea(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        upAppBar(context),
                        middleBar(),
                        mainBody(),
                                ],
                              ),
                  ))),
    );
  }

  upAppBar(context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 42.0,
      color: Colors.blue[600],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                  disabledColor: Colors.black45,
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () {
                    Navigator.pop(context); 
                  }),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.stars, color: Colors.white, size: 28),
                onPressed: () async{
                  var result = await Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesPage(fromSingle: true)));
                  if (result != null){
                    widget.titlePage = result["titlePage"];
                    widget.way = result["way"];
                    widget.singleElement = result["singleElement"];
                  }
                    await getElementsList();
                    setState(() { });
                },
              ),
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  mainBody() {
    return Expanded(
      child: RawScrollbar(
        thumbColor: Colors.blue[300],
        thickness: 3,
        controller: scrollcontroller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollcontroller,
          physics: const ScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder(
                future: elements,
                builder: (context, snapshot) {
                  if (snapshot.hasData) { 
                    if ((snapshot.data as List).isEmpty && elementsList.isEmpty) {
                      return Container();
                    }
                    return FutureBuilder(
                      future: prices,
                      builder: (context, snapshot2) {
                        if (snapshot2.hasData && snapshot.hasData) { 
                          if ((snapshot2.data as List).isEmpty || elementsList.isEmpty) {
                            return Container(); //цена до сих пор не получена
                          }
                          var data = [
                              ChartData('Золото',   elementsList[0].gold, colorFromHex("f5c400")),
                              ChartData('Серебро',  elementsList[0].silver, colorFromHex("9e9e9e")),
                              ChartData('Платина',  elementsList[0].platinum, colorFromHex("0037ff")),
                              ChartData('МГП',      elementsList[0].palladium, colorFromHex("e00909")),
                            ];
                          var tooltip = TooltipBehavior(enable: true);
                          var wayArr = (elementsList[0].way).split("^");
                          double max = 0.0;
                          max = elementsList[0].gold > max
                              ? elementsList[0].gold
                              : max;
                          max = elementsList[0].silver > max
                              ? elementsList[0].silver
                              : max;
                          max = elementsList[0].platinum > max
                              ? elementsList[0].platinum
                              : max;
                          max = elementsList[0].palladium > max
                              ? elementsList[0].palladium
                              : max;
                          max = max * 0.15 + max;
                          double price = 0.0;
                          for (var i = 0; i < pricesList.length; i++) {
                            if (pricesList[i].code == 1) {
                              price += pricesList[i].price * elementsList[0].gold;
                            } else if (pricesList[i].code == 2) {
                              price += pricesList[i].price * elementsList[0].silver;
                            } else if (pricesList[i].code == 3) {
                              price += pricesList[i].price * elementsList[0].platinum + pricesList[i].price * elementsList[0].palladium;
                            }
                          }
                          Icon iconFavorite = elementsList[0].favorite == 1 ? Icon(Icons.star_rate, color: Colors.amberAccent[400]) : 
                            Icon(Icons.star_border_outlined, color: Colors.blue[600]);
                          return Padding(
                          padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                            GestureDetector(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blue),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10.0),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IntrinsicWidth(
                                      child: Row(
                                        children: [
                                          iconFavorite,
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Избранное",
                                            style: TextStyle(color: Colors.blue, fontSize: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ),
                                    ),
                              onTap: () {
                                
                                if (elementsList[0].favorite == 1){
                                  requestNewScreen("<single page> <button> fav del ${elementsList[0].id}");
                                  elementsList[0].favorite = 0;
                                  DBHelper().db_delFavorite(elementsList[0].way);
                                }else{
                                  requestNewScreen("<single page> <button> fav add ${elementsList[0].id}");
                                  elementsList[0].favorite = 1;
                                  DBHelper().db_setFavorite(elementsList[0]);
                                }
                                setState(() {
                                });  
                              }),
                              const SizedBox(height: 16),
                            Text(
                              "${wayArr[wayArr.length - 2]}: ${wayArr[wayArr.length - 1]}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            SfCartesianChart(
                                title: ChartTitle(
                                    text:
                                        "Таблица содержания драгоценных металлов:"),
                                primaryXAxis: CategoryAxis(),
                                primaryYAxis: NumericAxis(
                                    minimum: 0,
                                    maximum: max,
                                    interval: max / 4),
                                tooltipBehavior: tooltip,
                                series: <ChartSeries<ChartData, String>>[
                                  ColumnSeries<ChartData, String>(
                                      dataLabelSettings:
                                          const DataLabelSettings(
                                              isVisible: true),
                                      dataSource: data,
                                      xValueMapper:
                                          (ChartData data, _) => data.x,
                                      yValueMapper:
                                          (ChartData data, _) => data.y,
                                      name: elementsList[0].name,
                                      pointColorMapper:
                                          (ChartData data, _) =>
                                              data.color),
                                ]),
                            price > 0
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10)),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.all(8.0),
                                          child: Text(
                                              "${price.toStringAsFixed(2)} рублей — точная стоимость чистых драгоценных металлов в ${wayArr[wayArr.length - 1]} по курсу ЦБ РФ.",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color:
                                                      Colors.lime[900])),
                                        )),
                                  )
                                : const SizedBox.shrink(),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      "Золото: ${elementsList[0].gold} гр.",
                                      style: const TextStyle(fontSize: 18)),
                                )),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      "Серебро: ${elementsList[0].silver} гр.",
                                      style: const TextStyle(fontSize: 18)),
                                )),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      "Платина: ${elementsList[0].platinum} гр.",
                                      style: const TextStyle(fontSize: 18)),
                                )),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      "МГП: ${elementsList[0].palladium} гр.",
                                      style: const TextStyle(fontSize: 18)),
                                )),
                              ],
                            ),
                          );

                        } else {
                          //return Text("вышел"); //цена до сих пор не получена
                          return Container();
                        }
                      }
                    );
                    
                  } else {
                    return Container();
                  }
                }),
          ),
        ),
      ),
    );
  }





  titleSize(width){
    if(width >= 410){
      return [18.0, 35.0];
    }else{
      double sz = 411.0 - width;
      return [18 - sz/22.75, 35 - sz/9.1];
    }
  }

  middleBar() {
    List<double> _tSz = titleSize(MediaQuery.of(context).size.width);
    return Container(
        width: MediaQuery.of(context).size.width,
        height: 40.0,
        color: Colors.blue[600],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(children: [
                 const SizedBox(width: 8),
                 const Icon(Icons.equalizer, color: Colors.white38),
                 const SizedBox(width: 8),
                Text(
                    widget.titlePage.toString(),
                    style: TextStyle(
                        fontSize: _tSz[0],
                        fontWeight: FontWeight.w500,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
                ]),
            )
          ],
        )
    );
  }
  

  metallPrice(el) {
    String image = "au";
    if (el.code == 1) {
      image = "au";
    } else if (el.code == 2) {
      image = "ag";
    } else if (el.code == 3) {
      image = "pt";
    } else if (el.code == 4) {
      image = "pd";
    }
    return SizedBox(
      height: MediaQuery.of(context).size.width * 0.15,
      child: Row(
        children: [
          Container(
              width: MediaQuery.of(context).size.width * 0.15,
              height: MediaQuery.of(context).size.width * 0.15,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage('assets/images/$image.jpg')))),
          const SizedBox(width: 20),
          Text(el.price.toString(),
              style: const TextStyle(fontSize: 20, color: Colors.blueAccent))
        ],
      ),
    );
  }

  Future<void> showPriceFrom(BuildContext context) async {
    await getMetallPrices();
    await getPriceList();
    // ignore: use_build_context_synchronously
    return await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return FutureBuilder(
                future: prices,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    String title = pricesList.length > 0
                        ? "на ${pricesList[0].date}"
                        : "";
                    List<Widget> tmp = [];
                    for (var i = 0; i < pricesList.length; i++) {
                      tmp.add(metallPrice(pricesList[i]));
                    }
                    if (tmp.isEmpty) {
                      tmp.add(const Center(child: Text("Сервис недоступен")));
                    }
                    return AlertDialog(
                      title: Center(
                          child: Text("Курс ЦБ $title",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.blue[900]))),
                      content: Form(
                          child: SizedBox(
                        height: title == ""
                            ? MediaQuery.of(context).size.width * 0.1
                            : 4 * MediaQuery.of(context).size.width * 0.15,
                        child: Column(
                          children: tmp,
                        ),
                      )),
                      actions: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                          width: MediaQuery.of(context).size.width * 0.33 - 22,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Color.fromARGB(255, 66, 116, 160).withOpacity(0.5)),
                                            color: Colors.blueAccent,
                                            borderRadius: const BorderRadius.all(
                                              Radius.circular(10.0),
                                            ),
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Center(
                                                child: Text(
                                              "Закрыть",
                                              style: TextStyle(color: Colors.white, fontSize: 18),
                                            )),
                                          )),
                                    ),
                              onTap: () {
                                Navigator.of(context).pop();
                              }),
                          ],
                        )
                      ],
                    );
                  } else {
                    return Container();
                  }
                });
          });
        });
  }
}

class ChartData {
  ChartData(this.x, this.y, this.color);

  final String x;
  final double y;
  final Color color;
}

Color colorFromHex(String hexColor) {
  final hexCode = hexColor.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}

const double _kHeight = 5;
enum OrderType { Ascending, Descending, None }
/*Utils*/

class MyAsset {
  final double? size;
  final Color? color;

  MyAsset({this.size, this.color});
}

class MyAssetsBar extends StatelessWidget {
  const MyAssetsBar(
      {Key? key,
      @required this.width,
      this.height = _kHeight,
      this.radius,
      this.assets,
      this.assetsLimit,
      this.order,
      this.background = Colors.grey})
      : assert(width != null),
        assert(assets != null),
        super(key: key);

  final double? width;
  final double? height;
  final double? radius;
  final List<MyAsset>? assets;
  final double? assetsLimit;
  final OrderType? order;
  final Color? background;

  double _getValuesSum() {
    double sum = 0;
    for (var single in assets!) {
      sum += single.size!;
    }
    return sum;
  }

  void orderMyAssetsList() {
    switch (order) {
      case OrderType.Ascending:
        {
          //From the smallest to the largest
          assets?.sort((a, b) {
            return a.size!.compareTo(b.size!);
          });
          break;
        }
      case OrderType.Descending:
        {
          //From largest to smallest
          assets?.sort((a, b) {
            return b.size!.compareTo(a.size!);
          });
          break;
        }
      case OrderType.None:
      default:
        {
          break;
        }
    }
  }

  Widget _createSingle(MyAsset singleAsset) {
    return SizedBox(
      width: (singleAsset.size! * (width!)) / (assetsLimit ?? _getValuesSum()),
      child: Container(color: singleAsset.color),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (assetsLimit != null && assetsLimit! < _getValuesSum()) {
      print("assetsSum < _getValuesSum() - Check your values!");
      return Container();
    }

    orderMyAssetsList();

    final double rad = radius ?? (height! / 2);
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(rad)),
      child: Container(
        decoration: BoxDecoration(
          color: background,
        ),
        width: width,
        height: height,
        child: 
        Row(
          children: assets?.map((singleAsset) => _createSingle(singleAsset)).toList() ?? [],
        ),
      ),
    );
  }
}