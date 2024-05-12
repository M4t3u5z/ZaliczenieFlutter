import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather/weather.dart';
import 'package:weather_app/AirScreen.dart';
import 'package:weather_app/MyHomePage.dart';
import 'package:weather_app/PermissionScreen.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

class SplashScreen extends StatefulWidget {

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: <Widget>[
        Container(
          decoration: BoxDecoration(
              color: new Color(0xffffffff),
              gradient: LinearGradient(
                  //liniowy gradient
                  begin: Alignment.centerRight,
                  //przejście gradientu od prawej do lewej
                  end: Alignment.centerLeft,
                  //przejście gradientu od lewej do prawej
                  colors: [
                    new Color(0xff6671e5),
                    new Color(0xff4852d9)
                  ] //dwa kolory które się mieszają w gradiencie
                  )),
        ),
        Align(
          alignment: FractionalOffset.center,
          //Aligment musi być zrobiony na kontenerze jak i na elemencie
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, //element kontenera
            children: <Widget>[
              Image(
                image: AssetImage('icons/cloud-sun.png'),
              ),
              Padding(padding: EdgeInsets.only(top: 15.0)),
              Text(Strings.appTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                      textStyle:
                          TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 42.0,
                              color: Colors.white))),
              Padding(padding: EdgeInsets.only(top: 5.0)),
              Text('Aplikacja do monitorowania \n czystości powietrza',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                      textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Colors.white))),
            ],
          ),
        ),
        Positioned(
            left: 0, //pozycja tekstu przywiewam dane
            bottom: 35, //pozycja tekstu przywiewam dane
            right: 0, //pozycja tekstu przywiewam dane
            child: Container(
              alignment: Alignment.center,
              //tekst musi być wyśrodkowany bo nie jest zbyt długi by być na środku
              child: Text("Przywiewam dane...",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                      textStyle:
                          TextStyle(
                            fontWeight: FontWeight.w300,
                              fontSize: 18.0,
                              color: Colors.white))),
            ))
      ]),
    );
  }

  @override
  void initState() {
    super.initState();
    checkPermission();
  }

  checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => PermissionScreen()));
    } else {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        executeOnceAfterBuild();
      });
    }
  }


  void executeOnceAfterBuild() async {
    Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.lowest,
        forceAndroidLocationManager: true,
        timeLimit: Duration(seconds: 5))
        .then((value) => {loadLocationData(value)})
        .onError((error, stackTrace) =>
    {
      Geolocator.getLastKnownPosition(forceAndroidLocationManager: true)
          .then((value) => {loadLocationData(value!)})
    });
  }

  loadLocationData(Position value) async {

    var lat = value.latitude;
    var lon = value.longitude;
    log(lat.toString() + " x " + lon.toString());

    WeatherFactory wf = new WeatherFactory("fe70cf7066ce04948960ba9d0e88f9d6", language: Language.POLISH);
    Weather w = await wf.currentWeatherByLocation(lat, lon);
    log(w.toJson().toString());

    var keyword = 'geo:$lat;$lon';
    String _endpoint = 'https://api.waqi.info/feed/';
    var key = '9cd1f46d46c90e648f87f67780d84cc1d12fe086';
    String url = '$_endpoint$keyword/?token=$key';

    http.Response response = await http.get(Uri.parse(url));
    log(response.body.toString());

    Map<String, dynamic> jsonBody = json.decode(response.body);
    AirQuality aq = new AirQuality(jsonBody);

    Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage(weather: w, air: aq)));
  }
  }


class AirQuality {
  bool isGood = false;
  bool isBad = false;
  String quality = "";
  String advice = "";
  int aqi = 0;
  int pm25 = 0;
  int pm10 = 0;
  String station = "";

  AirQuality(Map<String, dynamic> jsonBody) {
    aqi = int.tryParse(jsonBody['data']['aqi'].toString()) ?? -1;
    pm25 = int.tryParse(jsonBody['data']['iaqi']['pm25']['v'].toString()) ?? -1;
    //pm10 = int.tryParse(jsonBody['data']['iaqi']['pm10']['v'].toString()) ?? -1;//podczas emulacji na telefonie endpoint nie udostępnia parametrów dla pm10 wyłącznie dla pm25
    station = jsonBody['data']['city']['name'].toString();
    setupLevel(aqi);
  }

  void setupLevel(int aqi) {
    if (aqi <= 100) {
      quality = "Bardzo dobra";
      advice = "Skorzystaj z dobrego powietrzaa i wyjdź na spacer";
      isGood = true;
    } else if (aqi <= 150) {
      quality = "Nie za dobra";
      advice = "Jeśli tylko możesz zostań w domu, załatwiaj sprawy online";
      isBad = true;
    } else {
      quality = "Bardzo zła!";
      advice = "Zdecydowanie zostań w domu i załatwiaj sprawy online!";
    }
  }
}
