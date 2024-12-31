import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class Link extends ChangeNotifier {
  bool isLoading = true;
  late Web3Client ethClient;
  late DeployedContract contract;
  late String contractAddress;
  late String _abiCode;
  final String _rpcUrl = 'http://192.168.1.113:7545';
  final String _wsUrl = 'ws://192.168.1.113:7545';

  final String _privateKey =
      '0xd9741e09aa1ea25666545756b5df94d22ed1b8b7b743e4c957eab3d2f8bec4f8';
  Credentials? credentials;

  Link() {
    initialize();
  }

  // Assurez-vous que tout est bien initialisé avant de passer à l'étape suivante
  Future<void> initialize() async {
    await initialSetup(); // Attendre l'initialisation complète
    isLoading = false; // Modifier l'état lorsque l'initialisation est terminée
    notifyListeners();
  }

  // Initialisation des paramètres nécessaires
  Future<void> initialSetup() async {
    ethClient = Web3Client(_rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });

    await getAbi();
    await getCredentials();
  }

  // Charger l'ABI et l'adresse du contrat
  Future<void> getAbi() async {
    String abiString =
        await rootBundle.loadString("build/contracts/HotelBlockchain.json");
    var jsonAbi = jsonDecode(abiString);

    _abiCode = jsonEncode(jsonAbi["abi"]);

    contractAddress = "0xaC77C60F2cC1A097Ff6Fc101d9b4B00231a1D01e";

    contract = DeployedContract(
      ContractAbi.fromJson(_abiCode, "HotelBlockchain.json"),
      EthereumAddress.fromHex(contractAddress),
    );
  }

  // Charger les identifiants privés
  Future<void> getCredentials() async {
    credentials = EthPrivateKey.fromHex(_privateKey);
  }

  // Fonction de validation avant d'utiliser le contrat
  Future<String> registerRoom(int roomId, String ipfsHash) async {
    if (isLoading) {
      // Attendez que l'initialisation soit terminée
      await initialize();
    }

    try {
      // Déboguer : afficher roomId et ipfsHash
      print('Registering Room:');
      print('Room ID: $roomId');
      print('IPFS Hash: $ipfsHash');

      return await sendTransaction(
          "registerRoom", [BigInt.from(roomId), ipfsHash]);
    } catch (e) {
      // En cas d'erreur, afficher l'exception
      print('Error registering room: $e');
      rethrow;
    }
  }

  // Fonction pour envoyer une transaction
  Future<String> sendTransaction(
      String functionName, List<dynamic> args) async {
    final function = contract.function(functionName);
    final result = await ethClient.sendTransaction(
      credentials!,
      Transaction.callContract(
        contract: contract,
        function: function,
        parameters: args,
      ),
      chainId: 1337, // Remplacer par votre ID de chaîne si nécessaire
    );
    return result;
  }

  // Fonction pour appeler une fonction (en lecture seule)
  Future<List<dynamic>> callFunction(
      String functionName, List<dynamic> args) async {
    final function = contract.function(functionName);
    final result = await ethClient.call(
      contract: contract,
      function: function,
      params: args,
    );
    return result;
  }

  // Fonction pour récupérer les détails d'une chambre par ID
  Future<Map<String, dynamic>> getRoomById(int roomId) async {
    try {
      final result = await callFunction("getRoomById", [BigInt.from(roomId)]);
      return {
        "roomId": result[0] as BigInt,
        "ipfsHash": result[1] as String,
        "assignedBy": result[2] as EthereumAddress,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Fonction pour récupérer l'ID de la chambre par l'IPFS hash
  Future<int> getRoomIdByIpfsHash(String ipfsHash) async {
    try {
      final result = await callFunction("getRoomIdByIpfsHash", [ipfsHash]);
      return (result[0] as BigInt).toInt();
    } catch (e) {
      rethrow;
    }
  }
}
