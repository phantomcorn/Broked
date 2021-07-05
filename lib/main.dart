import 'dart:math';
import 'package:broked/Database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:animated_button/animated_button.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import "Database.dart";
import "Theme.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]
  );

  runApp(MyApp());
}

AudioCache player = AudioCache();

class MyApp extends StatelessWidget {
  
  static final positiveRealOneDP = RegExp(r"^\d*(\.\d)?$");
  
  static final Map<String,Map<String,dynamic>> theme = {
    "grey" : {
      "bg" : Colors.white,
      "text" : Color.fromRGBO(105, 105, 105, 1),
      "buttonText" : Colors.white,
      "hintText" : Color.fromRGBO(211, 211, 211, 1),
      "inputBorder" : Color.fromRGBO(211, 211, 211, 1),
      "dateButton" : Color.fromRGBO(128, 128, 128, 1),
      "brokeButton" : Color.fromRGBO(169, 169, 169, 1),
      "budgetButton" : Color.fromRGBO(169, 169, 169, 1),
      "sumButton" : Color.fromRGBO(169, 169, 169, 1),
      "deleteYes" : Color.fromRGBO(46,139,87, 1),
      "deleteNo" : Color.fromRGBO(128, 0, 0, 1),
      "dialogShadow" : Colors.black,
      "navBar" : Colors.white,
      "navSelected" : Color.fromRGBO(105, 105, 105, 1),
      "grid" : Color.fromRGBO(211, 211, 211, 1),
      "soundDef" : "greyDefault.mp3",
      "soundSucc" : "greySucc.mp3"
    },
    "retro" : {
      "bg" : Colors.black,
      "text" : Color.fromRGBO(224,231,34, 1),
      "buttonText" : Colors.black,
      "hintText" : Color.fromRGBO(224,231,34, 1),
      "inputBorder" : Color.fromRGBO(224,231,34, 1),
      "dateButton" : Color.fromRGBO(0, 255, 255, 1),
      "brokeButton" : Color.fromRGBO(254, 1, 254, 1),
      "budgetButton" : Color.fromRGBO(255, 7, 58, 1),
      "sumButton" : Color.fromRGBO(255, 7, 58, 1),
      "deleteYes" : Color.fromRGBO(57, 255, 20, 1),
      "deleteNo" : Color.fromRGBO( 255, 7, 58, 1),
      "dialogShadow" : Color.fromRGBO(57, 255, 20, 1),
      "navBar" : Colors.black,
      "navSelected" : Color.fromRGBO(224, 231, 34, 1),
      "grid" : Color.fromRGBO(224,231,34, 1),
      "soundDef" : "retroDefault.wav",
      "soundSucc" : "retroSucc.wav"
    }
  };

  static String selectedTheme = "grey";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child : MaterialApp(
        title: 'Broked', 
        theme: customTheme.defaultTheme,
        home: MyHomePage(title: 'Broked'),
      )
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {


  int _selectedDisplay = 0;
  static const List<Widget> _displayOptions = <Widget>[
    BrokeMain(),
    Analytics()
  ];

  void onTabTapped (int index) {
    setState(() {
      _selectedDisplay = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child : _displayOptions.elementAt(_selectedDisplay)
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label : "input"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label : "analytics"
          )
        ],
        currentIndex: _selectedDisplay,
        onTap: onTabTapped,
        backgroundColor: MyApp.theme[MyApp.selectedTheme]!["navBar"],
        selectedItemColor: MyApp.theme[MyApp.selectedTheme]!["navSelected"],
        unselectedItemColor: Color.fromRGBO(220, 220, 220, 1)
      ),
    );
  }
}

class BrokeMain extends StatefulWidget {
  const BrokeMain({ Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BrokeMain();

}

class _BrokeMain extends State<BrokeMain> with SingleTickerProviderStateMixin {

  DateTime _date = DateTime.now();
  late AnimationController _controller;
  

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500)
    );


