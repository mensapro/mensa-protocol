pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

import "../configuration/MensaAddressesProvider.sol";
import "../mensa/MensaCore.sol";
import "../libraries/EthAddressLib.sol";


/**
* @title WalletBalanceProvider contract
* @notice Implements a logic of getting multiple tokens balance for one user address
**/
contract WalletBalanceProvider {

    using Address for address;

    MensaAddressesProvider provider;

    constructor(MensaAddressesProvider _provider) public {

        provider = _provider;

    }
    /**
    @dev Fallback function, don't accept any ETH
    **/
    function() external payable {
        revert("WalletBalanceProvider does not accept payments");
    }

    /**
    @dev Check the token balance of a wallet in a token contract

    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address
    **/
    function balanceOf(address _user, address _token) public view returns (uint256) {
        // check if token is actually a contract
        if (_token.isContract()) {
            return IERC20(_token).balanceOf(_user);
        } else {
            return 0;
        }
    }


    /**
    @dev provides balances of user wallet for all reserves available on the pool
    */
    function getUserWalletBalances(address _user) public view returns (address[] memory, uint256[] memory) {

        MensaCore core = MensaCore(provider.getMensaCore());

        address[] memory reserves = core.getReserves();

        uint256[] memory balances = new uint256[](reserves.length);

        for (uint256 j = 0; j < reserves.length; j++) {
            if(!core.getReserveIsActive(reserves[j])){
                balances[j] = 0;
                continue;
            }
            if (reserves[j] != EthAddressLib.ethAddress()) {
                balances[j] = balanceOf(_user, reserves[j]);
            } else {
                balances[j] = _user.balance; // ETH balance
            }
        }

        return (reserves, balances);
    }
}
