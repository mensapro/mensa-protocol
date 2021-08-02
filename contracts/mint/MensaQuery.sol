pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

interface IMensaMinterQuery {
    function getGroupInfo(uint256 _pid, uint256 _gid) external view returns (uint256 gp, uint256 groupTotal, uint256 accPerShare);
    function pendingMensa(uint256 _pid, uint256 _gid, address _user) external returns (uint256 amount, uint256 protectAmount, uint256 rewardDebt, uint256 pending, uint256 protectMintPending, uint256 protectPrice, uint256 lockedTotal); 
}

contract MensaQuery {
    using SafeMath for uint256;
    IMensaMinterQuery private mt;
    constructor(address addressMensaMint) public{
        mt = IMensaMinterQuery(addressMensaMint); 
    }

    function earnings(uint256 pid, uint256 gid, uint256 duringBlocks, uint256 baseReservsePrice, uint256 mintReservePrice ) public view returns (uint256 rate){
        uint256 ap;
        uint256 gt;
        if (duringBlocks == 0 || baseReservsePrice == 0 || mintReservePrice == 0) {
            return 0;
        }
        ( , gt, ap) = mt.getGroupInfo(pid, gid);
        if (gt == 0) {
            return 0;
        }
        uint256 pending = duringBlocks.mul(ap);
        rate = pending.mul(mintReservePrice).mul(1e18).div(baseReservsePrice).div(gt);
        return rate;
    }

    function mintTokenPerBlock(uint256 pid, uint256 gid) public view returns (uint256 mintPerBlock){
        ( , , mintPerBlock) = mt.getGroupInfo(pid, gid);
        return mintPerBlock;
    }
    
    function mintedToken(uint256 pid, uint256 gid, uint256 poolStart, uint256 poolEnd) public view returns (uint256 minted){
        if (poolEnd <= poolStart){
            return 0;
        }

        if (block.number <= poolStart){
            return 0;
        }

        uint256 mintBlocks;
        uint256 mintPerBlock;
        if (block.number <= poolEnd){
            mintBlocks = block.number.sub(poolStart);
        }else{
            mintBlocks = poolEnd.sub(poolStart);
        }

        ( , , mintPerBlock) = mt.getGroupInfo(pid, gid);
        return mintBlocks.mul(mintPerBlock);
    }
}