    _controller.addStatusListener( (status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget budgetButton(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)
                    ),
                    elevation: 0,
                    backgroundColor: Colors.white,
                    child: LessBroke()
                );
              }
          );
        },
        child: Text(
            "Go LESS Broked",
            style: TextStyle(
                color: MyApp.theme[MyApp.selectedTheme]!["buttonText"]
            )
        ),
        style: ElevatedButton.styleFrom(
            primary: MyApp.theme[MyApp.selectedTheme]!["budgetButton"]
        )
    );
  }

  Widget brokeButton() {
    return AnimatedButton(
      onPressed: () async {
        if (MyApp.positiveRealOneDP.hasMatch(InputAmount.amountController.text)
          && InputAmount.amountController.text != '') {
          player.play(MyApp.theme[MyApp.selectedTheme]!["soundSucc"]);
          await SpentDatabase.instance.accumulateAmount(
              Spent(
                  date: _date,
                  amount: double.parse(InputAmount.amountController.text)
              )
          );
        } else {
          _controller.forward();
          player.play(MyApp.theme[MyApp.selectedTheme]!["soundDef"]);
        }
        InputAmount.amountController.clear();
      },
      child: Text(
        "BROKE!",
        style: TextStyle(
            fontSize: MediaQuery.of(context).size.width / 15,
            color: MyApp.theme[MyApp.selectedTheme]!["buttonText"]
        ),
      ),
      color: MyApp.theme[MyApp.selectedTheme]!["brokeButton"],
      width: MediaQuery.of(context).size.width / 1.2,
      height: MediaQuery.of(context).size.height / 8.5,
    );
  }

  Widget datePicker() {
    return TextButton(
      onPressed : () {
        DatePicker.showDatePicker(
          context,
          showTitleActions: true,
          currentTime: _date,
          minTime: DateTime(2000),
          maxTime: DateTime.now(),
          onConfirm: (date) {
            setState(() =>
              _date = date
            );
          }
        );
      },
      child : Text(
          "${DateFormat('dd MMM yyyy').format(_date)}",
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width / 15
          ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return SafeArea(
      child : Scaffold(
        body: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child : Column(
            children: <Widget> [
              Container(
                height: height / 15,
                margin: EdgeInsets.fromLTRB(20, 20, 20, height / 7),
                child : Row(
                  children: [
                    Spacer(),
                    budgetButton(context)
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                )
              ),
              Container(
                width: MediaQuery.of(context).size.width / 2.2,
                height : height / 16,
                child : datePicker()
              ),
              InputAmount(
                  controller: _controller
              ),
              Container(
                child : brokeButton()
              )
            ],
            mainAxisAlignment: MainAxisAlignment.start
          ),
        ),
      ),
    );
  }

}



class Analytics extends StatefulWidget {
  const Analytics({ Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Analytics();

}

class _Analytics extends State<Analytics> {

  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        body: Center(
          child : Container(
            child : Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child : IconButton(
                    icon : Icon(Icons.delete),
                    color: Color.fromRGBO(220, 220, 220, 1),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                BorderRadius.circular(10),
                            ),
                            elevation: 0,
                            backgroundColor: Colors.white,
                            child: resetDialog(context, width, height),
                          );
                        }
                      );
                    }
                  )
                ),
                Container(
                  child : Column(
                    children: [
                      Container(
                          child : Text("analytics",
                              style: TextStyle(
                                  fontSize: width * 0.04
                              )
                          ),
                          margin: EdgeInsets.only(bottom : height / 30)
                      ),
                      FutureBuilder(
                          future: SpentDatabase.instance.getBudgetByDate(_date),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("budget: ",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)}",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("budget: ",
                                  style: TextStyle(
                                      fontSize: width * 0.035,
                                      color : MyApp.theme[MyApp.selectedTheme]!["text"]
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: height / 40),
                      FutureBuilder(
                          future: SpentDatabase.instance.getSpendingByDate(_date),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("spent today: ",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)}",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("spent today: ",
                                  style: TextStyle(
                                      fontSize: width * 0.035
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: height / 40),
                      FutureBuilder(
                          future: SpentDatabase.instance.getSpendingByDate(_date),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("spent this month: ",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)}",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("spent this month: ",
                                  style: TextStyle(
                                      fontSize: width * 0.035
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: height / 40),
                      FutureBuilder(
                          future: SpentDatabase.instance.getAvgSpending(_date),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("avg spending this month: ",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)}",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("avg spending this month: ",
                                  style: TextStyle(
                                      fontSize: width * 0.035
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: height / 40),
                      FutureBuilder(
                          future: SpentDatabase.instance.getTargetByDate(_date),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("saving target this month: ",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)}",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("saving target this month: ",
                                  style: TextStyle(
                                      fontSize: width * 0.035
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: height / 40),
                      FutureBuilder(
                          future: SpentDatabase.instance.getSpendingPerDayToHitTarget(_date),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("to hit saving target: ",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)} / day",
                                        style: TextStyle(
                                            fontSize: width * 0.035
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("to hit saving target: ",
                                  style: TextStyle(
                                      fontSize: width * 0.035
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: height / 40),
                      FutureBuilder(
                          future: SpentDatabase.instance.getOverUnderSpent(_date),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                children: [
                                  Text("leftover: ",
                                      style: TextStyle(
                                          fontSize: width * 0.035
                                      )
                                  ),
                                  Spacer(),
                                  Text("${snapshot.data!.toStringAsFixed(1)}",
                                    style: TextStyle(
                                      color: (snapshot.data! > 0) ?
                                        Color.fromRGBO(50, 205, 50, 1)
                                          : (snapshot.data! < 0) ?
                                        Color.fromRGBO(221, 0, 4, 1)
                                          : MyApp.theme[MyApp.selectedTheme]!["text"],
                                      fontSize: width * 0.035
                                    )
                                  )
                                ],
                              );
                            } else {
                              return Text(
                                  "leftover: ",
                                  style: TextStyle(
                                      color: MyApp.theme[MyApp.selectedTheme]!["text"],
                                      fontSize: width * 0.035
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height : height / 40),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                  margin: EdgeInsets.only(left : width / 5, right : width / 5)
                ),
                FutureBuilder(
                    future : Future.wait([
                      SpentDatabase.instance.getAllSpentInAMonth(_date.month),
                      SpentDatabase.instance.getSpendingPerDayToHitTarget(_date)
                    ]),
                    builder : (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                      if (snapshot.hasData) {
                        List<Spent> spents = snapshot.data![0];
                        double spendPerDay = double.parse(snapshot.data![1].toStringAsFixed(1));
                        if (spents.isNotEmpty || spendPerDay != 0) {
                          return Container(
                              padding: EdgeInsets.all(20),
                              margin: EdgeInsets.only(left: 30, right: 30),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.blueAccent
                                  ),
                                  borderRadius: BorderRadius.circular(18)
                              ),
                              width: MediaQuery.of(context).size.width / 1.1,
                              height: MediaQuery.of(context).size.height / 3,
                              child: lineChart(spents, spendPerDay)
                          );
                        } else {
                          return Container(
                              margin: EdgeInsets.only(left: 30, right: 30),
                              decoration: BoxDecoration(
                                  color: MyApp.theme[MyApp.selectedTheme]!["text"],
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              width: MediaQuery.of(context).size.width / 1.1,
                              height: MediaQuery.of(context).size.height / 3,
                              child: Align(
                                alignment: Alignment.center,
                                child : Text("Add in budget and a saving target first to see graph",
                                  style: TextStyle(
                                      color: Colors.white
                                  ),
                                ),
                              )
                          );
                        }
                      } else {
                        return Text("Error fetching data from database");
                      }
                    }
                )
              ],
            ),
          )
        ),
      )
    );
  }

  Widget lineChart(List<Spent> spents, double spendPerDay) {
    String monthYear = "${spents.first.date.month}/${spents.first.date.year}";
    double maxSpent = spents.map((spent) => spent.amount).reduce(max);
    double minSpent = spents.map((spent) => spent.amount).reduce(min);
    double maxDayInSpent = spents.map((spent) => spent.date.day).reduce(max).toDouble();

    List<HorizontalLine> spendingPerDay = [
      HorizontalLine(y: spendPerDay)
    ];

    List<FlSpot> coordinates = [];

    for (Spent spent in spents) {
      //print("(${spent.date.day} , ${spent.amount})");
      coordinates.add(
          FlSpot(
              spent.date.day.toDouble(),
              spent.amount
          )
      );
    }
    return LineChart(
        LineChartData(
            gridData: FlGridData(
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: MyApp.theme[MyApp.selectedTheme]!["grid"],
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: MyApp.theme[MyApp.selectedTheme]!["grid"],
                  strokeWidth: 1,
                );
              },
            ),
            minY: (minSpent.floorToDouble() > spendPerDay)
                ? 0
                : minSpent.floorToDouble(),
            maxY: (maxSpent.ceilToDouble() > spendPerDay)
                ? maxSpent.ceilToDouble() + 1
                : spendPerDay.ceilToDouble() * 10,
            minX: 1,
            maxX: maxDayInSpent,
            lineBarsData: [
              LineChartBarData(
                  spots: coordinates,
                  barWidth: 2
              )
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    final textStyle = TextStyle(
                      color: touchedSpot.bar.colors[0],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    );
                    return LineTooltipItem(
                      "${touchedSpot.x.toInt()}/$monthYear : ${touchedSpot.y}",
                      textStyle
                    );
                  }).toList();
                }
              )
            ),
            extraLinesData: ExtraLinesData(
                horizontalLines: spendingPerDay
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTextStyles: (value) => TextStyle(
                    color: MyApp.theme[MyApp.selectedTheme]!["text"],
                    fontSize: 10
                ),
                getTitles: (value) {
                  if (value.toInt() % 2 == 1) {
                    return value.toStringAsFixed(0);
                  }
                  return '';
                },
                margin: 8,
              ),
              leftTitles: SideTitles(
                showTitles: true,
                getTextStyles: (value) => TextStyle(
                  color: MyApp.theme[MyApp.selectedTheme]!["text"],
                  fontSize: 10
                ),
                reservedSize: 28,
                margin: 8,
              ),
            ),
            axisTitleData: FlAxisTitleData(
              leftTitle: AxisTitle(
                showTitle: true,
                titleText: "Spent",
                textStyle: TextStyle(
                  color : MyApp.theme[MyApp.selectedTheme]!["text"],
                  fontWeight: FontWeight.bold
                )
              ),
              bottomTitle: AxisTitle(
                  showTitle: true,
                  titleText: "Day",
                  textStyle: TextStyle(
                      color : MyApp.theme[MyApp.selectedTheme]!["text"],
                      fontWeight: FontWeight.bold
                  )
              )
            ),
            borderData: FlBorderData(
              border : const Border(
                bottom: BorderSide(
                  color: Colors.black,
                ),
                left: BorderSide(
                  color: Colors.black,
                ),
                right: BorderSide(
                  color: Colors.black,
                ),
                top: BorderSide(
                  color: Colors.black,
                ),
              ),
            )
        ),
        swapAnimationCurve: Curves.bounceIn,
        swapAnimationDuration: Duration(milliseconds: 300),
    );
  }

  Widget resetDialog(BuildContext context, double width, double height) {
    return Stack(
      children: <Widget>[
        Container (
          padding: EdgeInsets.all(width / 35),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: MyApp.theme[MyApp.selectedTheme]!["dialogShadow"],
                    offset: Offset(0,10),
                    blurRadius: 10
                ),
              ]
          ),
          width: width / 1.1,
          height : height / 4,
          child : Column(
            children: [
              Text("Reset Database",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: width * 0.04
                )
              ),
              SizedBox(height : height / 22),
              Text("All input data you've previously entered will be erased. Are you sure?",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: width * 0.036
                )
              ),
              SizedBox(height : height / 20),
              Row(
                children: [
                  AnimatedButton(
                      onPressed: () async {
                        player.play(MyApp.theme[MyApp.selectedTheme]!["soundDef"]);
                        await SpentDatabase.instance.deleteAllRecords();
                        setState(() {
                        });
                        Navigator.pop(context);
                      },
                      child : Text("YES",
                        style: TextStyle(
                          color: MyApp.theme[MyApp.selectedTheme]!["buttonText"]
                        )
                      ),
                      color: MyApp.theme[MyApp.selectedTheme]!["deleteYes"]!,
                      width: width / 4,
                      height: height / 30
                  ),
                  AnimatedButton(
                      onPressed: () {
                        player.play(MyApp.theme[MyApp.selectedTheme]!["soundDef"]);
                        Navigator.pop(context);
                      },
                      child: Text("NO",
                        style: TextStyle(
                          color: MyApp.theme[MyApp.selectedTheme]!["buttonText"]
                        )
                      ),
                      color: MyApp.theme[MyApp.selectedTheme]!["deleteNo"]!,
                      width: width / 4,
                      height: height / 30
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              )
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        )
      ],
    );
  }

}


