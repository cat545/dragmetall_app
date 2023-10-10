import 'package:dragmetal_app/services/analytic.dart';
import 'package:dragmetal_app/sqlite/db_helper.dart';
import 'package:dragmetal_app/sqlite/models/data.dart';
import 'package:dragmetal_app/views/category_page.dart';
import 'package:dragmetal_app/views/favorites_page.dart';
import 'package:dragmetal_app/views/single_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:core';

class StartPage extends StatefulWidget {
  StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with TickerProviderStateMixin{
  final ScrollController scrollcontroller = ScrollController();
  TextEditingController textEditingControllerSearch = TextEditingController();
  int limit_step = 20;
  late List<int> limit;
  bool isLoading = false;

  var prices;
  var pricesList;

  double? width;

  var elements;
  var elementsList;
  final int _MAX_LEVEL = 3;

  int? current_index;

  String searchQuery = "";
  AnimationController? animationControllerEmpty;
  Animation? animationEmpty;

  bool _start = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments; 
      if (arguments != null && arguments is Map<String, bool> &&  arguments["isBack"] as bool){
      }else if (!_start){
        _start = true;
        requestNewScreen("<start>");
      }
  }

  @override
  void initState() {
    startElementsList();
    super.initState();
  }

  startElementsList() async {
    limit = [0, limit_step];
    getElementsList();
    getMetallPrices();
     animationControllerEmpty = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
     animationEmpty = Tween<double>(begin: 0, end: 1).animate(animationControllerEmpty!)..addListener(() {
    setState(() {});
    });
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

  getPriceList() async {
    pricesList = [];
    prices = DBHelper().db_getPricesList();
    prices.then((data) {
      pricesList = data;
    });
  }

  getElementsList() {
    if (scrollcontroller.hasClients) {
      scrollcontroller.jumpTo(0.0);
    }
    elementsList = [];
    if (searchQuery == "") {
      elements = DBHelper().db_getElementsList(limit, "", _MAX_LEVEL, false);
    } else {
      elements = DBHelper().db_getElementsListSearch(limit, searchQuery);
    }
    elements.then((data) {
      elementsList = data;
      isLoading = false;
    });
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
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesPage()));
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

