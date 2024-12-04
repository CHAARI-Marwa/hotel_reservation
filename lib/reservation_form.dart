import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import pour ImageSource
import 'dart:io'; // Pour File

class ReservationForm extends StatefulWidget {
  @override
  _ReservationFormState createState() => _ReservationFormState();
}

class _ReservationFormState extends State<ReservationForm> {
  final ImagePicker picker = ImagePicker(); // Initialisation du picker
  File? _image; // Variable pour stocker l'image capturée
  List<dynamic> objDetect = []; // Liste fictive pour objets détectés
  List<dynamic> boxes = []; // Liste fictive pour les boxes

  Future<void> getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    List<dynamic> newDetectionList =
        []; // Remplacez par la logique de détection réelle

    setState(() {
      objDetect = newDetectionList;
      boxes.clear();
    });

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    List<dynamic> newDetectionList = [];
    setState(() {
      objDetect = newDetectionList;
      boxes.clear();
    });
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réservation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Formulaire de Réservation',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              onPressed: getImageFromCamera,
              style: ElevatedButton.styleFrom(
                side: BorderSide(color: Color(0xFFEAF4F5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
                padding: EdgeInsets.all(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 24),
                  SizedBox(width: 16),
                  Text(
                    'Take Picture',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Afficher l'image capturée si elle existe
            _image != null
                ? Image.file(
                    _image!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : SizedBox(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Ajoutez ici la logique pour soumettre le formulaire
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Réservation envoyée !')),
                );
              },
              child: Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }
}
