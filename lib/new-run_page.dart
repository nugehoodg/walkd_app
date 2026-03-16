import 'package:flutter/material.dart';
import 'dart:ui'; // for lerpDouble
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'main.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class _NewRunPageState extends State<NewRunPage>
    with SingleTickerProviderStateMixin {
  // Gyro offsets
  double offsetX = 0;
  double offsetY = 0;

  // Target offsets from gyroscope
  double targetOffsetX = 0;
  double targetOffsetY = 0;

  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Pulse animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 1.0,
      upperBound: 1.3,
    );
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _pulseController.reverse();
    });

    // Smooth update ticker
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  void _tick() async {
    while (mounted) {
      // Interpolate offset toward target
      offsetX = lerpDouble(offsetX, targetOffsetX, 0.1)!;
      offsetY = lerpDouble(offsetY, targetOffsetY, 0.1)!;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 16)); // ~60fps
    }
  }

  @override
  void didUpdateWidget(covariant NewRunPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Pulse on step update
    if (widget.runSteps != oldWidget.runSteps) {
      _pulseController.forward(from: 0);
    }

    // Start or stop gyro
    if (widget.isRunning && _gyroSubscription == null) {
      _startGyro();
    } else if (!widget.isRunning && _gyroSubscription != null) {
      _stopGyro();
    }
  }

  void _startGyro() {
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      // Update target offsets instead of direct offsets
      targetOffsetX = event.y * 10;
      targetOffsetY = event.x * 10;
    });
  }

  void _stopGyro() {
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
    targetOffsetX = 0;
    targetOffsetY = 0;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stopGyro();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Steps",
              style: GoogleFonts.splineSansMono(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // AnimatedBuilder for pulse + gyro
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(offsetX, offsetY),
                  child: Transform.scale(
                    scale: _pulseController.value,
                    child: Text(
                      "${widget.runSteps}",
                      style: GoogleFonts.splineSansMono(
                        fontSize: 140,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: widget.isRunning ? null : widget.startRun,
                  child: const Text("Start Run"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: widget.isRunning ? widget.stopRun : null,
                  child: const Text("Stop Run"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NewRunPage extends StatefulWidget {
  final int runSteps;
  final bool isRunning;
  final VoidCallback startRun;
  final VoidCallback stopRun;
  final VoidCallback resetRun;
  final Function(bool) onRunStateChanged;

  const NewRunPage({
    super.key,
    required this.runSteps,
    required this.isRunning,
    required this.startRun,
    required this.stopRun,
    required this.resetRun,
    required this.onRunStateChanged,
  });

  @override
  State<NewRunPage> createState() => _NewRunPageState();
}

class AccountSummaries extends StatelessWidget {
  final List<Map<String, dynamic>> runs;

  const AccountSummaries({super.key, required this.runs});

  double getAverageSteps() {
    if (runs.isEmpty) return 0;

    int totalSteps = runs.fold(0, (sum, run) => sum + (run["steps"] as int));

    return totalSteps / runs.length;
  }

  double calculateDistance(int steps) {
    double stepLength = 0.75; // meters per step
    return (steps * stepLength) / 1000; // km
  }

  String formatDistance(double km) {
    if (km < 1) {
      double meters = km * 1000;
      return "${meters.toStringAsFixed(0)} m";
    } else {
      return "${km.toStringAsFixed(2)} km";
    }
  }

  double getAverageDistance() {
    if (runs.isEmpty) return 0;

    double totalDistance = runs.fold(
      0.0,
      (sum, run) => sum + double.tryParse(run["distance"].toString())! ?? 0,
    );

    return totalDistance / runs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Summaries',
          style: GoogleFonts.splineSansMono(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 0,
            margin: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Average Steps',
                  style: GoogleFonts.splineSansMono(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  getAverageSteps().toStringAsFixed(0),
                  style: GoogleFonts.splineSansMono(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 0,
            margin: EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Average Distance',
                  style: GoogleFonts.splineSansMono(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatDistance(getAverageDistance()),
                  style: GoogleFonts.splineSansMono(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