  Future<void> launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
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
            children: const [
              SizedBox.shrink()
              // IconButton(
              //     disabledColor: Colors.black45,
              //     color: Colors.white,
              //     icon: const Icon(Icons.arrow_back, size: 28),
              //     onPressed: () {
              //       setState(() {});
              //     }),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.stars, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesPage()));
                },
              ),
              // IconButton(
              //   icon: const Icon(Icons.history, color: Colors.white, size: 28),
              //   onPressed: () async {},
              // ),
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
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!isLoading && scrollInfo.metrics.extentAfter < 10) {
            setState(() {
              limit[0] = limit[0] + limit_step;

                if (searchQuery == "") {
                  elements = DBHelper().db_getElementsList(limit, "", _MAX_LEVEL, false);
                } else {
                  elements = DBHelper().db_getElementsListSearch(limit, searchQuery);
                }
              // elements = DBHelper().db_getElementsList(limit, "", _MAX_LEVEL, false);
              elements.then((data) {
                if (data.length == 0) return;
                elementsList.addAll(data);
                Future.delayed(const Duration(microseconds: 1), () {
                  isLoading = false;
                });
                int toUP = 80;
                scrollcontroller.animateTo(
                  scrollcontroller.position.pixels + toUP,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.linear,
                );
              });
              isLoading = true;
            });
          }
          return true;
        },
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
                      List<Widget> temp = [];
                      if ((snapshot.data as List).isEmpty && elementsList.isEmpty) {
                        animationControllerEmpty!.forward();
                        return SizedBox(
                            height: MediaQuery.of(context).size.height - (MediaQuery.of(context).padding.top + AppBar().preferredSize.height + MediaQuery.of(context).padding.bottom + (40 + 42 + 60)),
                            child: Center(
                                child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: Text("Нет элементов",
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.blueGrey.withOpacity(
                                        animationEmpty!.value),
                                    fontSize: 18,
                                  )),
                            )));
                      }
                      for (int i = 0; i < elementsList.length; i++) {
                        temp.add(element(elementsList[i]));
                      }
                      return SizedBox(
                        //height: MediaQuery.of(context).size.height - (MediaQuery.of(context).padding.top + AppBar().preferredSize.height + MediaQuery.of(context).padding.bottom + (40 + 42 + 60)),
                        child: ListView(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            children: temp),
                      );
                    } else {
                      return Container();
                    }
                  }),
            ),
          ),
        ),
      ),
    );
  }

  Widget element(elementPage) {
    return ListTile(
      onTap: () {
        String way = elementPage.way == "" ? elementPage.name : '${elementPage.way}^${elementPage.name}';
        if (searchQuery == ""){
          Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryPage(way: way, titlePage: elementPage.name  )));
        }else{
          Navigator.push(context, MaterialPageRoute(builder: (context) => SinglePage(way: way, titlePage: elementPage.name, singleElement: elementPage )));
        }

      },
      trailing: searchQuery == ""
          ? const Icon(Icons.folder, size: 25, color: Colors.black26)
          : const Icon(Icons.equalizer, size: 25, color: Colors.black54),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      subtitle: searchQuery == "" ? null : subtitle(elementPage),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.75,
            child: Text(elementPage.name, style: const TextStyle(color: Colors.black, fontSize: 18)),
          ),
        ],
      ),
    );
  }
  subtitle(element) {
    var sumMetals = element.gold +
        element.silver +
        element.platinum +
        element.palladium;
    var percentGold = element.gold * 100 / sumMetals;
    var percentSilver = element.silver * 100 / sumMetals;
    var percentlatinum = element.platinum * 100 / sumMetals;
    var percentPalladium = element.palladium * 100 / sumMetals;
    width = MediaQuery.of(context).size.width;
    return Row(children: [
      MyAssetsBar(
        width: width! * 0.8,
        height: 6,
        assetsLimit:
            percentGold + percentSilver + percentlatinum + percentPalladium,
        assets: [
          MyAsset(size: percentGold, color: colorFromHex("f5c400")),
          MyAsset(size: percentSilver, color: colorFromHex("9e9e9e")),
          MyAsset(size: percentlatinum, color: colorFromHex("0037ff")),
          MyAsset(size: percentPalladium, color: colorFromHex("e00909")),
        ],
      )
    ]);
  }

  

  middleBar() {
    return Container(
        width: MediaQuery.of(context).size.width,
        height: 40.0,
        color: Colors.blue[600],
        child: SizedBox(
            child: Center(
          child: Container(
            height: 30,
            width:
                MediaQuery.of(context).size.width * 0.95,
            decoration: const BoxDecoration(
                color: Colors.white30,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(
                    Radius.circular(10.0))),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: textEditingControllerSearch,
                    onSubmitted: (text) {
                      requestNewScreen("<search page> <query> $text");
                      setState(() {
                        limit = [0, limit_step];
                        searchQuery = text;
                        getElementsList();
                        // elementsList = [];
                        // limit[0] = limit_step;
                        // elements = DBHelper()
                        //     .db_getElementsListSearch(limit, searchQuery);
                        // elements.then((data) {
                        //   elementsList = data;
                        // });

                      });
                    },
                    style: const TextStyle(
                        height: 1.0,
                        color: Colors.white,
                        fontSize: 22),
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(
                              vertical: -5),
                      prefixIcon: Icon(Icons.search,
                          size: 22,
                          color: Colors.blue[900]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12.0),
                  child: GestureDetector(
                    child: const Icon(
                      Icons.cancel,
                      size: 24,
                      color: Colors.white,
                    ),
                    onTap: () {
                    if (textEditingControllerSearch.text != "") {
                      setState(() {
                        textEditingControllerSearch.text = "";
                        searchQuery = "";
                        elementsList = [];
                        limit = [0, limit_step];
                        getElementsList();
                      });
                    }
                  },
                  ),
                )
              ],
            ),
          ),
        )));
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


// class ChartData {
//   ChartData(this.x, this.y, this.color);

//   final String x;
//   final double y;
//   final Color color;
// }

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
        // Row(
        //     children: assets.map((singleAsset) => _createSingle(singleAsset)).toList()
        // ),
        Row(
          children: assets?.map((singleAsset) => _createSingle(singleAsset)).toList() ?? [],
        ),
      ),
    );
  }
}