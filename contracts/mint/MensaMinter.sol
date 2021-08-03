pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../interfaces/IMensaAddressesProvider.sol";
import "../interfaces/IMensaMinter.sol";
import "./MensaToken.sol";

//total		150000000

//开发者生态      7500000
//市场运营	  7500000
//团队激励	  9000000
//私募		  6000000
//流动性	 60000000

//创世		  6000000
//二阶段	 54000000
contract MensaMiner is MensaToken, IMensaMinter, Ownable {
    using SafeMath for uint256;
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

    event MintDeposit(address indexed user, uint256 indexed pid, uint256 gid, uint256 amount, uint256 total);
    event MintWithdraw(address indexed user, uint256 indexed pid, uint256 gid, uint256 amount, uint256 total, uint256 received);

    uint256 private _alloced = 0;
    
    uint liquidityPool = 3;
    uint constPoolCount = 4;

    uint256 depositWithdraw = 1;
    uint256 borrowRepay = 2;

    //uint256 protectDuration = 10; //seconds
    //uint256 timesPerBlock = 1; //second(s) 
    //uint256 protectDurationBlocks = protectDuration.div(timesPerBlock) ; 
    //3 months
    uint256 protectDurationBlocks = 7070000 ; 

    PoolInfo[] private poolInfo;    
    mapping(uint256 => uint256[]) idxGroups;
    IMensaAddressesProvider ap;
    address private lp;

    mapping(uint256 => bool) constPoolIsInit;
    constructor(address addressAp) public MensaToken("MensaToken", "MENSA") {
	ap = IMensaAddressesProvider(addressAp); 
    }
    function setLp(address addressLP) public noReentrancy onlyOwner {
        lp = addressLP;
    }

    function mint(address _to, uint256 _amount) internal {
        MensaTokenMint(_to, _amount);
    }

    modifier onlyMensa {
        require(ap.getMensa() == msg.sender, "MensaToken: the caller must be mensa contract");
	_;
    }

    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 lastWithdrawBlock;  // Last block number that withdraw occurs.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 protectAmount;
        uint256 mintPending;
        uint256 protectMintPending;
        uint256 PDA;
    }

    struct Group {
        uint256 allocPoint;       // How many allocation points assigned to this pool. 
        uint256 totalAmount;  
        uint256 accPerShare;
        mapping (address => UserInfo) users;
    }

    struct PoolInfo {
        uint256 poolCap;
        uint256 totalAllocPoint;
        uint256 startBlock;
        uint256 endBlock;
        uint256 bonusPerBlock;
        uint256 lockedTotal;
        bool ageout;
        mapping (uint256 =>Group) groups;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function createPool(uint256 _pid, uint256 _poolCap, uint256 _startBlock, uint256 _endBlock) public noReentrancy onlyOwner {
        require(_pid == poolLength(), "createPool: _pid fault");
        require(block.number < _endBlock && _endBlock > _startBlock , "createPool: Invailed block parameters");
        _poolCap = _poolCap.mul(1e18);
        require(_poolCap > 0, "createPool: cap fault");

	_alloced = _alloced.add(_poolCap);
        uint256 startBlock = block.number > _startBlock ? block.number : _startBlock;
        
        require(_endBlock > startBlock , "createPool: Invailed block parameters 2");
	uint256 _bonusPerBlock = _poolCap.div(_endBlock.sub(startBlock));

        poolInfo.push(PoolInfo({
            poolCap: _poolCap,
            totalAllocPoint: 0,
            startBlock: startBlock,
            endBlock: _endBlock,
            bonusPerBlock: _bonusPerBlock,
	    lockedTotal: 0,
            ageout: false
        }));
    }

    function setGroup(uint256 _pid, uint256 _gid, uint256 _allocPoint) public noReentrancy onlyOwner {
        require(_pid < poolLength(), "setGroup: _pid fault");
        require(constPoolIsInit[_pid] == false, "init failed");
        if (poolInfo[_pid].groups[_gid].allocPoint == 0){
            idxGroups[_pid].push(_gid);
        }
        poolInfo[_pid].totalAllocPoint = poolInfo[_pid].totalAllocPoint.sub(poolInfo[_pid].groups[_gid].allocPoint).add(_allocPoint);
        poolInfo[_pid].groups[_gid] = Group({
            allocPoint: _allocPoint,
            totalAmount: 0,
            accPerShare: 0
        });
	massUpdateGroups(_pid);
    }
   
    function getMultiplier(uint256 _from, uint256 _to, uint256 _start, uint256 _end) internal pure returns (uint256) {
        require(_from <= _to, "Block counting: ");
        require(_start <= _end, "Block counting: ");
        if (_to > _end) {
            _to = _end;
        } 
        if (_from < _start) {
            _from = _start;
        }

        if (_from >= _to) {
            return 0;
        }

        return _to.sub(_from);
    }
 
    function massUpdateGroups(uint256 _pid) internal {
        uint256 length = idxGroups[_pid].length;
        for (uint256 i = 0; i < length; ++i) {
            updateGroup(_pid, idxGroups[_pid][i]);
        }
    }
    
    function calculateMGR(uint256 point, uint256 base) internal pure returns (uint256 mgr) {
        mgr = 1e18;
        mgr = mgr.mul(point).div(base);
        
        uint256 z = mgr.add(1).div(2);
        uint256 y = mgr;
        while(z < y){
          y = z;
          z = mgr.div(z).add(z).div(2);
        }
        mgr = y.mul(75e7);
    }

    function updateUserProtectDuration(address userAddr, UserInfo storage u, uint256 amount, uint256 pending, uint256 poolPrice, bool unlockedOnly) internal returns(uint256 unlocked, uint256 flushCount) {
        if (block.number > u.PDA) {
            u.protectAmount = 0;
            u.protectMintPending = 0;
        }
        {
            uint256 pa = u.protectAmount.add(amount);
            if (pa > 0) {
                u.PDA = u.protectAmount.mul(u.PDA).add(amount.mul(block.number.add(protectDurationBlocks))).div(pa);
            }
        }
        u.lastWithdrawBlock = block.number;
        u.mintPending = u.mintPending.add(pending);
        if (u.protectAmount != 0) {
            u.protectMintPending = u.protectMintPending.add(pending.mul(u.protectAmount).div(u.amount));
        }
        u.amount = u.amount.add(amount);
        u.protectAmount = u.protectAmount.add(amount); 		
        if (amount == 0){ //withdraw 
            if (unlockedOnly) { 
                flushCount = u.mintPending.sub(u.protectMintPending).add(poolPrice);
                u.mintPending = u.protectMintPending;
            }else{
                unlocked = u.protectMintPending.div(2); 
                flushCount = u.mintPending.sub(unlocked).add(poolPrice); 
                u.mintPending = 0;
                u.protectMintPending = 0;
            }
            if (flushCount > 0) {
                mint(address(this), flushCount);
                this.transfer(userAddr, flushCount);
            }
        }
    }

    function updateGroup(uint256 _pid, uint256 _gid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        Group storage group = pool.groups[_gid];
        uint256 mgr = calculateMGR(group.totalAmount, pool.poolCap);
        group.accPerShare = pool.bonusPerBlock.mul(group.allocPoint).div(pool.totalAllocPoint).mul(mgr).div(1e18);
    }

    function getPoolInfo (uint256 _pid) public view returns (uint256 poolCap,
        uint256 totalAllocPoint,
        uint256 startBlock,
        uint256 endBlock,
        uint256 bonusPerBlock,
        uint256 lockedTotal) {
        PoolInfo storage pool = poolInfo[_pid];
        poolCap = pool.poolCap;
        totalAllocPoint = pool.totalAllocPoint;
        startBlock = pool.startBlock;
        endBlock = pool.endBlock;
        bonusPerBlock = pool.bonusPerBlock;
        lockedTotal = pool.lockedTotal;
    }
    function getGroupInfo(uint256 _pid, uint256 _gid) public view returns (uint256 gp, uint256 groupTotal, uint256 accPerShare){
        PoolInfo storage pool = poolInfo[_pid];
        Group storage group = pool.groups[_gid];
        gp = group.allocPoint;
        groupTotal = group.totalAmount;
        accPerShare = group.accPerShare;
    }

    function _deposit(uint256 _pid, uint256 _gid, address u, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.ageout) {
            return;
        }
        if (pool.endBlock < block.number) {
            pool.ageout = true;
            return;
        }
        Group storage group = pool.groups[_gid];
        UserInfo storage user = group.users[u];

        uint256 multiplier = getMultiplier(user.lastWithdrawBlock, block.number, pool.startBlock, pool.endBlock);
        uint256 pending = 0;
        if (group.totalAmount > 0) {
            pending = multiplier.mul(group.accPerShare).mul(user.amount).div(group.totalAmount);
        }
        group.totalAmount = group.totalAmount.add(_amount);
        updateGroup(_pid, _gid);

        updateUserProtectDuration(u, user, _amount, pending, 0, true);
        emit MintDeposit(u, _pid, _gid, user.amount, group.totalAmount);
    }

    function _withdraw(uint256 _pid, uint256 _gid, address u, uint256 _amount, bool unlockedOnly) internal {
        uint256 unlock = 0;
        uint256 unlockAmount = 0;
        uint256 flush = 0;
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.ageout == false && pool.endBlock < block.number) {
            pool.ageout = true;
        }
        Group storage group = pool.groups[_gid];
        UserInfo storage user = group.users[u];
        if (!(group.totalAmount > 0)) {
            return;
        }
        require(user.amount >= _amount, "withdraw: not good");
        if (pool.endBlock < block.number){
            user.protectAmount = 0; 
            user.protectMintPending = 0;
        }
        unlockAmount = user.amount.sub(user.protectAmount); 
        require(!(unlockedOnly && unlockAmount<_amount) , "withdraw: unlocked balance not enough");

        uint256 multiplier = getMultiplier(user.lastWithdrawBlock, block.number, pool.startBlock, pool.endBlock);
        uint256 pending = multiplier.mul(group.accPerShare).mul(user.amount).div(group.totalAmount);
        uint256 protectPrice; 
        {
        uint256 rate = _priceRate(pool, group, user);
        protectPrice = pool.lockedTotal.mul(rate).div(1e18); 
        if (unlockAmount >= _amount) {
            unlockedOnly = true;
        }
        }
        (unlock, flush) = updateUserProtectDuration(u, user, 0, pending, protectPrice, unlockedOnly);
        pool.lockedTotal = pool.lockedTotal.add(unlock).sub(protectPrice); 
        user.amount = user.amount.sub(_amount);
        if (user.protectAmount > user.amount){
            user.protectAmount = user.amount;
        }
        user.rewardDebt = user.rewardDebt.add(pending);
        group.totalAmount = group.totalAmount.sub(_amount);
        if (!pool.ageout) {
            updateGroup(_pid, _gid);
        }

        emit MintWithdraw(msg.sender, _pid, _gid, _amount, group.totalAmount, flush);
    }

    function pendingMensa(uint256 _pid, uint256 _gid, address _user) public view returns (uint256 amount, uint256 protectAmount, uint256 rewardDebt, uint256 pending, uint256 protectMintPending, uint256 protectPrice, uint256 lockedTotal) {
        PoolInfo storage pool = poolInfo[_pid];
        Group storage group = pool.groups[_gid];
        UserInfo storage user = group.users[_user];
        if (group.totalAmount == 0) {
            return (0, 0, 0, 0, 0, 0, 0);
        }
        uint256 multiplier = getMultiplier(user.lastWithdrawBlock, block.number, pool.startBlock, pool.endBlock);
                   pending = multiplier.mul(group.accPerShare).mul(user.amount).div(group.totalAmount).add(user.mintPending);

        amount = user.amount;
        uint256 rate = _priceRate(pool, group, user);
        protectPrice = pool.lockedTotal.mul(rate).div(1e18); 
        if (block.number < user.PDA) {
            protectAmount = user.protectAmount;
            protectMintPending = multiplier.mul(group.accPerShare).mul(user.protectAmount).div(group.totalAmount).add(user.protectMintPending);
        }
        rewardDebt = user.rewardDebt;
        lockedTotal = pool.lockedTotal; 
    }

    function selectPool() internal view returns (uint256){
        for (uint i = constPoolCount; i<poolLength(); i++) {
            if (poolInfo[i].endBlock > block.number) {
                return i;
            }
        }
        return 0;
    }

    function getUserAmount(uint256 _gid, address _user) public view returns (uint256 amount, uint256 pending, uint256 protectPending, uint256 protectPriceTotal, uint256 lockedPriceTotal){
        if (poolLength() <= constPoolCount) {
            return (0, 0, 0, 0, 0);
        }
        if (_gid != depositWithdraw && _gid != borrowRepay) {
            return (0, 0, 0, 0, 0);
        }
        uint256 p;
        uint256 pm;
        uint256 pp;
        uint256 lt;
        for (uint i = liquidityPool; i<poolLength(); i++) {
            amount = amount.add(poolInfo[i].groups[_gid].users[_user].amount);
            (, , , p, pm,pp,lt) = pendingMensa(i, _gid, _user);
            pending = pending.add(p);
            protectPending = protectPending.add(pm);
            protectPriceTotal = protectPriceTotal.add(pp); 
            lockedPriceTotal = lockedPriceTotal.add(lt);
        }
    }

    function _priceRate(PoolInfo memory p, Group memory g, UserInfo memory u) internal view returns (uint256 rate) {
        if (g.totalAmount == 0) {
            return 0;
        }
        uint256 protectAmount = u.protectAmount;
        if (block.number > u.PDA) {
            protectAmount = 0;
        }
        rate = 1e18;
        rate = rate.mul(u.amount.sub(protectAmount)).mul(g.allocPoint).div(p.totalAllocPoint).div(g.totalAmount); 
    }

    function priceRate(address u) external view returns (uint256 rate) {
        PoolInfo storage pool = poolInfo[liquidityPool];
        uint256 _rate;
        Group storage group = pool.groups[depositWithdraw];
        UserInfo storage user = group.users[u];
        if (user.amount != 0) {
            _rate = _priceRate(pool, group, user);
            rate = rate.add(_rate);
        }
    }

    function mintMensaToken(address _reserve, address _user, uint256 _gid, uint256 _amount) external noReentrancy onlyMensa {
        if (_amount == 0) {
            return;
        }
        require(poolLength() >= constPoolCount, "minMensaToken: Invailed pools");
        require(_gid == depositWithdraw || _gid == borrowRepay, "minMensaToken: Invailed action");
        if (_reserve == lp) {
            _deposit(liquidityPool, _gid, _user, _amount); 
            return;
        }
        uint256 _pid = selectPool();
        if (!(_pid < constPoolCount)){
            _deposit(_pid, _gid, _user, _amount); 
        }
    }

    function withdrawMensaToken(address _user, uint256 _gid, uint256 amount, bool unlockedOnly) external noReentrancy onlyMensa {
        if (amount == 0) {
            return;
        }
        require(poolLength() > constPoolCount, "minMensaToken: Invailed pools");
        require(_gid == depositWithdraw || _gid == borrowRepay, "minMensaToken: Invailed action");
        
        uint256 _amount;
        (_amount, , , ,) = getUserAmount(_gid, _user);
        if (amount > _amount) {
            amount = _amount;
        }
        for (uint i = poolLength()-1; i >= liquidityPool; i--) {
            _amount = poolInfo[i].groups[_gid].users[_user].amount;
            if (_amount > 0){
               if (amount > _amount) {
                    _withdraw(i, _gid, _user, _amount, unlockedOnly);
                    amount = amount.sub(_amount);
               } else {
                    _withdraw(i, _gid, _user, amount, unlockedOnly);
                    amount = 0;
               }
            }
            if (amount == 0) {
                return;
            }
        }
    }

    function _withdrawPendingMensaToken(uint256 _gid, bool unlockedOnly) public {
        require(poolLength() > constPoolCount, "minMensaToken: Invailed pools");
        require(_gid == depositWithdraw || _gid == borrowRepay, "minMensaToken: Invailed action");
        for (uint i = poolLength()-1; i >=  liquidityPool; i--) {
            if (poolInfo[i].groups[_gid].users[msg.sender].lastWithdrawBlock < block.number) {
                _withdraw(i, _gid, msg.sender, 0, unlockedOnly);
            }
        }
    }

    function withdrawPendingMensaToken(bool unlockedOnly) public {
        _withdrawPendingMensaToken(1, unlockedOnly); 
        _withdrawPendingMensaToken(2, unlockedOnly); 
    }

    function setPoolInited(uint256 _pid) public noReentrancy onlyOwner {
        constPoolIsInit[_pid] = true;
    }

    function deposit(uint256 _pid, uint256 _gid, address u, uint256 _amount) external noReentrancy onlyOwner {
        require(_pid < liquidityPool, "only for const pool");
        require(constPoolIsInit[_pid] == false, "init failed");
        constPoolIsInit[_pid] = true;
        _deposit(_pid, _gid, u, _amount);
    }

    function withdraw(uint256 _pid, uint256 _gid, address u, uint256 _amount) external noReentrancy onlyOwner {
        require(_pid < liquidityPool, "only for const pool" );
        _withdraw(_pid, _gid, u, _amount, true);
    }
}

