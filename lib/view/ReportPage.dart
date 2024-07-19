import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportPage extends StatelessWidget {
  final List<Map<String, dynamic>> events;

  ReportPage({required this.events});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Report'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Event Analysis",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 20),
              _buildPieChart(),
              SizedBox(height: 20),
              _buildSummary(),
              SizedBox(height: 20),
              _buildFavoriteEvent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    Map<String, int> eventCounts = {};

    for (var event in events) {
      final eventId = event['eventId'] as String;
      if (eventCounts.containsKey(eventId)) {
        eventCounts[eventId] = eventCounts[eventId]! + (event['totalTimeSpent'] as int);
      } else {
        eventCounts[eventId] = event['totalTimeSpent'] as int;
      }
    }

    List<charts.Series<MapEntry<String, int>, String>> series = [
      charts.Series(
        id: 'Events',
        data: eventCounts.entries.toList(),
        domainFn: (MapEntry<String, int> entry, _) => entry.key,
        measureFn: (MapEntry<String, int> entry, _) => entry.value,
        labelAccessorFn: (MapEntry<String, int> entry, _) => '${entry.key}: ${entry.value}',
      ),
    ];

    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Time Allocation by Event",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 10),
            Container(
              height: 200,
              child: charts.PieChart<String>(
                series,
                animate: true,
                defaultRenderer: charts.ArcRendererConfig(
                  arcRendererDecorators: [charts.ArcLabelDecorator()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    Map<String, int> timeSpentPerEvent = {};

    for (var event in events) {
      final eventId = event['eventId'] as String;
      final totalTimeSpent = event['totalTimeSpent'] as int;
      if (timeSpentPerEvent.containsKey(eventId)) {
        timeSpentPerEvent[eventId] = timeSpentPerEvent[eventId]! + totalTimeSpent;
      } else {
        timeSpentPerEvent[eventId] = totalTimeSpent;
      }
    }

    String favoriteEventId = timeSpentPerEvent.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    int totalEvents = timeSpentPerEvent.length;
    int totalTimeSpent = timeSpentPerEvent.values.fold(0, (sum, item) => sum + item);

    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 10),
            Text("Total Events: $totalEvents", style: TextStyle(fontSize: 16)),
            Text("Total Time Spent: ${formatDuration(totalTimeSpent)}", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteEvent() {
    if (events.isEmpty) return Text('No events found.', style: TextStyle(color: Colors.white, fontSize: 16));

    Map<String, int> timeSpentPerEvent = {};

    for (var event in events) {
      final eventId = event['eventId'] as String;
      final totalTimeSpent = event['totalTimeSpent'] as int;
      if (timeSpentPerEvent.containsKey(eventId)) {
        timeSpentPerEvent[eventId] = timeSpentPerEvent[eventId]! + totalTimeSpent;
      } else {
        timeSpentPerEvent[eventId] = totalTimeSpent;
      }
    }

    String favoriteEventId = timeSpentPerEvent.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Favorite Event",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 10),
            Text('Favorite Event ID: $favoriteEventId', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  String formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
