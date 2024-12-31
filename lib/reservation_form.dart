import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:hotel_reservation/link.dart';

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
  String _uploadStatus = '';
  String _ipfsHash = '';

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

      switch (_currentPhotoIndex) {
        case 1:
          await _sendImageToServer(File(pickedFile.path), "image1");
          break;
        case 2:
          await _sendImageToServer(File(pickedFile.path), "image2");
          break;
        case 3:
          await _sendImageToServer(File(pickedFile.path), "image3");
          break;
      }
    }
  }

  Future<void> _sendImageToServer(File imageFile, String imageName) async {
    final uri = Uri.parse('http://192.168.1.113:5000/extract_features');
    final request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final extractedFeatures = json.decode(responseBody)['features'];

      setState(() {
        switch (imageName) {
          case "image1":
            _frontResponse = extractedFeatures.toString();
            break;
          case "image2":
            _leftResponse = extractedFeatures.toString();
            break;
          case "image3":
            _rightResponse = extractedFeatures.toString();
            break;
        }
      });

      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/user_data.json";
      final file = File(filePath);

      Map<String, dynamic> userData;

      if (await file.exists()) {
        final existingContent = await file.readAsString();
        userData = json.decode(existingContent);
      } else {
        userData = {
          "full_name": "Marwa CHAARI",
          "id": "11669933",
          "phone_number": "98650420",
          "nights_to_stay": 3,
          "features": {}
        };
      }

      if (userData["features"] == null) {
        userData["features"] = {};
      }

      userData["features"][imageName] = extractedFeatures;

      final jsonString = json.encode(userData);
      await file.writeAsString(jsonString);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$imageName features added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: ${response.statusCode}')),
      );
    }
  }

  Future<void> _sendDataToIPFS() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/user_data.json";
      final jsonFile = File(filePath);

      if (await jsonFile.exists()) {
        final url = Uri.parse('https://api.pinata.cloud/pinning/pinFileToIPFS');
        final request = http.MultipartRequest('POST', url);

        request.files
            .add(await http.MultipartFile.fromPath('file', jsonFile.path));

        request.headers.addAll({
          'pinata_api_key': '7b1dd642ae011dc2f4cb',
          'pinata_secret_api_key':
              '53707391c25f9622b0b057d69c921fbb5ec9511b2951475ed27ceaa1e32dd147',
        });

        final response = await request.send();
        setState(() {
          _uploadStatus = 'HTTP Status: ${response.statusCode}';
        });

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final ipfsHash = json.decode(responseBody)['IpfsHash'];
          setState(() {
            _ipfsHash = ipfsHash;
          });
        } else {
          setState(() {
            _ipfsHash = 'Failed to upload file';
          });
        }
      } else {
        setState(() {
          _uploadStatus = 'File not found';
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'Error: $e';
      });
    }
  }

  void testConnection() async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://192.168.100.220:7545'), // Changez l'URL selon votre configuration
        headers: {"Content-Type": "application/json"},
        body:
            '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}',
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    } catch (e) {
      print('Error connecting to Ganache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractLinking = Provider.of<Link>(context, listen: false);

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
                  labelText: 'ID',
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
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nights to stay',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // testConnection();
                    // Étape 1 : Envoyer les données à IPFS
                    await _sendDataToIPFS();

                    // Étape 2 : Enregistrer la chambre sur la blockchain avec l'IPFS Hash
                    await contractLinking.registerRoom(9, _ipfsHash);

                    // Vous pouvez ajouter un message de succès si nécessaire
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Chambre enregistrée avec succès !')),
                    );
                  } catch (e) {
                    // Afficher l'erreur si l'une des étapes échoue
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur : $e')),
                    );
                  }
                },
                child: Text('Envoyer'),
              ),
              // Text(
              //   _uploadStatus,
              //   style: TextStyle(color: Colors.red, fontSize: 16),
              // ),
              // SizedBox(height: 10),
              // if (_ipfsHash.isNotEmpty)
              //   Text(
              //     'IPFS Hash: $_ipfsHash',
              //     style: TextStyle(color: Colors.green, fontSize: 16),
              //   ),
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
