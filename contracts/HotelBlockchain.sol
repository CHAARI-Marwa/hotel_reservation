// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HotelBlockchain {
    struct Room {
        uint256 roomId;
        string ipfsHash;
        address assignedBy;
    }

    mapping(uint256 => Room) public rooms; // Map roomId to Room details
    mapping(string => uint256) private ipfsToRoomId; // Map ipfsHash to roomId

    event RoomRegistered(uint256 indexed roomId, string ipfsHash, address indexed assignedBy);

    /**
     * @dev Enregistre une chambre avec un ID spécifique et un hash IPFS.
     * @param roomId L'identifiant unique de la chambre.
     * @param ipfsHash Le hash IPFS associé à cette chambre.
     */
    function registerRoom(uint256 roomId, string memory ipfsHash) public {
        require(rooms[roomId].roomId == 0, "Room ID already exists");
        require(ipfsToRoomId[ipfsHash] == 0, "IPFS hash already assigned");

        rooms[roomId] = Room({
            roomId: roomId,
            ipfsHash: ipfsHash,
            assignedBy: msg.sender
        });

        ipfsToRoomId[ipfsHash] = roomId;

        emit RoomRegistered(roomId, ipfsHash, msg.sender);
    }

    /**
     * @dev Récupère les détails d'une chambre en fonction de son ID.
     * @param roomId L'identifiant unique de la chambre.
     * @return Les détails de la chambre.
     */
    function getRoomById(uint256 roomId) public view returns (Room memory) {
        require(rooms[roomId].roomId != 0, "Room does not exist");
        return rooms[roomId];
    }

    /**
     * @dev Récupère l'ID d'une chambre en fonction de son hash IPFS.
     * @param ipfsHash Le hash IPFS associé à la chambre.
     * @return L'identifiant de la chambre.
     */
    function getRoomIdByIpfsHash(string memory ipfsHash) public view returns (uint256) {
        uint256 roomId = ipfsToRoomId[ipfsHash];
        require(roomId != 0, "IPFS hash not found");
        return roomId;
    }
}
