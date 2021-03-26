pragma solidity ^0.5.0;

/**
@title IMensaAddressesProvider interface
@notice provides the interface to fetch the MensaCore address
 */

contract IMensaAddressesProvider {

    function getMensa() public view returns (address);
    function setMensaImpl(address _pool) public;

    function getMensaCore() public view returns (address payable);
    function setMensaCoreImpl(address _mensaCore) public;

    function getMensaConfigurator() public view returns (address);
    function setMensaConfiguratorImpl(address _configurator) public;

    function getMensaDataProvider() public view returns (address);
    function setMensaDataProviderImpl(address _provider) public;

    function getMensaParametersProvider() public view returns (address);
    function setMensaParametersProviderImpl(address _parametersProvider) public;

    function getTokenDistributor() public view returns (address);
    function setTokenDistributor(address _tokenDistributor) public;


    function getFeeProvider() public view returns (address);
    function setFeeProviderImpl(address _feeProvider) public;

    function getMensaLiquidationManager() public view returns (address);
    function setMensaLiquidationManager(address _manager) public;

    function getMensaManager() public view returns (address);
    function setMensaManager(address _mensaManager) public;

    function getPriceOracle() public view returns (address);
    function setPriceOracle(address _priceOracle) public;

    function getInterestRateOracle() public view returns (address);
    function setInterestRateOracle(address _interestRateOracle) public;

}
