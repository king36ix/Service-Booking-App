import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'bizdetails.dart';



class BizList extends StatefulWidget {
  @override
  _BizListState createState() => _BizListState();
}

class _BizListState extends State<BizList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LocationData? _currentLocation;
  bool _isLoading = true;
  List<Map<String, dynamic>> _businesses = [];
  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    // Check if permission is granted
    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    // Get location
    final locationData = await _locationService.getLocation();
    setState(() {
      _currentLocation = locationData;
    });

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
          'phoneNumber':data['phoneNumber']??'No phone number available',
          'rating': data['rating'] ?? 0.0,
          'imageUrl': data['imageUrl'] ?? '',
        });
      }

      // Sort by distance
      businessList.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        _businesses = businessList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching businesses: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
          : _businesses.isEmpty
          ? Center(child: Text('No businesses found'))
          : ListView.builder(
        itemCount: _businesses.length,
        itemBuilder: (context, index) {
          final business = _businesses[index];
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
                  Text(business['address'], style: TextStyle(fontSize: 12)),
                  Text(business['phoneNumber'], style: TextStyle(fontSize: 12)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('${business['rating'].toStringAsFixed(1)}'),
                    ],
                  ),
                ],
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDistance(business['distance']),
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              isThreeLine: true,
              onTap: () {
                // Navigate to business details page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusinessDetailScreen(business: business),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

