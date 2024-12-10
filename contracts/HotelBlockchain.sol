// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HotelBlockchain {
    struct Reservation {
        uint256 roomId;          // Numéro de chambre
        string userId;           // ID unique de l'utilisateur (sous forme de string, comme un hash IPFS)
        uint256 amountPaid;      // Montant payé
        address reserver;        // Adresse Ethereum de la personne
    }

    // Mapping pour stocker les réservations par numéro de chambre
    mapping(uint256 => Reservation) public reservations;

    // Adresse du propriétaire du contrat
    address public owner;

    // Événement pour signaler une nouvelle réservation
    event RoomReserved(uint256 roomId, string userId, uint256 amountPaid, address reserver);

    // Constructeur pour initialiser le propriétaire
    constructor() {
        owner = msg.sender;
    }

    /// @notice Permet de réserver une chambre
    /// @param _roomId Le numéro de la chambre
    /// @param _userId L'ID unique de l'utilisateur (hash ou string)
    function reserveRoom(uint256 _roomId, string memory _userId) public payable {
        require(_roomId > 0, "roomId doit etre superieur a 0");
        require(bytes(_userId).length > 0, "userId doit etre valide");
        require(reservations[_roomId].roomId == 0, "Chambre deja reservee");
        require(msg.value > 0, "Le paiement doit etre superieur a 0");

        // Enregistre la réservation
        reservations[_roomId] = Reservation({
            roomId: _roomId,
            userId: _userId,
            amountPaid: msg.value,
            reserver: msg.sender
        });

        // Émet un événement pour la réservation
        emit RoomReserved(_roomId, _userId, msg.value, msg.sender);
    }

    /// @notice Vérifie si un utilisateur a accès à une chambre
    /// @param _roomId Le numéro de la chambre
    /// @param _userId L'ID unique de l'utilisateur (hash ou string)
    /// @return bool True si l'utilisateur a accès, false sinon
    function verifyAccess(uint256 _roomId, string memory _userId) public view returns (bool) {
        Reservation memory reservation = reservations[_roomId];
        require(reservation.roomId != 0, "Aucune reservation pour cette chambre");
        
        return keccak256(abi.encodePacked(reservation.userId)) == keccak256(abi.encodePacked(_userId));
    }

    /// @notice Récupère les détails d'une réservation
    /// @param _roomId Le numéro de la chambre
    /// @return Reservation La réservation correspondante
    function getReservation(uint256 _roomId) public view returns (Reservation memory) {
        return reservations[_roomId];
    }
}