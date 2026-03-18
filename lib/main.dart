import 'package:flutter/material.dart';
import 'dart:ui'; // for lerpDouble
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'setup_page.dart';
import 'new-run_page.dart';
import 'previous-run_page.dart';
import 'settings_page.dart';
import 'account_page.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'user_progress.dart';
import 'package:http/http.dart' as http;

Future<void> requestPermission() async {
  await Permission.activityRecognition.request();
}

Future<bool> isInsideRadius(double radiusMeters) async {
  final prefs = await SharedPreferences.getInstance();

  double? homeLat = prefs.getDouble("home_lat");
  double? homeLng = prefs.getDouble("home_lng");

  if (homeLat == null || homeLng == null) {
    return false;
  }

  Position current = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  double distance = Geolocator.distanceBetween(
    homeLat,
    homeLng,
    current.latitude,
    current.longitude,
  );

  return distance <= radiusMeters;
}

Future<void> launchURL(String urlString) async {
  // Convert string to Uri
  final Uri url = Uri.parse(urlString);

  if (await canLaunchUrl(url)) {
    await launchUrl(
      url,
      mode:
          LaunchMode.externalApplication, // optional: opens in external browser
    );
  } else {
    debugPrint('Could not launch $urlString');
  }
}

/// Flutter code sample for [NavigationBar].

