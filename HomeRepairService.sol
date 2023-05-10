// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract HomeRepairService {
    struct Request {
        address payable user;
        string description;
        uint256 tax;
        uint256 auditsCount;
        bool exists;
    }

    address public admin;

    mapping(uint256 => Request) public requests;
    mapping(uint256 => uint256) private payments;
    mapping(uint256 => uint256) private confirmations;
    mapping(address => bool) private auditors;
    mapping(uint256 => mapping(address => bool)) private auditedRequestsBy;

    event RepairRequestAdded(uint256 indexed requestId, address indexed user);
    event RepairRequestAccepted(uint256 indexed requestId, uint256 tax);
    event PaymentAdded(uint256 indexed requestId, uint256 payment);
    event RepairRequestConfirmed(uint256 indexed requestId);
    event JobVerified(uint256 indexed requestId, address indexed auditor);
    event RepairRequestExecuted(
        uint256 indexed requestId,
        address indexed repairer
    );
    event MoneyReturned(uint256 indexed requestId);
    event AuditorAdded(address indexed auditor);
    event AuditorRemoved(address indexed auditor);

    error RequestAlreadyExists();
    error NotAdministrator();
    error RequestNotAccepted();
    error RequestAlreadyPaid();
    error NotEnoughETH();
    error AlreadyAudited();
    error NotAuditedEnough();
    error MoreTimeToVerify();
    error NotUserRequest();
    error NoBalanceToReturn();

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not administrator");
        _;
    }

    modifier onlyAuditor() {
        require(auditors[msg.sender], "Not auditor");
        _;
    }

    function addRepairRequest(string calldata description, uint256 requestId)
        external
    {
        require(!requests[requestId].exists, "Request already exists");

        requests[requestId] = Request(
            payable(msg.sender),
            description,
            0,
            0,
            true
        );

        emit RepairRequestAdded(requestId, msg.sender);
    }

    function acceptRepairRequest(uint256 requestId, uint256 tax)
        external
        onlyAdmin
    {
        require(requests[requestId].exists, "Request does not exist");

        requests[requestId].tax = tax;

        emit RepairRequestAccepted(requestId, tax);
    }

    function addPayment(uint256 requestId) external payable {
        require(requests[requestId].exists, "Request does not exist");
        require(requests[requestId].tax > 0, "Request not accepted");
        require(payments[requestId] == 0, "Request already paid");
        require(msg.value >= requests[requestId].tax, "Not enough ETH");

        payments[requestId] = msg.value;

        emit PaymentAdded(requestId, msg.value);
    }

    function confirmRepairRequest(uint256 requestId) external onlyAdmin {
        require(requests[requestId].exists, "Request does not exist");

        confirmations[requestId] = block.timestamp;

        emit RepairRequestConfirmed(requestId);
    }

    function verifyDoneJob(uint256 requestId) external onlyAuditor {
        require(requests[requestId].exists, "Request does not exist");
        require(!auditedRequestsBy[requestId][msg.sender], "Already audited");
        require(requests[requestId].tax > 0, "Request not accepted");

        auditedRequestsBy[requestId][msg.sender] = true;
        requests[requestId].auditsCount++;

        emit JobVerified(requestId, msg.sender);
    }

    function executeRepairRequest(uint256 requestId, address payable repairer)
        external
        onlyAuditor
    {
        require(requests[requestId].exists, "Request does not exist");
        require(requests[requestId].tax > 0, "Request not accepted");
        require(payments[requestId] > 0, "Request not paid");
        require(requests[requestId].auditsCount >= 2, "Not audited enough");

        repairer.transfer(payments[requestId]);

        emit RepairRequestExecuted(requestId, repairer);
    }

    function getMoneyBack(uint256 requestId) external {
        require(requests[requestId].exists, "Request does not exist");
        require(
            requests[requestId].user == msg.sender,
            "Not user who created request"
        );
        require(address(this).balance > 0, "No balance to return");
        require(
            confirmations[requestId] + 30 days >= block.timestamp,
            "More time to verify"
        );

        requests[requestId].user.transfer(payments[requestId]);

        delete requests[requestId];
        delete payments[requestId];
        delete confirmations[requestId];

        emit MoneyReturned(requestId);
    }

    function addAuditor(address auditor) external onlyAdmin {
        require(!auditors[auditor], "Auditor already added");

        auditors[auditor] = true;

        emit AuditorAdded(auditor);
    }

    function removeAuditor(address auditor) external onlyAdmin {
        require(auditors[auditor], "Auditor not found");

        auditors[auditor] = false;

        emit AuditorRemoved(auditor);
    }
}
