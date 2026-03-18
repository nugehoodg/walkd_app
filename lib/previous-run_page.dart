import 'package:flutter/material.dart';

class PreviousRunPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const PreviousRunPage({super.key, required this.items});

  @override
  State<PreviousRunPage> createState() => _PreviousRunPageState();
}

class _PreviousRunPageState extends State<PreviousRunPage> {
  final List<String> runEmojis = ["🏃", "🔥", "💨", "⚡", "🚀", "👟"];

  String getRandomEmoji() {
    runEmojis.shuffle();
    return runEmojis.first;
  }

  Map<String, List<Map<String, dynamic>>> groupRunsByDate(
    List<Map<String, dynamic>> runs,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var run in runs) {
      DateTime date = DateTime.parse(run["date"]);

      String formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      if (!grouped.containsKey(formattedDate)) {
        grouped[formattedDate] = [];
      }

      grouped[formattedDate]!.add(run);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedRuns = groupRunsByDate(widget.items);

    final dates = groupedRuns.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    return Column(
      children: [
        Expanded(
          child: widget.items.isEmpty
              ? const Center(child: Text("No runs yet"))
              : ListView(
                  children: dates.map((date) {
                    final runs = groupedRuns[date]!;

                    return ExpansionTile(
                      title: Text(
                        date,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      initiallyExpanded: true, // 👈 open by default (optional)
                      children: runs.map((run) {
                        return ListTile(
                          leading: const Icon(Icons.directions_run),
                          title: Text("${getRandomEmoji()} ${run["title"]}"),
                          subtitle: Text("${run["steps"]} steps"),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
