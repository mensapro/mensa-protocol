pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../libraries/openzeppelin-upgradeability/VersionedInitializable.sol";
import "../configuration/MensaAddressesProvider.sol";
import "../mensa/MensaConfigurator.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract MensaManager is Ownable, VersionedInitializable {
    using SafeMath for uint256;
    MensaAddressesProvider public addressesProvider;
    MensaConfigurator public conf;
    uint256 public constant CONFIGURATOR_REVISION = 0x3;

    function initAddressProvider(MensaAddressesProvider _addressesProvider) external onlyOwner {
        addressesProvider = _addressesProvider;
        conf = MensaConfigurator(addressesProvider.getMensaConfigurator());
    }

    function getRevision() internal pure returns (uint256) {
        return CONFIGURATOR_REVISION;
    }

    function initReserve(
        address _reserve,
        uint8 _underlyingAssetDecimals,
        address _interestRateStrategyAddress
    ) external onlyOwner {
	conf.initReserve(_reserve, _underlyingAssetDecimals, _interestRateStrategyAddress);
    }

    function initReserveWithData(
        address _reserve,
        string memory _mTokenName,
        string memory _mTokenSymbol,
        uint8 _underlyingAssetDecimals,
        address _interestRateStrategyAddress
    ) public onlyOwner {
     	conf.initReserveWithData(_reserve, _mTokenName,_mTokenSymbol,_underlyingAssetDecimals,_interestRateStrategyAddress);
    }

    function removeLastAddedReserve(address _reserveToRemove) external onlyOwner {
        conf.removeLastAddedReserve(_reserveToRemove);
    }

    function enableBorrowingOnReserve(address _reserve, bool _stableBorrowRateEnabled)
        external
        onlyOwner 
    {
        conf.enableBorrowingOnReserve(_reserve,_stableBorrowRateEnabled);
    }

    function disableBorrowingOnReserve(address _reserve) external onlyOwner {
        conf.disableBorrowingOnReserve(_reserve);
    }

    function enableReserveAsCollateral(
        address _reserve,
        uint256 _baseLTVasCollateral,
        uint256 _liquidationThreshold,
        uint256 _liquidationBonus
    ) external onlyOwner {
        conf.enableReserveAsCollateral(_reserve,_baseLTVasCollateral,_liquidationThreshold,_liquidationBonus);
    }

    function disableReserveAsCollateral(address _reserve) external onlyOwner {
        conf.disableReserveAsCollateral(_reserve);
    }

    function enableReserveStableBorrowRate(address _reserve) external onlyOwner {
        conf.enableReserveStableBorrowRate(_reserve);
    }

    function disableReserveStableBorrowRate(address _reserve) external onlyOwner {
        conf.disableReserveStableBorrowRate(_reserve);
    }

    function activateReserve(address _reserve) external onlyOwner {
        conf.activateReserve(_reserve);
    }

    function deactivateReserve(address _reserve) external onlyOwner {
        conf.deactivateReserve(_reserve);
    }

    /**
    * @dev freezes a reserve. A freezed reserve doesn't accept any new deposit, borrow or rate swap, but can accept repayments, liquidations, rate rebalances and redeems
    * @param _reserve the address of the reserve
    **/
    function freezeReserve(address _reserve) external onlyOwner {
        conf.freezeReserve(_reserve);
    }

    /**
    * @dev unfreezes a reserve
    * @param _reserve the address of the reserve
    **/
    function unfreezeReserve(address _reserve) external onlyOwner {
        conf.unfreezeReserve(_reserve);
    }

    /**
    * @dev emitted when a reserve loan to value is updated
    * @param _reserve the address of the reserve
    * @param _ltv the new value for the loan to value
    **/
    function setReserveBaseLTVasCollateral(address _reserve, uint256 _ltv)
        external
        onlyOwner 
    {
        conf.setReserveBaseLTVasCollateral(_reserve,_ltv);
    }

    /**
    * @dev updates the liquidation threshold of a reserve.
    * @param _reserve the address of the reserve
    * @param _threshold the new value for the liquidation threshold
    **/
    function setReserveLiquidationThreshold(address _reserve, uint256 _threshold)
        external
        onlyOwner 
    {
        conf.setReserveLiquidationThreshold(_reserve,_threshold);
    }

    /**
    * @dev updates the liquidation bonus of a reserve
    * @param _reserve the address of the reserve
    * @param _bonus the new value for the liquidation bonus
    **/
    function setReserveLiquidationBonus(address _reserve, uint256 _bonus)
        external
        onlyOwner 
    {
        conf.setReserveLiquidationBonus(_reserve,_bonus);
    }

    /**
    * @dev updates the reserve decimals
    * @param _reserve the address of the reserve
    * @param _decimals the new number of decimals
    **/
    function setReserveDecimals(address _reserve, uint256 _decimals)
        external
        onlyOwner 
    {
        conf.setReserveDecimals(_reserve,_decimals);
    }

    /**
    * @dev sets the interest rate strategy of a reserve
    * @param _reserve the address of the reserve
    * @param _rateStrategyAddress the new address of the interest strategy contract
    **/
    function setReserveInterestRateStrategyAddress(address _reserve, address _rateStrategyAddress)
        external
        onlyOwner 
    {
        conf.setReserveInterestRateStrategyAddress(_reserve,_rateStrategyAddress);
    }

    /**
    * @dev refreshes the mensa core configuration to update the cached address
    **/
    function refreshMensaCoreConfiguration() external onlyOwner {
        conf.refreshMensaCoreConfiguration();
    }
}



