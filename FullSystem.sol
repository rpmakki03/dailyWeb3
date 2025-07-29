// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/*
   ==========================
   COMBINED SMART CONTRACT
   Includes:
   ✅ ERC20 Token
   ✅ ERC721 NFT
   ✅ Staking System
   ✅ DAO Governance
   ✅ Treasury Management
   ==========================
*/

// ----------------------------
//  UTILITY CONTRACTS
// ----------------------------

// A simple Ownable contract to restrict functions to the owner
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// A simple ReentrancyGuard to prevent reentrancy attacks
contract ReentrancyGuard {
    bool private _locked;

    modifier nonReentrant() {
        require(!_locked, "Reentrancy not allowed");
        _locked = true;
        _;
        _locked = false;
    }
}

// ----------------------------
//  ERC20 TOKEN IMPLEMENTATION
// ----------------------------
contract MyToken is Ownable {
    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Invalid address");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    // Mint function only owner can call
    function mint(address to, uint256 amount) public onlyOwner {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    // Burn tokens
    function burn(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Not enough tokens");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
// ----------------------------
//  ERC721 NFT IMPLEMENTATION
// ----------------------------
contract MyNFT is Ownable {
    string public name = "MyNFT";
    string public symbol = "MNFT";
    uint256 public totalSupply;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => string) public tokenURI;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function mint(address to, string memory uri) public onlyOwner returns (uint256) {
        totalSupply += 1;
        uint256 newTokenId = totalSupply;

        ownerOf[newTokenId] = to;
        balanceOf[to] += 1;
        tokenURI[newTokenId] = uri;

        emit Transfer(address(0), to, newTokenId);
        return newTokenId;
    }

    function transfer(address to, uint256 tokenId) public {
        require(ownerOf[tokenId] == msg.sender, "Not token owner");
        require(to != address(0), "Invalid address");

        balanceOf[msg.sender] -= 1;
        balanceOf[to] += 1;
        ownerOf[tokenId] = to;

        emit Transfer(msg.sender, to, tokenId);
    }
}

// ----------------------------
//  STAKING CONTRACT
// ----------------------------
contract Staking is Ownable, ReentrancyGuard {
    MyToken public token;

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 rewardDebt;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public rewardRatePerSecond = 1e16; // 0.01 token per second

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);

    constructor(address _token) {
        token = MyToken(_token);
    }

    function stake(uint256 amount) public nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(token.balanceOf(msg.sender) >= amount, "Not enough tokens");

        token.transferFrom(msg.sender, address(this), amount);

        if (stakes[msg.sender].amount > 0) {
            uint256 pendingReward = calculateReward(msg.sender);
            stakes[msg.sender].rewardDebt += pendingReward;
        }

        stakes[msg.sender].amount += amount;
        stakes[msg.sender].startTime = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) public nonReentrant {
        require(stakes[msg.sender].amount >= amount, "Not enough staked");

        uint256 reward = calculateReward(msg.sender) + stakes[msg.sender].rewardDebt;

        stakes[msg.sender].amount -= amount;
        stakes[msg.sender].rewardDebt = 0;
        stakes[msg.sender].startTime = block.timestamp;

        token.transfer(msg.sender, amount);
        token.mint(msg.sender, reward);

        emit Unstaked(msg.sender, amount, reward);
    }

    function calculateReward(address user) public view returns (uint256) {
        StakeInfo memory stakeData = stakes[user];
        if (stakeData.amount == 0) return 0;

        uint256 duration = block.timestamp - stakeData.startTime;
        return (duration * rewardRatePerSecond * stakeData.amount) / 1e18;
    }
}
// ----------------------------
//  DAO GOVERNANCE CONTRACT
// ----------------------------
contract DAO is Ownable {
    MyToken public token;

    struct Proposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public proposalCount;
    uint256 public votingDuration = 3 days;

    event ProposalCreated(uint256 id, string description);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, bool success);

    constructor(address _token) {
        token = MyToken(_token);
    }

    function createProposal(string memory description) public {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + votingDuration,
            executed: false
        });

        emit ProposalCreated(proposalCount, description);
    }

    function vote(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp < proposal.deadline, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(token.balanceOf(msg.sender) > 0, "Must hold tokens to vote");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.votesFor += token.balanceOf(msg.sender);
        } else {
            proposal.votesAgainst += token.balanceOf(msg.sender);
        }

        emit Voted(proposalId, msg.sender, support);
    }

    function executeProposal(uint256 proposalId) public onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting not ended");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;
        bool success = proposal.votesFor > proposal.votesAgainst;

        emit ProposalExecuted(proposalId, success);
    }
}