void main() => runApp(const NavigationBarApp());

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: const ColorScheme(
          brightness: Brightness.light,

          primary: Colors.black,
          onPrimary: Colors.white,

          secondary: Colors.black,
          onSecondary: Colors.white,

          error: Colors.black,
          onError: Colors.white,

          surface: Colors.white,
          onSurface: Colors.black,
        ),
      ),
      home: NavigationExample(),
    );
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class AccountLevel extends StatelessWidget {
  final int level;
  final int exp;
  final int expNeeded;

  const AccountLevel({
    super.key,
    required this.level,
    required this.exp,
    required this.expNeeded,
  });

  @override
  Widget build(BuildContext context) {
    double progress = 0;

    if (expNeeded > 0) {
      progress = exp / expNeeded;
    }

    progress = progress.clamp(0.0, 1.0);

    int filledBars = (progress * 8).floor();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Text("Level", style: TextStyle(color: Colors.white)),

          SizedBox(width: 6),

          Text(
            "$level",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(width: 16),

          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(8, (index) {
                return Container(
                  width: 18,
                  height: 40,
                  decoration: BoxDecoration(
                    color: index < filledBars
                        ? Colors.green
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountCard extends StatelessWidget {
  final int totalRuns;
  final String username;

  const AccountCard({
    super.key,
    required this.totalRuns,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 30),
        color: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hi, $username",
                    style: GoogleFonts.splineSansMono(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Lottie.asset(
                    'assets/run_01.json',
                    width: 90,
                    height: 10,
                    fit: BoxFit.fitWidth,
                  ),
                ],
              ),

              SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    "$totalRuns",
                    style: GoogleFonts.splineSansMono(
                      color: Colors.white,
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    "  TOTAL RUN",
                    style: GoogleFonts.splineSansMono(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationExampleState extends State<NavigationExample> {
  int level = 1;
  int exp = 0;
  int expNeeded = 0;
  String username = "";
  bool loaded = false;
  int steps = 0;
  int runSteps = 0;
  bool isRunning = false;
  int startSteps = 0;
  int currentIndex = 2; // <-- ADD IT HERE
  int totalRuns = 0; // <-- add this
  int listLength = 0;
  List<Map<String, dynamic>> items = [];
  Timer? radiusTimer;
  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    loadUsername();
    loadRuns();
    loadLevel();

    if (!kIsWeb) {
      requestPermission();

      Pedometer.stepCountStream.listen((StepCount event) {
        setState(() {
          steps = event.steps;

          if (isRunning) {
            runSteps = steps - startSteps;
          }
        });
      });
    }
  }

  int expToNextLevel(int level) {
    return 1000 + (level * 500);
  }

  Future<void> addExp(int steps, double distanceKm) async {
    final prefs = await SharedPreferences.getInstance();

    int level = prefs.getInt("level") ?? 1;
    int exp = prefs.getInt("exp") ?? 0;

    int gainedExp = steps + (distanceKm * 1000).toInt();

    exp += gainedExp;

    while (exp >= expToNextLevel(level)) {
      exp -= expToNextLevel(level);
      level++;
    }

    await prefs.setInt("level", level);
    await prefs.setInt("exp", exp);
  }

  double calculateDistance(int steps) {
    double stepLength = 0.78; // meters per step
    return (steps * stepLength) / 1000; // km
  }

  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      username = prefs.getString('username') ?? "";
      loaded = true;
    });
  }

  Future<void> loadRuns() async {
    final prefs = await SharedPreferences.getInstance();

    List<String>? runList = prefs.getStringList('runs');

    if (runList != null) {
      items = runList
          .map((run) => jsonDecode(run))
          .toList()
          .cast<Map<String, dynamic>>();
    }
  }

  void startRun() async {
    bool allowed = await isInsideRadius(100);

    if (!allowed) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("You're introverted!"),
          content: Text("You must be within the comfort of your house!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      isRunning = true;
      startSteps = steps;
      runSteps = 0;
    });

    positionStream =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // update every 5 meters
          ),
        ).listen((Position position) async {
          final prefs = await SharedPreferences.getInstance();

          double homeLat = prefs.getDouble("home_lat")!;
          double homeLng = prefs.getDouble("home_lng")!;

          double distance = Geolocator.distanceBetween(
            homeLat,
            homeLng,
            position.latitude,
            position.longitude,
          );

          print("Distance from home: $distance");

          if (distance > 100 && isRunning) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Leaving Running Area"),
                content: Text(
                  "You left the allowed running radius.\nThe run will now stop.",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      stopRun();
                    },
                    child: Text("OK"),
                  ),
                ],
              ),
            );
          }
        });
  }

  String getStepFunFact(int steps, double distanceKm) {
    if (distanceKm < 0.2) {
      return "That's about walking across a large building 🏢";
    } else if (distanceKm < 0.5) {
      return "That's like walking around a park 🌳";
    } else if (distanceKm < 1) {
      return "That's roughly 12 football fields ⚽";
    } else if (distanceKm < 2) {
      return "That's like walking around Hogwarts castle 🏰";
    } else if (distanceKm < 5) {
      return "That's like exploring a theme park 🎢";
    } else if (distanceKm < 10) {
      return "That's like crossing a small city 🏙️";
    } else if (distanceKm < 20) {
      return "That's half a marathon! 🏃‍♂️🔥";
    } else {
      return "That's basically a marathon level run! 🏅";
    }
  }

  Future<void> stopRun() async {
    positionStream?.cancel();
    double distance = calculateDistance(runSteps);
    String funFact = getStepFunFact(runSteps, distance);

    setState(() {
      isRunning = false;
    });

    if (runSteps > 0) {
      double distance = calculateDistance(runSteps);

      items.add({
        "title": "Run ${items.length + 1}",
        "steps": runSteps,
        "distance": distance,
        "date": DateTime.now().toString(),
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Good job! 🎉"),
          content: Text(
            "You ran $runSteps steps!\n"
            "≈ ${distance.toStringAsFixed(2)} km\n\n"
            "🏃 $funFact",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Nice!"),
            ),
          ],
        ),
      );

      await saveRuns();
      await addExp(runSteps, distance);
      await loadLevel();
      setState(() {});
    }
  }

  Future<void> loadLevel() async {
    final prefs = await SharedPreferences.getInstance();

    int savedLevel = prefs.getInt("level") ?? 1;
    int savedExp = prefs.getInt("exp") ?? 0;

    setState(() {
      level = savedLevel;
      exp = savedExp;
      expNeeded = expToNextLevel(savedLevel);
    });
  }

  Future<void> saveRuns() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> runList = items.map((run) => jsonEncode(run)).toList();

    await prefs.setStringList('runs', runList);
  }

  void setRunning(bool value) {
    setState(() {
      isRunning = value;
    });
  }

  void resetRun() {
    setState(() {
      runSteps = 0;
      startSteps = steps;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if ((username ?? "").isEmpty) {
      return const SetupPage();
    }
    final List<Widget> pages = [
      PreviousRunPage(items: items),
      NewRunPage(
        runSteps: runSteps,
        isRunning: isRunning,
        startRun: startRun,
        stopRun: stopRun,
        resetRun: resetRun,
        onRunStateChanged: setRunning,
      ),
      AccountPage(
        progress: UserProgress(
          steps: steps,
          totalRuns: items.length,
          username: username,
          level: level,
          exp: exp,
          runs: items,
        ),
      ),
      SettingsPage(),
    ];
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: pages[currentIndex],

      appBar: AppBar(
        actionsPadding: EdgeInsets.all(15),
        actions: [
          Row(
            children: [
              OutlinedButton(
                onPressed: () => showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: RichText(
                      text: TextSpan(
                        text: 'Made by ',
                        style: GoogleFonts.splineSansMono(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Anugerah',
                            style: GoogleFonts.splineSansMono(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: 'Running Animation by',
                            style: GoogleFonts.splineSansMono(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            launchURL(
                              'https://lottiefiles.com/musaadanur',
                            ); // just pass a string
                          },
                          child: Text(
                            'Musa Adanur',
                            style: GoogleFonts.splineSansMono(
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      OutlinedButton(
                        onPressed: () {
                          launchURL(
                            'https://ko-fi.com/J3J61JMZL2',
                          ); // just pass a string
                        },
                        child: Text("Buy me a Coffee"),
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll<Color>(
                            Colors.yellow,
                          ),
                          foregroundColor: WidgetStatePropertyAll<Color>(
                            Colors.black,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'OK'),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.yellow),
                  foregroundColor: WidgetStatePropertyAll<Color>(Colors.black),
                ),
                child: Icon(Icons.coffee),
              ),
            ],
          ),
        ],
        toolbarHeight: 80,
        title: Text(
          "⚹ walkd.",
          style: GoogleFonts.archivoBlack(
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
        indicatorColor: Colors.black,
        selectedIndex: currentIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.arrow_back),
            icon: Icon(Icons.arrow_back_rounded),
            label: 'Previous Runs',
          ),
          NavigationDestination(icon: Icon(Icons.run_circle), label: 'New Run'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
