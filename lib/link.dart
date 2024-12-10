import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart'; // For WebSocket connection

class Link extends ChangeNotifier {
  List<Note> notes = [];
  final String _rpcUrl = 'http://127.0.0.1:7545';
  final String _wsUrl = 'ws://127.0.0.1:7545';
  bool isLoading = true;

  final String _privatekey = '0xad15cbef8708bc894c7790a137ffe0ecbf1b756f515fab4b723ef1dce6c7eea3';
  Credentials? credentials;

  late Web3Client ethClient;
  late DeployedContract contract;
  late String _abiCode;
  late String contractAddress;

  Link() {
    initialize();
  }

  Future<void> initialize() async {
    await initialSetup();
    isLoading = false;
    notifyListeners();
  }

  // Function to establish Web3Client connection
  Future<void> initialSetup() async {
    // Web3Client setup using WebSocket for real-time events
    ethClient = Web3Client(_rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });

    // Load the contract ABI and setup the deployed contract
    await getAbi();
    await getCredentials();
  }

  // Function to load the ABI from the asset and initialize the contract
  Future<void> getAbi() async {
    String abiString =
        await rootBundle.loadString("build/contracts/HotelBlockchain.json");
    var jsonAbi = jsonDecode(abiString);

    // Extract the ABI from the loaded JSON
    _abiCode = jsonEncode(jsonAbi["abi"]);

    contractAddress = "0xCdFA6bB322ACf675cc024FeA75b2E05E4Edc01EE";

    // Initialize the deployed contract
    contract = DeployedContract(
      ContractAbi.fromJson(_abiCode, "HotelBlockchain.json"),
      EthereumAddress.fromHex(contractAddress),
    );
  }

  Future<void> getCredentials() async {
    try {
      credentials = EthPrivateKey.fromHex(_privatekey);
      print("Credentials récupérés avec succès");
    } catch (e) {
      print("Erreur pendant l'obtention des credentials: $e");
    }
  }

  // Function to reserve a room
  Future<void> reserveRoom(int roomId, int userId, double amount) async {
    final reserveRoomFunction = contract.function('reserveRoom');
    
    final result = await ethClient.sendTransaction(
      credentials!,
      Transaction(
        to: EthereumAddress.fromHex(contractAddress),
        data: reserveRoomFunction.encodeCall([
          BigInt.from(roomId),
          BigInt.from(userId),
        ]),
        value: EtherAmount.fromUnitAndValue(EtherUnit.wei, (amount * 1e18).toInt()), // Convert ETH to Wei
      ),
      chainId: null, // Specify the chain ID if necessary
    );
    print("Transaction sent: $result");
  }

  // Function to verify access to a room
  Future<bool> verifyAccess(int roomId, int userId) async {
    final verifyAccessFunction = contract.function('verifyAccess');

    final result = await ethClient.call(
      contract: contract,
      function: verifyAccessFunction,
      params: [
        BigInt.from(roomId),
        BigInt.from(userId),
      ],
    );
    return result.first as bool;
  }

  // Function to get reservation details
  Future<Map<String, dynamic>> getReservation(int roomId) async {
    final getReservationFunction = contract.function('getReservation');

    final result = await ethClient.call(
      contract: contract,
      function: getReservationFunction,
      params: [BigInt.from(roomId)],
    );

    // Parse the result into a map
    return {
      'roomId': result[0],
      'userId': result[1],
      'amountPaid': result[2],
      'reserver': result[3],
    };
  }
}