// ----------------------------
//  TREASURY CONTRACT
// ----------------------------
contract Treasury is Ownable, ReentrancyGuard {
    MyToken public token;
    DAO public dao;

    event FundsReceived(address indexed from, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);

    constructor(address _token, address _dao) {
        token = MyToken(_token);
        dao = DAO(_dao);
    }

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    function withdrawETH(address payable to, uint256 amount) public onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient ETH");
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
        emit FundsWithdrawn(to, amount);
    }

    function withdrawTokens(address to, uint256 amount) public onlyOwner nonReentrant {
        require(token.balanceOf(address(this)) >= amount, "Insufficient tokens");
        token.transfer(to, amount);
    }
}
// ----------------------------
//  MAIN CONTRACT
// ----------------------------
contract MainContract is Ownable {
    MyToken public token;
    MyNFT public nft;
    Staking public staking;
    DAO public dao;
    Treasury public treasury;

    event SystemDeployed(address token, address nft, address staking, address dao, address treasury);

    constructor() {
        // ✅ Deploy ERC20 token with initial supply of 1,000,000 tokens
        token = new MyToken(1_000_000);

        // ✅ Deploy NFT contract
        nft = new MyNFT();

        // ✅ Deploy Staking contract (passing token address)
        staking = new Staking(address(token));

        // ✅ Deploy DAO (passing token address)
        dao = new DAO(address(token));

        // ✅ Deploy Treasury (passing token + dao address)
        treasury = new Treasury(address(token), address(dao));

        emit SystemDeployed(address(token), address(nft), address(staking), address(dao), address(treasury));
    }

    // Mint NFT directly from main contract
    function mintNFT(address to, string memory uri) public onlyOwner {
        nft.mint(to, uri);
    }

    // Transfer tokens from main contract
    function sendTokens(address to, uint256 amount) public onlyOwner {
        token.transfer(to, amount);
    }

    // Deposit ETH to Treasury
    function fundTreasury() public payable onlyOwner {
        (bool success, ) = payable(address(treasury)).call{value: msg.value}("");
        require(success, "ETH transfer failed");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/*
   ==========================
   COMBINED SMART CONTRACT
   Includes:
   ✅ ERC20 Token
   ✅ ERC721 NFT
   ✅ Staking System
   ✅ DAO Governance
   ✅ Treasury Management
   ==========================
*/

// ----------------------------
//  UTILITY CONTRACTS
// ----------------------------

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ReentrancyGuard {
    bool private _locked;

    modifier nonReentrant() {
        require(!_locked, "Reentrancy not allowed");
        _locked = true;
        _;
        _locked = false;
    }
}

// ----------------------------
//  ERC20 TOKEN IMPLEMENTATION
// ----------------------------
contract MyToken is Ownable {
    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Invalid address");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Not enough tokens");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}

// ----------------------------
//  ERC721 NFT IMPLEMENTATION
// ----------------------------
contract MyNFT is Ownable {
    string public name = "MyNFT";
    string public symbol = "MNFT";
    uint256 public totalSupply;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => string) public tokenURI;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function mint(address to, string memory uri) public onlyOwner returns (uint256) {
        totalSupply += 1;
        uint256 newTokenId = totalSupply;

        ownerOf[newTokenId] = to;
        balanceOf[to] += 1;
        tokenURI[newTokenId] = uri;

        emit Transfer(address(0), to, newTokenId);
        return newTokenId;
    }

    function transfer(address to, uint256 tokenId) public {
        require(ownerOf[tokenId] == msg.sender, "Not token owner");
        require(to != address(0), "Invalid address");

        balanceOf[msg.sender] -= 1;
        balanceOf[to] += 1;
        ownerOf[tokenId] = to;

        emit Transfer(msg.sender, to, tokenId);
    }
}