class InputAmount extends StatelessWidget {

  static TextEditingController amountController = TextEditingController();
  final AnimationController controller;
  final Animation _offsetAnimation;
  final Animation _colorAnimation;

  InputAmount({required this.controller})
  : _offsetAnimation = Tween(
      begin : 0.0,
      end : 30.0
    ).chain(
      CurveTween(
          curve: Curves.elasticIn
      )
    ).animate(controller),


    _colorAnimation = ColorTween(
      begin : MyApp.theme[MyApp.selectedTheme]!["inputBorder"],
      end: Colors.redAccent
    ).animate(controller);


  Widget inputAmount(context) {
    double textSize = MediaQuery.of(context).size.width / 16;
    return TextFormField(
        controller: amountController,
        keyboardType: TextInputType.numberWithOptions(
            decimal: true,
            signed: false
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(r"[\d.]+")
          ),
          LengthLimitingTextInputFormatter(8),
        ],
        decoration: InputDecoration(
            hintText: 'Amount (1 D.P)',
            hintStyle: TextStyle(
                color: MyApp.theme[MyApp.selectedTheme]!["hintText"],
                fontSize: textSize
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: InputBorder.none,

        ),
        style: TextStyle(
            fontSize: textSize,
            color: MyApp.theme[MyApp.selectedTheme]!["text"]
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation : controller,
        builder : (context, child) {
          return Container(
            width: MediaQuery.of(context).size.width / 1.4,
            height: MediaQuery.of(context).size.height / 11,
            margin: EdgeInsets.only(
                bottom: 50,
                top: 30,
                left: _offsetAnimation.value + 30.0,
                right: 30.0 - _offsetAnimation.value
            ),
            decoration: BoxDecoration(
                border: Border.all(
                    color: _colorAnimation.value,
                    width: 4
                ),
                borderRadius: BorderRadius.circular(10)
            ),
            child: child
          );
        },
        child: Align(
          alignment: Alignment.center,
          child: inputAmount(context) ,
        )
    );
  }
}

class LessBroke extends StatefulWidget {

