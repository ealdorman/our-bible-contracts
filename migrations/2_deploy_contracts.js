var TheBible = artifacts.require("./TheBible.sol");

module.exports = function(deployer) {
  deployer.deploy(TheBible);
};
