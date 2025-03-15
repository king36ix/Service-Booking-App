import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:location/location.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class BizRegScreen extends StatefulWidget {
  @override
  _BizRegScreenState createState() => _BizRegScreenState();
}

class _BizRegScreenState extends State<BizRegScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Location _location = Location();

  // Form fields
  String _name = '';
  String _address = '';
  double _rating = 0.0;
  double? _latitude;
  double? _longitude;
  File? _imageFile;
  bool _isSubmitting = false;
  bool _useCurrentLocation = false;
  Set<String> _bizServices = {};


  // Predefined business categories
  final List<String> _categories = ['Manicure', 'Spa', 'Barber', 'Entertainment', 'Services', 'Healthcare', 'Education', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register Business')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImagePicker(),
                SizedBox(height: 16),
                _buildTextField('Business Name', Icons.business, (value) => _name = value!),
                SizedBox(height: 16),
                _buildCategorySelector(),
                SizedBox(height: 16),
                _buildTextField('Address', Icons.location_on, (value) => _address = value!, maxLines: 2),
                SizedBox(height: 16),
                _buildLocationSwitch(),
                if (!_useCurrentLocation) _buildManualLocationFields(),
                SizedBox(height: 16),
                _buildRatingSlider(),
                SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Image Picker Widget
  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: _imageFile != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_imageFile!, fit: BoxFit.cover),
          )
              : Icon(Icons.add_a_photo, size: 50, color: Colors.grey[400]),
        ),
      ),
    );
  }

  // Generic Text Field Widget
  Widget _buildTextField(String label, IconData icon, Function(String?) onSaved, {int maxLines = 1}) {
    return TextFormField(
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(), prefixIcon: Icon(icon)),
      maxLines: maxLines,
      validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
      onSaved: onSaved,
    );
  }

  // Multi-Checkbox Category Selector
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Column(
          children: _categories.map((category) {
            return CheckboxListTile(
              title: Text(category),
              value: _bizServices.contains(category),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    _bizServices.add(category);
                  } else {
                    _bizServices.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }


  // Toggle for using current location
  Widget _buildLocationSwitch() {
    return Row(
      children: [
        Expanded(child: Text('Use current location for coordinates?')),
        Switch(value: _useCurrentLocation, onChanged: (value) => setState(() => _useCurrentLocation = value)),
      ],
    );
  }

  // Manual latitude and longitude entry
  Widget _buildManualLocationFields() {
    return Row(
      children: [
        Expanded(child: _buildTextField('Latitude', Icons.map, (value) => _latitude = double.parse(value!), maxLines: 1)),
        SizedBox(width: 16),
        Expanded(child: _buildTextField('Longitude', Icons.map, (value) => _longitude = double.parse(value!), maxLines: 1)),
      ],
    );
  }

  // Rating Slider
  Widget _buildRatingSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Initial Rating (optional)'),
        Slider(
          value: _rating,
          min: 0,
          max: 5,
          divisions: 10,
          label: _rating.toString(),
          onChanged: (value) => setState(() => _rating = value),
        ),
      ],
    );
  }

  // Submit Button
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      child: _isSubmitting ? CircularProgressIndicator(color: Colors.white) : Text('REGISTER BUSINESS', style: TextStyle(fontSize: 16)),
    );
  }

  // Image Picker Method
  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imageFile = File(image.path));
  }

  // Upload Image to Firebase Storage
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    try {
      String fileName = 'business_images/${Uuid().v4()}';
      final Reference storageRef = _storage.ref().child(fileName);
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e'))
      );
      return null;
    }
  }

  // Get Current Location
  Future<void> _getCurrentLocation() async {
    try {
      if (!await _location.serviceEnabled()) await _location.requestService();
      if (await _location.hasPermission() == PermissionStatus.denied) await _location.requestPermission();
      LocationData locationData = await _location.getLocation();
      _latitude = locationData.latitude;
      _longitude = locationData.longitude;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  // Form Submission
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_useCurrentLocation) await _getCurrentLocation();
      String? imageUrl = await _uploadImage();
      await _firestore.collection('businesses').add({
        'name': _name,
        'categories': _bizServices.toList(), // Store as an array
        'address': _address,
        'latitude': _latitude,
        'longitude': _longitude,
        'rating': _rating,
        'imageUrl': imageUrl ?? '',
      });
      Navigator.pop(context);
    }
  }
}
