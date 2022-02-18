const LuckyMintLotto = artifacts.require('LuckyMintLotto.sol');
const LuckyMintNFT = artifacts.require('LuckyMintNFT.sol');

module.exports = function(deployer){
    deployer.deploy(LuckyMintNFT).then(() => {
        return deployer.deploy(LuckyMintLotto, LuckyMintNFT.address);
    });
};