import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'bizdetails.dart';

class ServiceList extends StatefulWidget {
  @override
  _ServiceListState createState() => _ServiceListState();
}

class _ServiceListState extends State<ServiceList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LocationData? _currentLocation;
  bool _isLoading = true;
  List<Map<String, dynamic>> _businesses = []; // Original list
  List<Map<String, dynamic>> _filteredBusinesses = []; // Filtered list
  final Location _locationService = Location();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer; // Debouncing timer

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    // ... (rest of your _getCurrentLocation() code is the same) ...
    await _fetchBusinesses();
  }

  Future<void> _fetchBusinesses() async {
    if (_currentLocation == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      // Fetch businesses from Firestore
      QuerySnapshot snapshot = await _firestore.collection('businesses').get();
      List<Map<String, dynamic>> businessList = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Calculate distance if location data is available
        double distance = 0.0;
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          distance = Geolocator.distanceBetween(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
            data['latitude'],
            data['longitude'],
          );

          // Convert to kilometers
          distance = distance / 1000;
        }

        businessList.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Business',
          'category': data['category'] ?? 'Uncategorized',
          'distance': distance,
          'address': data['address'] ?? 'No address available',
          'phoneNumber': data['phoneNumber'] ?? 'No phone number available',
          'rating': data['rating'] ?? 0.0,
          'imageUrl': data['imageUrl'] ?? '',
        });
      }

      // Sort by distance (primary) then by rating (secondary)
      businessList.sort((a, b) {
        // Compare by distance first
        int distanceComparison = a['distance'].compareTo(b['distance']);

        // If distances are equal, compare by rating
        if (distanceComparison == 0) {
          // Handle cases where 'rating' might be null or not a number
          double ratingA = (a['rating'] is num) ? (a['rating'] as num)
              .toDouble() : 0.0;
          double ratingB = (b['rating'] is num) ? (b['rating'] as num)
              .toDouble() : 0.0;
          return ratingB.compareTo(
              ratingA); // Sort in descending order (highest rating first)
        } else {
          return distanceComparison; // Distances are different, use distance comparison
        }
      });
      setState(() {
        _businesses = businessList;
        _filteredBusinesses = businessList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching businesses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _filterBusinesses(_searchController.text);
    });
  }

  void _filterBusinesses(String query) {
    List<Map<String, dynamic>> filteredList = [];
    if (query.isEmpty) {
      filteredList.addAll(_businesses);
    } else {
      filteredList.addAll(_businesses.where((business) {
        final name = business['name'].toString().toLowerCase();
        final category = business['category'].toString().toLowerCase();
        final address = business['address'].toString().toLowerCase();
        final queryLower = query.toLowerCase();
        return name.contains(queryLower) ||
            category.contains(queryLower) ||
            address.contains(queryLower);
      }));
    }
    setState(() {
      _filteredBusinesses = filteredList;
    });
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Businesses'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _getCurrentLocation();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _currentLocation == null
          ? Center(child: Text('Location service is not available'))
          : Column(
          children: [
      Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search Businesses',
          hintText: 'Search by name, category, or address',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
    ),
    Expanded(
    child: _filteredBusinesses.isEmpty
    ? Center(child: Text('No businesses found'))
        : ListView.builder(
    itemCount: _filteredBusinesses.length,
    itemBuilder: (context, index) {
    final business = _filteredBusinesses[index];
    return Card(
    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: ListTile(
    leading: business['imageUrl'].isNotEmpty
    ? ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: Image.network(
    business['imageUrl'],
    width: 50,
    height: 50,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) =>
    Container(
    width: 50,
    height: 50,
    color: Colors.grey[300],
    child: Icon(Icons.business, color: Colors.grey[600]),
    ),
    ),
    )
        : Container(
    width: 50,
    height: 50,
    color: Colors.grey[300],
    child: Icon(Icons.business, color: Colors.grey[600]),
    ),
    title: Text(
    business['name'],
    style: TextStyle(fontWeight: FontWeight.bold),
    ),
    subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(business['category']),
    Text(