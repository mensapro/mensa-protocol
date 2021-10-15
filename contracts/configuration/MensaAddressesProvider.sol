pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../libraries/openzeppelin-upgradeability/InitializableAdminUpgradeabilityProxy.sol";

import "./AddressStorage.sol";
import "../interfaces/IMensaAddressesProvider.sol";

/**
* @title MensaAddressesProvider contract
* @notice Is the main registry of the protocol. All the different components of the protocol are accessible
* through the addresses provider.
* @author Mensa
**/

contract MensaAddressesProvider is Ownable, IMensaAddressesProvider, AddressStorage {
    //events
    event MensaUpdated(address indexed newAddress);
    event MensaCoreUpdated(address indexed newAddress);
    event MensaParametersProviderUpdated(address indexed newAddress);
    event MensaManagerUpdated(address indexed newAddress);
    event MensaConfiguratorUpdated(address indexed newAddress);
    event MensaLiquidationManagerUpdated(address indexed newAddress);
    event MensaDataProviderUpdated(address indexed newAddress);
    event EthereumAddressUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event InterestRateOracleUpdated(address indexed newAddress);
    event FeeProviderUpdated(address indexed newAddress);
    event TokenDistributorUpdated(address indexed newAddress);
    event MensaMinterUpdated(address indexed newAddress);

    event ProxyCreated(bytes32 id, address indexed newAddress);

    bytes32 private constant XENSA = "XENSA";
    bytes32 private constant XENSA_CORE = "XENSA_CORE";
    bytes32 private constant XENSA_CONFIGURATOR = "XENSA_CONFIGURATOR";
    bytes32 private constant XENSA_PARAMETERS_PROVIDER = "PARAMETERS_PROVIDER";
    bytes32 private constant XENSA_MANAGER = "XENSA_MANAGER";
    bytes32 private constant XENSA_LIQUIDATION_MANAGER = "LIQUIDATION_MANAGER";
    bytes32 private constant DATA_PROVIDER = "DATA_PROVIDER";
    bytes32 private constant ETHEREUM_ADDRESS = "ETHEREUM_ADDRESS";
    bytes32 private constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 private constant INTEREST_RATE_ORACLE = "INTEREST_RATE_ORACLE";
    bytes32 private constant FEE_PROVIDER = "FEE_PROVIDER";
    bytes32 private constant WALLET_BALANCE_PROVIDER = "WALLET_BALANCE_PROVIDER";
    bytes32 private constant TOKEN_DISTRIBUTOR = "TOKEN_DISTRIBUTOR";
    bytes32 private constant XENSA_MINTER = "XENSA_MINTER ";


    /**
    * @dev returns the address of the Mensa proxy
    * @return the mensa proxy address
    **/
    function getMensa() public view returns (address) {
        return getAddress(XENSA);
    }


    /**
    * @dev updates the implementation of the mensa
    * @param _mensa the new mensa implementation
    **/
    function setMensaImpl(address _mensa) public onlyOwner {
        updateImplInternal(XENSA, _mensa);
        emit MensaUpdated(_mensa);
    }

    /**
    * @dev returns the address of the MensaCore proxy
    * @return the mensa core proxy address
     */
    function getMensaCore() public view returns (address payable) {
        address payable core = address(uint160(getAddress(XENSA_CORE)));
        return core;
    }

    /**
    * @dev updates the implementation of the mensa core
    * @param _mensaCore the new mensa core implementation
    **/
    function setMensaCoreImpl(address _mensaCore) public onlyOwner {
        updateImplInternal(XENSA_CORE, _mensaCore);
        emit MensaCoreUpdated(_mensaCore);
    }

    /**
    * @dev returns the address of the MensaConfigurator proxy
    * @return the mensa configurator proxy address
    **/
    function getMensaConfigurator() public view returns (address) {
        return getAddress(XENSA_CONFIGURATOR);
    }

    /**
    * @dev updates the implementation of the mensa configurator
    * @param _configurator the new mensa configurator implementation
    **/
    function setMensaConfiguratorImpl(address _configurator) public onlyOwner {
        updateImplInternal(XENSA_CONFIGURATOR, _configurator);
        emit MensaConfiguratorUpdated(_configurator);
    }

    /**
    * @dev returns the address of the MensaDataProvider proxy
    * @return the mensa data provider proxy address
     */
    function getMensaDataProvider() public view returns (address) {
        return getAddress(DATA_PROVIDER);
    }

    /**
    * @dev updates the implementation of the mensa data provider
    * @param _provider the new mensa data provider implementation
    **/
    function setMensaDataProviderImpl(address _provider) public onlyOwner {
        updateImplInternal(DATA_PROVIDER, _provider);
        emit MensaDataProviderUpdated(_provider);
    }

    /**
    * @dev returns the address of the MensaParametersProvider proxy
    * @return the address of the mensa parameters provider proxy
    **/
    function getMensaParametersProvider() public view returns (address) {
        return getAddress(XENSA_PARAMETERS_PROVIDER);
    }

    /**
    * @dev updates the implementation of the mensa parameters provider
    * @param _parametersProvider the new mensa parameters provider implementation
    **/
    function setMensaParametersProviderImpl(address _parametersProvider) public onlyOwner {
        updateImplInternal(XENSA_PARAMETERS_PROVIDER, _parametersProvider);
        emit MensaParametersProviderUpdated(_parametersProvider);
    }

    /**
    * @dev returns the address of the FeeProvider proxy
    * @return the address of the Fee provider proxy
    **/
    function getFeeProvider() public view returns (address) {
        return getAddress(FEE_PROVIDER);
    }

    /**
    * @dev updates the implementation of the FeeProvider proxy
    * @param _feeProvider the new mensa fee provider implementation
    **/
    function setFeeProviderImpl(address _feeProvider) public onlyOwner {
        updateImplInternal(FEE_PROVIDER, _feeProvider);
        emit FeeProviderUpdated(_feeProvider);
    }

    /**
    * @dev returns the address of the MensaLiquidationManager. Since the manager is used
    * through delegateCall within the Mensa contract, the proxy contract pattern does not work properly hence
    * the addresses are changed directly.
    * @return the address of the mensa liquidation manager
    **/

    function getMensaLiquidationManager() public view returns (address) {
        return getAddress(XENSA_LIQUIDATION_MANAGER);
    }

    /**
    * @dev updates the address of the mensa liquidation manager
    * @param _manager the new mensa liquidation manager address
    **/
    function setMensaLiquidationManager(address _manager) public onlyOwner {
        _setAddress(XENSA_LIQUIDATION_MANAGER, _manager);
        emit MensaLiquidationManagerUpdated(_manager);
    }

    /**
    * @dev the functions below are storing specific addresses that are outside the context of the protocol
    * hence the upgradable proxy pattern is not used
    **/


    function getMensaManager() public view returns (address) {
        return getAddress(XENSA_MANAGER);
    }

    function setMensaManager(address _mensaManager) public onlyOwner {
        _setAddress(XENSA_MANAGER, _mensaManager);
        emit MensaManagerUpdated(_mensaManager);
    }

    function getPriceOracle() public view returns (address) {
        return getAddress(PRICE_ORACLE);
    }

    function setPriceOracle(address _priceOracle) public onlyOwner {
        _setAddress(PRICE_ORACLE, _priceOracle);
        emit PriceOracleUpdated(_priceOracle);
    }

    function getInterestRateOracle() public view returns (address) {
        return getAddress(INTEREST_RATE_ORACLE);
    }

    function setInterestRateOracle(address _interestRateOracle) public onlyOwner {
        _setAddress(INTEREST_RATE_ORACLE, _interestRateOracle);
        emit InterestRateOracleUpdated(_interestRateOracle);
    }

    function getTokenDistributor() public view returns (address) {
        return getAddress(TOKEN_DISTRIBUTOR);
    }

    function setTokenDistributor(address _tokenDistributor) public onlyOwner {
        _setAddress(TOKEN_DISTRIBUTOR, _tokenDistributor);
        emit TokenDistributorUpdated(_tokenDistributor);
    }

    function getMensaMinter() public view returns (address) {
        return getAddress(XENSA_MINTER);
    }

    function setMensaMinter(address _mensaMinter) public onlyOwner {
        _setAddress(XENSA_MINTER, _mensaMinter);
        emit MensaMinterUpdated(_mensaMinter);
    }

    /**
    * @dev internal function to update the implementation of a specific component of the protocol
    * @param _id the id of the contract to be updated
    * @param _newAddress the address of the new implementation
    **/
    function updateImplInternal(bytes32 _id, address _newAddress) internal {
        address payable proxyAddress = address(uint160(getAddress(_id)));

        InitializableAdminUpgradeabilityProxy proxy = InitializableAdminUpgradeabilityProxy(proxyAddress);
        bytes memory params = abi.encodeWithSignature("initialize(address)", address(this));

        if (proxyAddress == address(0)) {
            proxy = new InitializableAdminUpgradeabilityProxy();
            proxy.initialize(_newAddress, address(this), params);
            _setAddress(_id, address(proxy));
            emit ProxyCreated(_id, address(proxy));
        } else {
            proxy.upgradeToAndCall(_newAddress, params);
        }

    }
}
