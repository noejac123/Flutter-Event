import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_reader/qr_reader.dart';
import 'dart:convert' as convert;
import 'package:shared_preferences/shared_preferences.dart';

class Model {
  static List<int> favs;
  static Events events;
  static SharedPreferences prefs;
  static getModel() async {
    prefs = await SharedPreferences.getInstance();
    try {
      var bod = prefs.getString("body");
      if (bod != null) {
        events = Events.fromJson(convert.jsonDecode(bod));
        await loadFont(events.font);
      }
    } catch (e) {
      events = null;
      await prefs.clear();
    }
    favs =
        prefs.getStringList("favs")?.map((s) => int.parse(s))?.toList() ?? [];
  }

  static setModel(bod) async {
    events = Events.fromJson(convert.jsonDecode(bod));
    await prefs.setString("body", bod);
  }

  static chngFav(id) {
    favs.contains(id) ? favs.remove(id) : favs.add(id);
    prefs.setStringList("favs", favs.map((i) => i.toString()).toList());
  }

  static Future<void> loadFont(url) async {
    var resp = await http.get(url);
    var data = Future.value(ByteData.view(resp.bodyBytes.buffer));
    await (FontLoader(events.title)..addFont(data)).load();
  }
}

void main() {
  Model.getModel().then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(_) {
    return MaterialApp(
      title: 'Flutter Events',
      theme: ThemeData(primaryColor: Colors.green, accentColor: Colors.green),
      home: Model.events != null ? EventPage() : QrPage(),
    );
  }
}

class QrPage extends StatefulWidget {
  @override
  createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  bool loader = false;
  @override
  build(_) => Scaffold(
      appBar: AppBar(title: Text("Flutter Events"), centerTitle: true),
      body: Center(
        child: loader
            ? CircularProgressIndicator()
            : RaisedButton(
                onPressed: () async {
                  String s = await QRCodeReader().scan();
                  setState(() => loader = true);
                  var response = await http.get(s);
                  await Model.setModel(response.body);
                  await Model.loadFont(Model.events.font);
                  Navigator.of(context)
                    ..popUntil((route) => route.isFirst)
                    ..pushReplacement(
                        MaterialPageRoute(builder: (_) => EventPage()));
                },
                child: Text("Scan QR Code")),
      ));
}

class EventPage extends StatefulWidget {
  @override
  createState() => _MyEventPageState();
}

class _MyEventPageState extends State<EventPage> {
  Widget build(BuildContext context) {
    var ets = Model.events;
    return Theme(
      child: DefaultTabController(
        length: ets.tabs.length,
        child: Scaffold(
          appBar: AppBar(
              elevation: 0.0,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => QrPage())),
                )
              ],
              bottom: TabBar(
                tabs: ets.tabs
                    .map((e) => Padding(
                          child: Text(
                            e.title,
                            textAlign: TextAlign.center,
                          ),
                          padding: EdgeInsets.fromLTRB(5.0, 10.0, 10.0, 5.0),
                        ))
                    .toList(),
              ),
              title: Text(ets.title)),
          body: TabBarView(
            physics: BouncingScrollPhysics(),
            children: ets.tabs
                .map((e) => Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0)),
                      child: ListView.separated(
                          itemCount: e.items.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: ets.accent),
                          itemBuilder: (context, int index) {
                            var i = e.items[index];
                            return ListTile(
                              title: Text(i.title),
                              subtitle: Text(i.desc),
                              leading: Text(
                                i.time,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ets.accent,
                                  textBaseline: TextBaseline.ideographic,
                                ),
                              ),
                              trailing: IconButton(
                                  icon: Icon(
                                    Model.favs.contains(i.id)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: ets.iconColor,
                                  ),
                                  onPressed: () {
                                    Model.chngFav(i.id);
                                    setState(() {});
                                  }),
                            );
                          }),
                    ))
                .toList(),
          ),
        ),
      ),
      data: ThemeData(
          primaryColor: ets.primary,
          accentColor: ets.accent,
          canvasColor: ets.background,
          brightness: ets.brightness,
          fontFamily: ets.title),
    );
  }
}

class Events {
  Color primary, accent, background, iconColor;
  Brightness brightness;
  String title, font;
  List<Tabs> tabs;
  Events(
      {this.title,
      this.brightness,
      this.primary,
      this.accent,
      this.background,
      this.iconColor,
      this.font,
      this.tabs});

  static Color srtToCol(String s) {
    return Color(
        int.parse('0xFF' + s?.substring(1)?.toUpperCase() ?? "FFFFFF"));
  }

  factory Events.fromJson(Map<String, dynamic> parsedJson) {
    return Events(
        primary: srtToCol(parsedJson["primary color"]),
        accent: srtToCol(parsedJson["accent color"]),
        background: srtToCol(parsedJson["background color"]),
        iconColor: srtToCol(parsedJson["icon color"]),
        brightness: (parsedJson["brightness"] as String).toLowerCase() == "dark"
            ? Brightness.dark
            : Brightness.light,
        font: parsedJson["font"],
        title: parsedJson["app title"],
        tabs:
            (parsedJson["tabs"] as List).map((e) => Tabs.fromJson(e)).toList());
  }
}

class Tabs {
  String title;
  List<Item> items;
  Tabs({this.title, this.items});

  factory Tabs.fromJson(Map<String, dynamic> parsedJson) {
    return Tabs(
        title: parsedJson["tab title"],
        items: (parsedJson["items"] as List)
            .map((e) => Item.fromJson(e))
            .toList());
  }
}

class Item {
  String time;
  String title;
  String desc;
  int id;
  Item({
    this.time,
    this.title,
    this.desc,
    this.id,
  });

  factory Item.fromJson(Map<String, dynamic> parsedJson) {
    return Item(
        time: parsedJson["time"],
        title: parsedJson["event title"],
        desc: parsedJson["description"],
        id: ((parsedJson["time"]) + (parsedJson["event title"])).hashCode);
  }
}
