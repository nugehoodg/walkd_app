import 'package:flutter/material.dart';

class PreviousRunPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const PreviousRunPage({super.key, required this.items});

  @override
  State<PreviousRunPage> createState() => _PreviousRunPageState();
}

class _PreviousRunPageState extends State<PreviousRunPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.items.isEmpty
              ? const Center(child: Text("No runs yet"))
              : ListView.builder(
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final run = widget.items[index];

                    return ListTile(
                      leading: const Icon(Icons.directions_run),
                      title: Text(run["title"]),
                      subtitle: Text("${run["steps"]} steps • ${run["date"]}"),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
