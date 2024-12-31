import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hotel_reservation/link.dart';

class VerifyPerson extends StatefulWidget {
  @override
  _VerifyPersonState createState() => _VerifyPersonState();
}

class _VerifyPersonState extends State<VerifyPerson> {
  String statusMessage = "Chargement des données...";
  Map<String, dynamic>? features;
  File? _image;
  final picker = ImagePicker();

  Future<Map<String, dynamic>> getJsonFromPinata(String ipfsHash) async {
    final pinataApiUrl = 'https://gateway.pinata.cloud/ipfs/$ipfsHash';

    try {
      final response = await http.get(Uri.parse(pinataApiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        throw Exception('Failed to load IPFS content');
      }
    } catch (e) {
      throw Exception('Failed to load IPFS content: $e');
    }
  }

  Future<void> extractFeaturesFromIpfs(String ipfsHash) async {
    setState(() {
      statusMessage = "Extraction des données depuis IPFS...";
    });

    try {
      final jsonResponse = await getJsonFromPinata(ipfsHash);
      final Map<String, dynamic> extractedFeatures = jsonResponse['features'];
      setState(() {
        features = extractedFeatures;
        statusMessage = "Données extraites avec succès!";
      });
      await sendFeaturesToFlask(extractedFeatures);
    } catch (e) {
      setState(() {
        statusMessage = "Erreur : $e";
      });
    }
  }

  Future<void> sendFeaturesToFlask(Map<String, dynamic> features) async {
    final uri = Uri.parse('http://192.168.1.113:5000/receive_features');
    final request = http.MultipartRequest('POST', uri);

    request.fields['features'] = json.encode(features);

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        setState(() {
          statusMessage =
              'Les caractéristiques ont été envoyées avec succès au serveur Flask!';
        });
      } else {
        setState(() {
          statusMessage =
              'Échec de l\'envoi des caractéristiques : ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Erreur lors de l\'envoi des caractéristiques : $e';
      });
    }
  }

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      if (_image != null) {
        await verifyPersonWithFlask(_image!);
      }
    }
  }

  Future<void> verifyPersonWithFlask(File imageFile) async {
    final uri = Uri.parse('http://192.168.1.113:5000/verify_person');
    var request = http.MultipartRequest('POST', uri);
    var stream = http.ByteStream(imageFile.openRead());
    var length = await imageFile.length();
    var multipartFile = http.MultipartFile('file', stream, length,
        filename: imageFile.path.split('/').last);
    request.files.add(multipartFile);

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      setState(() {
        if (response.statusCode == 200) {
          statusMessage = "Personne identifiée!";
          //}\nCorrespondances: ${jsonResponse['matches'].join(', ')
        } else if (response.statusCode == 404) {
          statusMessage = "Aucune correspondance trouvée.";
        } else {
          statusMessage =
              "Erreur: ${jsonResponse['error'] ?? 'Erreur inconnue'}";
        }
      });
    } catch (e) {
      setState(() {
        statusMessage = "Erreur lors de la vérification: $e";
      });
    }
  }

  // @override
  // void initState() {
  //   final contractLinking = Provider.of<Link>(context, listen: false);
  //   super.initState();
  //   final roomData = contractLinking.getRoomById(3);
  //   // extractFeaturesFromIpfs(
  //   //     'QmZWGppw2Jyw8RgPoFizqdpfZZKVEef6xXrx8YhjuaABqY'); //Put here the ipfsHash of the user
  //   extractFeaturesFromIpfs(
  //       roomData["ipfsHash"]); //Put here the ipfsHash of the user
  // }
  @override
  void initState() async {
    super.initState();
    final contractLinking = Provider.of<Link>(context, listen: false);
    final roomData = await contractLinking.getRoomById(9); // Or use user input
    extractFeaturesFromIpfs(roomData["ipfsHash"]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Person'),
      ),
      body: Center(
        child: features == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(statusMessage),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(statusMessage),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _getImage,
                    child: Text('Prendre une photo'),
                  ),
                ],
              ),
      ),
    );
  }
}
