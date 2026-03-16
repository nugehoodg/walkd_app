import 'package:flutter/material.dart';
import 'new-run_page.dart';
import 'main.dart';
import 'previous-run_page.dart';
import 'new-run_page.dart';
import 'setup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("Reset Data"),
                  content: Text(
                    "This will delete your username, runs, and saved location.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();

                        /// Remove stored data
                        await prefs.remove("username");
                        await prefs.remove("runs");
                        await prefs.remove("home_lat");
                        await prefs.remove("home_lng");
                        await prefs.remove("level");
                        await prefs.remove("exp");

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const SetupPage()),
                          (route) => false,
                        );
                      },
                      child: Text("Reset", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            child: Text("Reset User Data"),
          ),
        ],
      ),
    );
  }
}
