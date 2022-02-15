const Lotto = artifacts.require('Lotto.sol');
const NftLottery = artifacts.require('NftLottery.sol');

module.exports = function(deployer){
    deployer.deploy(NftLottery).then(() => {
        return deployer.deploy(Lotto, NftLottery.address);
    });
};