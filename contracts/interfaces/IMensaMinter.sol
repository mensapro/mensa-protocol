pragma solidity ^0.5.0;
interface IMensaMinter {
    function mintMensaToken(address reserve, address _user,  uint256 _gid, uint256 _amount) external; 
    function withdrawMensaToken(address _user, uint256 _gid, uint256 amount, bool unlockedOnly) external; 
}
