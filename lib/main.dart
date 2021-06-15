import 'package:broked/Database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import "Database.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Broked',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(title: 'Broked'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
/*
  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _firstTime = (prefs.getBool('firstTime') ?? false);

    if (_firstTime) {
      //create db
    } else {
      await prefs.setBool('firstTime', true);
      //get db and get pointer
    }
  }

 */


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return DefaultTabController(
        length : 2,
        child : Scaffold(
          bottomNavigationBar: Material(
            color: Colors.greenAccent,
            child: TabBar(
              tabs: [
                Tab(text: "Input"),
                Tab(text: "Analytics")
              ]
            )
          ),
          body: TabBarView(
            children : [
              BrokeMain(),
              Analytics()
            ] 
          )
        )
    );
  }
}

class BrokeMain extends StatefulWidget {
  const BrokeMain({ Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BrokeMain();

}

class _BrokeMain extends State<BrokeMain> {

  DateTime _date = DateTime.now();
  final amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child : Column(
          children: <Widget> [
            Text("${DateFormat('dd-MM-yyyy').format(_date)}"),
            ElevatedButton(
              onPressed: () {
                showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now()
                ).then((date) => {
                  setState(() {
                    if (date != null) {
                      _date = date;
                    }
                  })
                });
              }, child: Text("Pick a date"),
            ),

            //add space between widget
            SizedBox(height: 20),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))],
            ),
            //add space between widget
            SizedBox(height : 20),
            ElevatedButton(
                onPressed: () async {
                  spentDatabase.instance.insertAmount(
                    Spent(date : _date, amount : double.parse(amountController.text))
                  );
                  amountController.clear();
                },
                child: Text("BROKE!"),
                style : ElevatedButton.styleFrom(
                    primary: Colors.brown
                )
            )
          ],
          mainAxisAlignment: MainAxisAlignment.center
        ),
      )
    );
  }

}



class Analytics extends StatefulWidget {
  const Analytics({ Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Analytics();

}

class _Analytics extends State<Analytics> {

  late double totalSpent;

  @override
  void initState() {
    super.initState();
    recalculate();
  }


  Future recalculate() async {
    totalSpent = await spentDatabase.instance.getTotalSpending();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child : Column(
            children: [
              Text("Analytics"),
              Text("Total spent : $totalSpent")
            ],
            mainAxisAlignment: MainAxisAlignment.center
          )
        ),
    );
  }

}

