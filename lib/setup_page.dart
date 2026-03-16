import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final PageController controller = PageController();

  int currentPage = 0;
  bool canContinue = false;

  final TextEditingController nameController = TextEditingController();

  /// Save username
  Future<void> saveName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", nameController.text);
  }

  /// Save location
  Future<void> saveLocation() async {
    final prefs = await SharedPreferences.getInstance();

    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enable location services.")),
      );
      return;
    }

    // Check permission
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // If permanently denied
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Location permission permanently denied. Please enable it in settings.",
          ),
        ),
      );

      await Geolocator.openAppSettings();
      return;
    }

    // If still denied
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Location permission denied.")));
      return;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Save location
    await prefs.setDouble("home_lat", position.latitude);
    await prefs.setDouble("home_lng", position.longitude);

    Navigator.pushReplacementNamed(context, "/");
  }

  void nextPage() {
    controller.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// STEP INDICATOR
  Widget indicator(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6),
      width: currentPage == index ? 14 : 10,
      height: currentPage == index ? 14 : 10,
      decoration: BoxDecoration(
        color: currentPage == index ? Colors.blue : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  /// PAGE 1 — USERNAME
  Widget buildNamePage() {
    return Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Welcome to Walkd.",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Text(
            "Walking app for the introvert.",
            style: TextStyle(fontSize: 16),
          ),

          SizedBox(height: 30),

          TextField(
            controller: nameController,
            onChanged: (value) {
              setState(() {
                canContinue = value.trim().isNotEmpty;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter your name",
            ),
          ),

          SizedBox(height: 30),

          ElevatedButton(
            onPressed: nameController.text.isEmpty
                ? null
                : () async {
                    await saveName();
                    controller.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
            child: Text("Continue"),
          ),
        ],
      ),
    );
  }

  /// PAGE 2 — LOCATION
  Widget buildLocationPage() {
    return Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: 80, color: Colors.blue),

          SizedBox(height: 20),

          Text(
            "Save your running location",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 10),

          Text(
            "The app will only allow runs within this radius.",
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 30),

          ElevatedButton(
            onPressed: saveLocation,
            child: Text("Save My Location"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Setup")),

      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: controller,
              physics: NeverScrollableScrollPhysics(), // disables swipe
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              children: [buildNamePage(), buildLocationPage()],
            ),
          ),

          /// STEP INDICATORS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [indicator(0), indicator(1)],
          ),

          SizedBox(height: 30),
        ],
      ),
    );
  }
}
