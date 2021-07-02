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
            fontSize: 30,
            color: MyApp.theme[MyApp.selectedTheme]!["buttonText"]
        ),
      ),
      color: MyApp.theme[MyApp.selectedTheme]!["brokeButton"],
      width: 350,
      height: 100,
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
      child : Text("${DateFormat('dd MMM yyyy').format(_date)}")
    );
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child : Scaffold(
        body: Center(
          child : Column(
            children: <Widget> [
              Container(
                margin: EdgeInsets.fromLTRB(20, 20, 20, 140),
                child : Row(
                  children: [
                    Spacer(),
                    budgetButton(context)
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                )
              ),
              Container(
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

  @override
  Widget build(BuildContext context) {
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
                            child: resetDialog(context),
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
                                  fontSize: 16
                              )
                          ),
                          margin: EdgeInsets.only(bottom : 40)
                      ),
                      FutureBuilder(
                          future: SpentDatabase.instance.getBudgetThisMonth(),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("budget: ",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)}",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("budget: ",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color : MyApp.theme[MyApp.selectedTheme]!["text"]
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: 20),
                      FutureBuilder(
                          future: SpentDatabase.instance.getSpendingToday(),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("spent today: ",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)}",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("spent today: ",
                                  style: TextStyle(
                                      fontSize: 14
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: 20),
                      FutureBuilder(
                          future: SpentDatabase.instance.getSpendingThisMonth(),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("spent this month: ",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)}",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("spent this month: ",
                                  style: TextStyle(
                                      fontSize: 14
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: 20),
                      FutureBuilder(
                          future: SpentDatabase.instance.getAvgSpending(),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("avg spending this month: ",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)}",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("avg spending this month: ",
                                  style: TextStyle(
                                      fontSize: 14
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: 20),
                      FutureBuilder(
                          future: SpentDatabase.instance.getTargetThisMonth(),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("saving target this month: ",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)}",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("saving target this month: ",
                                  style: TextStyle(
                                      fontSize: 14
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: 20),
                      FutureBuilder(
                          future: SpentDatabase.instance.getSpendingPerDayToHitTarget(),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                  children : [
                                    Text("to hit saving target: ",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    ),
                                    Spacer(),
                                    Text("${snapshot.data!.toStringAsFixed(1)} / day",
                                        style: TextStyle(
                                            fontSize: 14
                                        )
                                    )
                                  ]
                              );
                            } else {
                              return Text("to hit saving target: ",
                                  style: TextStyle(
                                      fontSize: 14
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height: 20),
                      FutureBuilder(
                          future: SpentDatabase.instance.getOverUnderSpent(),
                          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                children: [
                                  Text("leftover: ",
                                      style: TextStyle(
                                          fontSize: 14
                                      )
                                  ),
                                  Spacer(),
                                  Text("${snapshot.data!.toStringAsFixed(1)}",
                                    style: TextStyle(
                                      color: (snapshot.data! > 0) ?
                                        Color.fromRGBO(50, 205, 50, 1)
                                          : (snapshot.data! < 0) ?
                                        Color.fromRGBO(221, 0, 4, 1)
                                          : MyApp.theme[MyApp.selectedTheme]!["text"]
                                    )
                                  )
                                ],
                              );
                            } else {
                              return Text(
                                  "leftover: ",
                                  style: TextStyle(
                                      color: MyApp.theme[MyApp.selectedTheme]!["text"],
                                      fontSize: 14
                                  )
                              );
                            }
                          }
                      ),
                      SizedBox(height : 40),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                  margin: EdgeInsets.only(left : 90, right : 90)
                ),
                FutureBuilder(
                    future : Future.wait([
                      SpentDatabase.instance.getAllSpentThisMonth(),
                      SpentDatabase.instance.getSpendingPerDayToHitTarget()
                    ]),
                    builder : (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                      if (snapshot.hasData) {
                        List<Spent> spents = snapshot.data![0];
                        double spendPerDay = double.parse(snapshot.data![1].toStringAsFixed(1));
                        if (spents.isEmpty || spendPerDay.toInt() == 0) {
                          return Container(
                              margin: EdgeInsets.only(left: 30, right: 30),
                              decoration: BoxDecoration(
                                color: MyApp.theme[MyApp.selectedTheme]!["text"],
                                borderRadius: BorderRadius.circular(10)
                              ),
                              width: MediaQuery.of(context).size.width,
                              height: 300,
                              child: Align(
                                alignment: Alignment.center,
                                child : Text("Add in budget and a saving target first to see this graph",
                                  style: TextStyle(
                                      color: Colors.white
                                  ),
                                ),
                              )
                          );
                        } else {
                          return Container(
                              margin: EdgeInsets.only(left: 30, right: 30),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.blueAccent
                                  )
                              ),

                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width,
                              height: 300,
                              child: lineChart(spents, spendPerDay)
                          );
                        }
                      } else {
                        return Text("Error");
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
    double maxSpent = spents.map((spent) => spent.amount).reduce(max);
    double minSpent = spents.map((spent) => spent.amount).reduce(min);
    int numDaysInMonth = SpentDatabase.instance
        .numOfDaysInMonth(DateTime.now());

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
            minY: (minSpent.floorToDouble() > spendPerDay)
                ? 0
                : minSpent.floorToDouble(),
            maxY: (maxSpent.ceilToDouble() > spendPerDay)
                ? maxSpent.ceilToDouble() + 1
                : spendPerDay.ceilToDouble() * 10,
            minX: 1,
            maxX: numDaysInMonth.toDouble(),
            lineBarsData: [
              LineChartBarData(
                  spots: coordinates
              )
            ],
            extraLinesData: ExtraLinesData(
                horizontalLines: spendingPerDay
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTextStyles: (value) =>
                const TextStyle(color: Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 16),
                getTitles: (value) {
                  if (value == numDaysInMonth) {
                    return '$numDaysInMonth';
                  } else if (value == 1) {
                    return '1';
                  } else if (value == 5) {
                    return '5';
                  } else if (value == 10) {
                    return '10';
                  } else if (value == 15) {
                    return '15';
                  } else if (value == 20) {
                    return '20';
                  } else if (value == 25) {
                    return '25';
                  }
                  return '';
                },
                margin: 8,
              ),
              leftTitles: SideTitles(
                showTitles: true,
                getTextStyles: (value) => const TextStyle(
                  color: Color(0xff67727d),
                  fontWeight: FontWeight.bold,
                ),
                reservedSize: 28,
                margin: 12,
              ),
            ),
            borderData: FlBorderData(
              border : const Border(
                bottom: BorderSide(
                  color: Color(0xff4e4965),
                  width: 4,
                ),
                left: BorderSide(
                  color: Colors.transparent,
                ),
                right: BorderSide(
                  color: Colors.transparent,
                ),
                top: BorderSide(
                  color: Colors.transparent,
                ),
              ),
            )
        )
    );
  }

  Widget resetDialog(context) {
    return Stack(
      children: <Widget>[
        Container (
          padding: EdgeInsets.all(20),
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
          width: MediaQuery.of(context).size.height / 1.5,
          height : MediaQuery.of(context).size.width / 2,
          child : Column(
            children: [
              Text("Reset Database",
                style: TextStyle(
                  color: Colors.black
                )
              ),
              SizedBox(height : 25),
              Text("All input data you've previously entered will be erased. Are you sure?",
                style: TextStyle(
                  color: Colors.black
                )
              ),
              SizedBox(height : 40),
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
                      width: 100,
                      height: 32
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
                      width: 100,
                      height: 32
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              )
            ],
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


  Widget inputAmount() {
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
                color: MyApp.theme[MyApp.selectedTheme]!["hintText"]
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
                vertical: 20.0, horizontal: 10.0)
        ),
        style: TextStyle(
            fontSize: 30,
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
            width: 300,
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
        child: inputAmount(),
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
    return Container(
        width: MediaQuery.of(context).size.height / 1.5,
        height : MediaQuery.of(context).size.width / 1.5,
        child : Stack(
            children : [
              PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: pageController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    budget(context),
                    savingTarget(context)
                  ]
              )
            ]
        )
    );
  }

  Widget inputBudget() {
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
              fontSize: 25
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0)
      ),
      style: TextStyle(
          fontSize: 30,
          color: Colors.black
      ),
    );
  }


  Widget budget(context) {
    return Container(
        padding: EdgeInsets.all(20),
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
                    fontSize: 20
                )
            ),
            SizedBox(height : 40),
            inputBudget(),
            SizedBox(height : 50),
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
                width: 100,
                height: 32
            )
          ],
        )
    );
  }

  Widget savingTarget(context) {
    if (sliderValue != null && budgetController.text != '') {
      return Container(
          padding: EdgeInsets.zero,
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
                margin: EdgeInsets.only(bottom : 10),
                child : Row(
                  children: [
                    IconButton(
                      icon : Icon(Icons.arrow_back),
                      onPressed: () {
                        pageController.animateToPage(0,
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeInExpo
                        );
                      },
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
                        fontSize: 20
                    ),
                )
              ),
              SizedBox(height: 20),
              Container(
                  margin: EdgeInsets.only(left : 10, right : 10),
                  child : Text(
                      sliderValue!.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 23
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
                  min: 0,
                  max: double.parse(budgetController.text),
                )
              ),
              SizedBox(height: 15),
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
                  width: 100,
                  height: 32
              )
            ],
          )
      );
    } else {
      return Container();
    }
  }
}

