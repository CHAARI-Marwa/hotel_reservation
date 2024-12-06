import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import pour ImageSource
import 'package:http/http.dart' as http;
import 'dart:io';

class ReservationForm extends StatefulWidget {
  @override
  _ReservationFormState createState() => _ReservationFormState();
}

class _ReservationFormState extends State<ReservationForm> {
  final ImagePicker picker = ImagePicker();
  File? _frontImage;
  File? _leftImage;
  File? _rightImage;

  int _currentPhotoIndex = 0;
  String _frontResponse = '';
  String _leftResponse = '';
  String _rightResponse = '';

  String get _photoInstructions {
    switch (_currentPhotoIndex) {
      case 0:
        return "Please take a photo of your face from the front";
      case 1:
        return "Please take a photo of the left side of your face";
      case 2:
        return "Please take a photo of the right side of your face";
      default:
        return "All photos completed";
    }
  }

  Future<void> getImageFromCamera() async {
    if (_currentPhotoIndex >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All required photos have been taken')),
      );
      return;
    }

    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        switch (_currentPhotoIndex) {
          case 0:
            _frontImage = File(pickedFile.path);
            break;
          case 1:
            _leftImage = File(pickedFile.path);
            break;
          case 2:
            _rightImage = File(pickedFile.path);
            break;
        }
        _currentPhotoIndex++;
      });
      await _sendImageToServer(File(pickedFile.path));
    }
  }

  Future<void> _sendImageToServer(File imageFile) async {
    final uri = Uri.parse(
        'http:///*Put the ip @ of your computer*/:5000/extract_features');
    final request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      setState(() {
        switch (_currentPhotoIndex - 1) {
          case 0:
            _frontResponse = responseBody;
            break;
          case 1:
            _leftResponse = responseBody;
            break;
          case 2:
            _rightResponse = responseBody;
            break;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réservation'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _photoInstructions,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPhotoContainer('Front Photo', _frontImage),
                  _buildPhotoContainer('Left Side', _leftImage),
                  _buildPhotoContainer('Right Side', _rightImage),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _currentPhotoIndex < 3 ? getImageFromCamera : null,
                  child: Text(_currentPhotoIndex < 3
                      ? 'Take Photo ${_currentPhotoIndex + 1} of 3'
                      : 'Photos Complete'),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Responses:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Réservation envoyée !')),
                  );
                },
                child: Text('Envoyer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoContainer(String label, File? image) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(Icons.person, size: 50, color: Colors.grey),
        ),
        SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
