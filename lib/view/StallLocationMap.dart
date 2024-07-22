import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StallLocationMap extends StatefulWidget {
  const StallLocationMap({Key? key}) : super(key: key);

  @override
  State<StallLocationMap> createState() => _StallLocationMapState();
}

class _StallLocationMapState extends State<StallLocationMap> {
  Map<String, String> _stallMap = {};
  Map<String, String> _filteredStallMap = {};
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStallMap();
    _searchController.addListener(() => _filterStalls(_searchController.text));
  }

  Future<void> _fetchStallMap() async {
    final stallMapDocRef = FirebaseFirestore.instance.collection('stallMap').doc('HdFbY9S1XyLHqKGuOLAE');
    DocumentSnapshot stallMapDocSnapshot = await stallMapDocRef.get();
    Map<String, dynamic> mapData = stallMapDocSnapshot.data() as Map<String, dynamic>;
    Map<String, dynamic> mapValues = mapData['stallMap'];

    setState(() {
      _stallMap = mapValues.map((key, value) => MapEntry(key.toString(), value.toString()));
      _filteredStallMap = Map.from(_stallMap); // Initialize the filtered map with all stalls
    });
  }

  void _filterStalls(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStallMap = Map.from(_stallMap);
      } else {
        Map<String, String> tempFilteredStallMap = {};
        _stallMap.forEach((key, value) {
          if (key.toLowerCase().contains(query.toLowerCase()) ||
              value.toLowerCase().contains(query.toLowerCase())) {
            tempFilteredStallMap[key] = value;
          }
        });
        _filteredStallMap = tempFilteredStallMap;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stall Location Map'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Stall Number or Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _filteredStallMap.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 3 / 2,
                      ),
                      itemCount: _filteredStallMap.length,
                      itemBuilder: (context, index) {
                        String key = _filteredStallMap.keys.elementAt(index);
                        String value = _filteredStallMap[key]!;
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Stall $key',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  value,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: StallLocationMap(),
    theme: ThemeData(
      primarySwatch: Colors.green,
      textTheme: TextTheme(
        headline1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headline6: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        bodyText2: TextStyle(fontSize: 16),
      ),
    ),
  ));
}
