const Token = artifacts.require("Token");

module.exports = async function (deployer) {
  deployer.deploy(Token, "AndrewToken", "AML");
};