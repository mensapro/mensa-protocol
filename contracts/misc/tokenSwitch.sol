pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

contract tokenSwitch is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    bool private locked;

    modifier noReentrancy() {
        require(
            !locked,
            "Reentrant call."
        );
        locked = true;
        _;
        locked = false;
    }

    modifier inServiceTime() {
        require(
            block.number<finishedBlocks,
            "Too late to switch."
        );
        _;
    }

    uint256 finishedBlocks; 
    uint256 rate;
    ERC20 token1;
    ERC20 token2;
    constructor(address _src, address _dst, uint256 _blocks, uint256 _rate) public {
        token1 = ERC20(_src);
        token2 = ERC20(_dst);
        finishedBlocks = block.number.add(_blocks);
        rate = _rate;
    }

    function goSwitch(uint256 amount) public noReentrancy inServiceTime {
        require(amount>0, "zero amount.");
        uint256 switchAmount = amount.mul(rate).div(1e18);
        require(token2.balanceOf(address(this))>switchAmount, "no enough token to switch.");
        token1.safeTransferFrom(msg.sender, address(0xdead), amount);
        token2.safeTransfer(msg.sender, switchAmount);
    }

    function setRate(uint256 _rate) public noReentrancy onlyOwner {
        rate = _rate;
    }

    function cleanup() public noReentrancy onlyOwner {
        token2.safeTransfer(msg.sender, token2.balanceOf(address(this)));
    }
}
