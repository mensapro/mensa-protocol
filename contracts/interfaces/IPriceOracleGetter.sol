pragma solidity ^0.5.0;

/************
@title IPriceOracleGetter interface
@notice Interface for the mensa price oracle.*/
interface IPriceOracleGetter {
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address _asset) external view returns (uint256);
}