// ----------------------------
//  STAKING CONTRACT
// ----------------------------
contract Staking is Ownable, ReentrancyGuard {
    MyToken public token;

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 rewardDebt;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public rewardRatePerSecond = 1e16; // 0.01 token per second

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);

    constructor(address _token) {
        token = MyToken(_token);
    }

    function stake(uint256 amount) public nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(token.balanceOf(msg.sender) >= amount, "Not enough tokens");

        token.transferFrom(msg.sender, address(this), amount);

        if (stakes[msg.sender].amount > 0) {
            uint256 pendingReward = calculateReward(msg.sender);
            stakes[msg.sender].rewardDebt += pendingReward;
        }

        stakes[msg.sender].amount += amount;
        stakes[msg.sender].startTime = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) public nonReentrant {
        require(stakes[msg.sender].amount >= amount, "Not enough staked");

        uint256 reward = calculateReward(msg.sender) + stakes[msg.sender].rewardDebt;

        stakes[msg.sender].amount -= amount;
        stakes[msg.sender].rewardDebt = 0;
        stakes[msg.sender].startTime = block.timestamp;

        token.transfer(msg.sender, amount);
        token.mint(msg.sender, reward);

        emit Unstaked(msg.sender, amount, reward);
    }

    function calculateReward(address user) public view returns (uint256) {
        StakeInfo memory stakeData = stakes[user];
        if (stakeData.amount == 0) return 0;

        uint256 duration = block.timestamp - stakeData.startTime;
        return (duration * rewardRatePerSecond * stakeData.amount) / 1e18;
    }
}

// ----------------------------
//  DAO GOVERNANCE CONTRACT
// ----------------------------
contract DAO is Ownable {
    MyToken public token;

    struct Proposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public proposalCount;
    uint256 public votingDuration = 3 days;

    event ProposalCreated(uint256 id, string description);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, bool success);

    constructor(address _token) {
        token = MyToken(_token);
    }

    function createProposal(string memory description) public {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + votingDuration,
            executed: false
        });

        emit ProposalCreated(proposalCount, description);
    }

    function vote(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp < proposal.deadline, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(token.balanceOf(msg.sender) > 0, "Must hold tokens to vote");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.votesFor += token.balanceOf(msg.sender);
        } else {
            proposal.votesAgainst += token.balanceOf(msg.sender);
        }

        emit Voted(proposalId, msg.sender, support);
    }

    function executeProposal(uint256 proposalId) public onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting not ended");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;
        bool success = proposal.votesFor > proposal.votesAgainst;

        emit ProposalExecuted(proposalId, success);
    }
}

// ----------------------------
//  TREASURY CONTRACT
// ----------------------------
contract Treasury is Ownable, ReentrancyGuard {
    MyToken public token;
    DAO public dao;

    event FundsReceived(address indexed from, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);

    constructor(address _token, address _dao) {
        token = MyToken(_token);
        dao = DAO(_dao);
    }

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    function withdrawETH(address payable to, uint256 amount) public onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient ETH");
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
        emit FundsWithdrawn(to, amount);
    }

    function withdrawTokens(address to, uint256 amount) public onlyOwner nonReentrant {
        require(token.balanceOf(address(this)) >= amount, "Insufficient tokens");
        token.transfer(to, amount);
    }
}

// ----------------------------
//  MAIN CONTRACT
// ----------------------------
contract MainContract is Ownable {
    MyToken public token;
    MyNFT public nft;
    Staking public staking;
    DAO public dao;
    Treasury public treasury;

    event SystemDeployed(address token, address nft, address staking, address dao, address treasury);

    constructor() {
        token = new MyToken(1_000_000);
        nft = new MyNFT();
        staking = new Staking(address(token));
        dao = new DAO(address(token));
        treasury = new Treasury(address(token), address(dao));

        emit SystemDeployed(address(token), address(nft), address(staking), address(dao), address(treasury));
    }

    function mintNFT(address to, string memory uri) public onlyOwner {
        nft.mint(to, uri);
    }

    function sendTokens(address to, uint256 amount) public onlyOwner {
        token.transfer(to, amount);
    }

    function fundTreasury() public payable onlyOwner {
        (bool success, ) = payable(address(treasury)).call{value: msg.value}("");
        require(success, "ETH transfer failed");
    }
}
