// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract ERC721 {
    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(uint256 => address) private tokenOwners;
    mapping(uint256 => bool) private tokenExists;
    mapping(uint256 => address) private tokenApprovals;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(
            msg.sender == tokenOwners[_tokenId],
            "Not the owner of the token"
        );
        _;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "Invalid owner address");
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(tokenExists[_tokenId], "Token does not exist");
        return tokenOwners[_tokenId];
    }

    function approve(address _approved, uint256 _tokenId)
        external
        onlyOwnerOf(_tokenId)
    {
        address owner = tokenOwners[_tokenId];
        require(_approved != owner, "Already approved");
        tokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(tokenExists[_tokenId], "Token does not exist");
        return tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender, "Invalid operator");
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        require(tokenExists[_tokenId], "Token does not exist");
        require(_to != address(0), "Invalid recipient address");
        require(
            _from == msg.sender || operatorApprovals[_from][msg.sender],
            "Not authorized to transfer"
        );

        address owner = tokenOwners[_tokenId];
        require(owner == _from, "Not the owner of the token");

        balances[_from]--;
        balances[_to]++;
        tokenOwners[_tokenId] = _to;
        delete tokenApprovals[_tokenId];

        emit Transfer(_from, _to, _tokenId);
    }

    function mint(address _to, uint256 _tokenId) external {
        require(_to != address(0), "Invalid recipient address");
        require(!tokenExists[_tokenId], "Token already exists");

        balances[_to]++;
        tokenOwners[_tokenId] = _to;
        tokenExists[_tokenId] = true;
        totalSupply++;

        emit Transfer(address(0), _to, _tokenId);
    }
}
