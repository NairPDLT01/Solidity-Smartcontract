//SPDX-License-Identifier:MIT
pragma solidity >0.5.0 <0.9.0;

/**
* @title AnimalsFund
*@dev A contract to manage fundraising for animals with multi owner approval
for withdrawals.
**/
contract AnimalsFund {

    /// @notice List of owner addresses
    address[] public owners;

    /// @notice Total amount of donation received 
    uint256 public totalDonations;

    /// @notice The fundraising goal amount
    uint256 public  fundraisingGoal;

    /// @notice Total amount of funds withdrawn
    uint256 public fundsWithdrawn;


/// @notice Repesents a donation made by a donor
    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
    }  

    /// @notice Represents a withdrawal request
    struct WithdrawalRequest{
        uint256 amount;
        address payable to;
        uint256 approvalCount;
        bool executed;
    }

/// @notice mapping to check if an adddress is an owner
    mapping(address => bool) public isOwner;

    /// @notice Mapping to track the donation amount of each donor
    mapping(address => uint256) public donorRewards;

    /// @notice List of all donations
    Donation[] public donations;

    /// @notice List of all withdrawal requests
    WithdrawalRequest[]public withdrawalRequests;
    
    /// @notice Mapping to track approvals of withdrawal requests
    mapping(uint256 => mapping(address => bool)) public approvals;

/// @notice Emitted when donation is received
/// @param donor The adress of the donor
// @param amount the amount donated
    event DonationReceived(address indexed donor, uint256 am1ount);

    /// @notice Emitted when a withdrawal requestId is created
    /// @param  requestId The ID of the withdrawal request
    /// @param to The address to which the funds will be sent
    /// @param amount The amount to be withdrawn
    event WithdrawalRequested(uint256 indexed requestId, address indexed to, uint256 amount);

    /// @notice Emitted when a withdrawal request is approved
    /// @param requestId the ID of the withdrawal request
    /// @param approver The address of the owner who approved the request
     event WithdrawalApproved(uint256 indexed requestId, address indexed approver);

     /// @notice Emitted when a withdrawal request is executed
     /// @param requestId The ID of the withdrawal request
     /// @param to the address to which the funds were sent
     /// @param amount the amount withdrawn 
     event WithdrawalExecuted(uint256 indexed requestId, address indexed to, uint256 amount);

/// @dev Ensures that only owners can call the function
     modifier onlyOwner() {
        require(isOwner[msg.sender], "Only owners can perform this action");
        _;
     }

/// @dev Ensures that the fundraising goal has not  been reached
     modifier goalNotReached() {
        require(totalDonations < fundraisingGoal, "Fundraising goal already reached");
        _;
     }

/// @notice Constructor to intialize the contract with owners and fundraising goal
/// @param _owners List of owner addresses
/// @param _fundraisingGoal The fundraising goal amount
     constructor(address[] memory _owners, uint256 _fundraisingGoal) {
        require(_owners.length > 0, "There must be atleast one owner");
        require(_fundraisingGoal > 0, "Fundraising goal must be greater than zero");

        for(uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            isOwner[owner] = true;
            owners.push(owner);
        }

        fundraisingGoal = _fundraisingGoal;
     }


/// @notice Donate funds to the contract
/// @dev Donations are only accepted if the fundraising goal is not reached
     function donate() external payable goalNotReached {
        require(msg.value > 0, "Donation must be greater than zero");

        donations.push(Donation({
            donor: msg.sender,
            amount : msg.value,
            timestamp: block.timestamp
        }));

        totalDonations += msg.value;
        donorRewards[msg.sender] += msg.value;

        emit DonationReceived(msg.sender, msg.value);
     }

     /// @notice Get the list of all donations
     /// @return List of all donations
     function getDonation() external view returns (Donation[] memory) {
        return donations;
     }

     /// @notice create a withdrawal request
     /// @param amount The amount to withdraw
     /// @param to the adddress to send the funds to
     /// @dev only owners can create withdrawal requests
     function createWithdrawalRequest(uint256 amount, address payable to) external onlyOwner{
     require(amount <= address(this).balance, "Insufficient balance in contract");

     withdrawalRequests.push(WithdrawalRequest({
        amount: amount,
        to: to,
        approvalCount: 0,
        executed: false
     }));

     emit WithdrawalRequested(withdrawalRequests.length - 1, to, amount);
}

/// @notice Approved a withdrawal request
/// @param requestId the ID of the withdrawal request to approve
/// @dev only owners can approava withdrawal requests
function approveWithdrawalRequest(uint256 requestId) external onlyOwner {
    WithdrawalRequest storage request = withdrawalRequests[requestId];

    require(!request.executed, "Request already executed");
    require(!approvals[requestId][msg.sender], "Request already approved by this owner");

    approvals[requestId][msg.sender] = true;
    request. approvalCount += 1;

    emit WithdrawalApproved(requestId, msg.sender);

    if(request.approvalCount > owners.length / 2) {
        request.executed = true;
        fundsWithdrawn += request.amount;
        request.to.transfer(request.amount);

        emit WithdrawalExecuted(requestId, request.to, request.amount);
    }
    }

    /// @notice Get the  list of all withdrawal requests
    /// @return list of all withdrawal requests
    function getWithdrawalRequests() external view returns (WithdrawalRequest[] memory) {
        return withdrawalRequests;
    }


/// @notice get the list of all owners
/// @return list of all owner addresses
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

/// @notice get the rewards of a specific donor
/// @param donor address of the donor
/// @return the total donation amount of the donor
    function getDonorRewards(address donor) external view returns (uint256) {
        return donorRewards[donor];
       
    }
}