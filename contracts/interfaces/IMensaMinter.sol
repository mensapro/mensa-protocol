pragma solidity ^0.5.0;
interface IMensaMinter {
    function mintMensaToken(uint256 _gid, address _user, uint256 _amount) external; 
    function withdrawMensaToken(uint256 _gid, address _user, uint256 amount) external; 
}
