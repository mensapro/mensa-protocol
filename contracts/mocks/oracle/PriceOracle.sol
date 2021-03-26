pragma solidity ^0.5.0;

import "../../interfaces/IPriceOracle.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract PriceOracle is Ownable, IPriceOracle {

    mapping(address => uint256) prices;
    uint256 ethPriceUsd;

    event AssetPriceUpdated(address _asset, uint256 _price, uint256 timestamp);
    event EthPriceUpdated(uint256 _price, uint256 timestamp);

    function getAssetPrice(address _asset) external view returns(uint256) {
        return prices[_asset];
    }

    function setAssetPrice(address _asset, uint256 _price) external onlyOwner {
        prices[_asset] = _price;
        emit AssetPriceUpdated(_asset, _price, block.timestamp);
    }

    function getEthUsdPrice() external view returns(uint256) {
        return ethPriceUsd;
    }

    function setEthUsdPrice(uint256 _price) external onlyOwner {
        ethPriceUsd = _price;
        emit EthPriceUpdated(_price, block.timestamp);
    }
}
