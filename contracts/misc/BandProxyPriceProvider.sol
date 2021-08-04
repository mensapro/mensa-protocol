pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes)
        external
        view
        returns (ReferenceData[] memory);
}

interface IERC20Symbol {
    function symbol() external view returns (string memory);
}

interface IPriceOracleGetter {
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address _asset) external view returns (uint256);
}

contract BandOracle is IPriceOracleGetter, Ownable {
    event AssetSourceDeleted(address indexed asset);
    event AssetSourceUpdated(address indexed asset, string indexed symbol);
    event FallbackOracleUpdated(address indexed fallbackOracle);
    IStdReference ref;

    string quote; 
    IPriceOracleGetter private fallbackOracle;
    mapping(address => string) private assetsSources;
    address private baseAsset;

    constructor(IStdReference _ref, string memory _quote, address _fallbackOracle, address _baseAsset) public {
        ref = _ref;
        quote = _quote;
        baseAsset = _baseAsset;
	internalSetFallbackOracle(_fallbackOracle);
    }

    function internalSetFallbackOracle(address _fallbackOracle) internal {
        fallbackOracle = IPriceOracleGetter(_fallbackOracle);
        emit FallbackOracleUpdated(_fallbackOracle);
    }

    function setAssetSource(address _asset, string calldata _symbol) external onlyOwner {
        internalSetAssetsSource(_asset, _symbol);
    }

    function unsetAssetSource(address _asset) external onlyOwner {
        internalUnSetAssetsSource(_asset);
    }

    function internalSetAssetsSource(address _asset, string calldata _symbol) internal {
        assetsSources[_asset] = _symbol;
        emit AssetSourceUpdated(_asset, _symbol);
    }

    function internalUnSetAssetsSource(address _asset) internal {
        delete(assetsSources[_asset]);
        emit AssetSourceDeleted(_asset);
    }

    function getBasePrice() external view returns (uint256){
        IStdReference.ReferenceData memory data = ref.getReferenceData(quote ,"USDT");
        return data.rate;
    }

    function getAssetPrice(address _asset) override external view returns (uint256){
        if (_asset == baseAsset) {
            return 1 ether;
        }
        string memory regSymbol = assetsSources[_asset];
        if (bytes(regSymbol).length == 0) {
            return IPriceOracleGetter(fallbackOracle).getAssetPrice(_asset);
        }
        IStdReference.ReferenceData memory data = ref.getReferenceData(regSymbol, quote);
        return data.rate;
    }
}
