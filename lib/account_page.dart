import 'package:flutter/material.dart';
import 'new-run_page.dart';
import 'main.dart';
import 'previous-run_page.dart';
import 'new-run_page.dart';
import 'user_progress.dart';

class AccountPage extends StatelessWidget {
  final UserProgress progress;

  const AccountPage({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(padding: EdgeInsetsGeometry.all(30)),
        AccountCard(totalRuns: progress.totalRuns, username: progress.username),
        Padding(padding: EdgeInsetsGeometry.all(20)),
        AccountSummaries(runs: progress.runs),
        Padding(padding: EdgeInsetsGeometry.all(0)),
        AccountLevel(
          level: progress.level,
          exp: progress.exp,
          expNeeded: progress.expToNextLevel(),
        ),
      ],
    );
  }
}
