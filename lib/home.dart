import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => LandingPageState();
}

class LandingPageState extends State<SearchScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Forces UI to update when text changes
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String searchTerm) async {
    if (searchTerm.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('your_collection') // Replace with your Firestore collection
          .orderBy('name')
          .startAt([searchTerm])
          .endAt([searchTerm + '\uf8ff'])
          .get();

      setState(() {
        _searchResults = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error performing search: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error performing search: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                          : null,
                    ),
                    onSubmitted: (value) => _performSearch(value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _performSearch(_searchController.text);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(child: Text("No results found"))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> result = _searchResults[index];
                return ListTile(
                  title: Text(result['name'] ?? 'No Name'),
                  subtitle: Text(result['description'] ?? ''), // Add more fields if needed
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
