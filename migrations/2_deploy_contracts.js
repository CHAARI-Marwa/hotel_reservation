const HotelBlockchain = artifacts.require("HotelBlockchain");

module.exports = function (deployer) {
  deployer.deploy(HotelBlockchain);
};