  LessBroke({Key? key}) : super(key: key);

  @override
  _LessBrokeState createState() => _LessBrokeState();
}


class _LessBrokeState extends State<LessBroke> {

  final budgetController = TextEditingController();
  final targetController = TextEditingController();
  final PageController pageController = PageController(initialPage: 0);
  double? sliderValue;


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
        width: width / 1.1,
        height : height / 3.4,
        child : Stack(
            children : [
              PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: pageController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    budget(context, width, height),
                    savingTarget(context, width, height)
                  ]
              )
            ]
        )
    );
  }

  Widget inputBudget(BuildContext context) {
    return TextFormField(
      controller: budgetController,
      keyboardType: TextInputType.numberWithOptions(
          decimal: true,
          signed: false
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(r"[\d.]+")
        ),
        LengthLimitingTextInputFormatter(8),
      ],
      decoration: InputDecoration(
          hintText: "Budget",
          hintStyle: TextStyle(
              color : Colors.black,
              fontSize: MediaQuery.of(context).size.width * 0.06
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0)
      ),
      style: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.06,
          color: Colors.black
      ),
    );
  }


  Widget budget(BuildContext context, double width, double height) {
    return Container(
        padding: EdgeInsets.all(width / 35),
        decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: MyApp.theme[MyApp.selectedTheme]!["dialogShadow"],
                  offset: Offset(0,10),
                  blurRadius: 10
              )
            ]
        ),
        child : Column(
          children: [
            Text(
                "Enter budget for this month",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: width * 0.045
                )
            ),
            SizedBox(height : height / 29),
            inputBudget(context),
            SizedBox(height : height / 25),
            AnimatedButton(
                onPressed: () async {
                  if (budgetController.text != '') {
                    setState(() {
                      sliderValue = double.parse(budgetController.text);
                    });

                    pageController.animateToPage(1,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeInExpo
                    );

                  }

                  player.play(MyApp.theme[MyApp.selectedTheme]!["soundDef"]);
                },
                child: Text("NEXT",
                    style: TextStyle(
                        color: MyApp.theme[MyApp.selectedTheme]!["buttonText"]
                    )
                ),
                width: width / 4,
                height: height / 25
            )
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        )
    );
  }

  Widget savingTarget(BuildContext context, double width, double height) {
    if (sliderValue != null && budgetController.text != '') {
      return Container(
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: MyApp.theme[MyApp.selectedTheme]!["dialogShadow"],
                    offset: Offset(0, 10),
                    blurRadius: 10
                )
              ]
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(bottom : width / 35, top : width / 50),
                height: height / 30,
                child : Row(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: IconButton(
                        icon : Icon(Icons.arrow_back),
                        iconSize: width / 20,
                        onPressed: () {
                          pageController.animateToPage(0,
                              duration: Duration(milliseconds: 200),
                              curve: Curves.easeInExpo
                          );
                        },
                      ),
                    ),

                    Spacer(),
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
              ),
              Container(
                margin: EdgeInsets.only(left : 10, right : 10),
                child : Text(
                    "Savings target for this month",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: width * 0.042
                    ),
                ),
              ),
              SizedBox(height: height / 40),
              Container(
                  margin: EdgeInsets.only(left : 10, right : 10),
                  child : Text(
                      sliderValue!.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: width * 0.045
                      ),
                  ),
              ),
              Container (
                margin: EdgeInsets.only(left : 10, right : 10),
                child: Slider(
                  value: sliderValue!,
                  onChanged: (double value) {
                    setState(() {
                      sliderValue = value;
                    });
                  },
                  divisions: 5,
                  min: 0,
                  max: double.parse(budgetController.text),
                )
              ),
              SizedBox(height: height / 60),
              AnimatedButton(
                  onPressed: () async {
                    await SpentDatabase.instance.addBudgetAndTarget(
                        double.parse(
                            budgetController.text
                        ),
                        double.parse(sliderValue!.toStringAsFixed(1))
                    );
                    player.play(MyApp.theme[MyApp.selectedTheme]!["soundDef"]);
                    Navigator.pop(context);
                  },
                  child: Text("DONE",
                      style: TextStyle(
                          color: MyApp.theme[MyApp.selectedTheme]!["buttonText"]
                      )
                  ),
                  width: width / 4,
                  height: height / 28
              )
            ],
            mainAxisAlignment: MainAxisAlignment.start,
          )
      );
    } else {
      return Container();
    }
  }
}

