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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Event Analysis",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildPieChart(),
            SizedBox(height: 20),
            _buildTimeSpentHistogram(),
            SizedBox(height: 20),
            _buildFavoriteEvent(),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    // Aggregate total time spent per event
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

    List<charts.Series<MapEntry<String, int>, String>> series = [
      charts.Series(
        id: 'Events',
        data: timeSpentPerEvent.entries.toList(),
        domainFn: (MapEntry<String, int> entry, _) => entry.key,
        measureFn: (MapEntry<String, int> entry, _) => entry.value,
        labelAccessorFn: (MapEntry<String, int> entry, _) => '${entry.key}: ${entry.value}',
      ),
    ];

    return Container(
      height: 300,
      child: charts.PieChart<String>(
        series,
        animate: true,
        defaultRenderer: charts.ArcRendererConfig(
          arcRendererDecorators: [charts.ArcLabelDecorator()],
        ),
      ),
    );
  }

  Widget _buildTimeSpentHistogram() {
    // Prepare data for histogram
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

    List<charts.Series<EventData, String>> series = [
      charts.Series(
        id: 'TimeSpent',
        data: timeSpentPerEvent.entries.map((entry) => EventData(entry.key, entry.value)).toList(),
        domainFn: (EventData data, _) => data.eventId,
        measureFn: (EventData data, _) => data.timeSpent,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      ),
    ];

    return Container(
      height: 300,
      child: charts.BarChart(
        series,
        animate: true,
        barRendererDecorator: charts.BarLabelDecorator<String>(),
      ),
    );
  }

  Widget _buildFavoriteEvent() {
    if (events.isEmpty) return Text('No events found.');

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

    return Text('Favorite Event: $favoriteEventId');
  }
}

class EventData {
  final String eventId;
  final int timeSpent;

  EventData(this.eventId, this.timeSpent);
}
