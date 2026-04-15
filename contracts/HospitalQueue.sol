// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract HospitalQueue {
    address public owner;
    address public allowedPayer;
    address payable public hospitalWallet;
    address payable public emergencyWallet;

    uint256 public minPayment;
    uint256 public vipPayment;
    uint256 public nextQueueNumber = 1;

    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public userQueueNumbers;

    event QueuePaid(
        address indexed payer,
        uint256 amount,
        uint256 queueNumber,
        uint8 serviceType,
        address indexed mainReceiver
    );
    event MoneyRouted(address indexed receiver, uint256 amount, string reason);
    event Withdrawn(address indexed owner, uint256 amount);
    event AllowedPayerChanged(address indexed oldPayer, address indexed newPayer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    constructor(
        address _allowedPayer,
        address payable _hospitalWallet,
        address payable _emergencyWallet,
        uint256 _minPayment,
        uint256 _vipPayment
    ) {
        require(_allowedPayer != address(0), "Allowed payer cannot be zero");
        require(_hospitalWallet != address(0), "Hospital wallet cannot be zero");
        require(_emergencyWallet != address(0), "Emergency wallet cannot be zero");
        require(_minPayment > 0, "Minimum payment must be greater than zero");
        require(_vipPayment >= _minPayment, "VIP payment must be at least minimum");

        owner = msg.sender;
        allowedPayer = _allowedPayer;
        hospitalWallet = _hospitalWallet;
        emergencyWallet = _emergencyWallet;
        minPayment = _minPayment;
        vipPayment = _vipPayment;
    }

    receive() external payable {
        revert("Use takeQueue function to pay");
    }

    function takeQueue(uint8 serviceType) external payable returns (uint256) {
        require(msg.sender == allowedPayer, "Payment accepted only from allowed payer");
        require(msg.value >= minPayment, "Payment is less than minimum amount");
        require(serviceType <= 2, "Invalid service type");

        uint256 queueNumber = nextQueueNumber;
        nextQueueNumber++;

        userBalances[msg.sender] += msg.value;
        userQueueNumbers[msg.sender] = queueNumber;

        address mainReceiver;

        if (serviceType == 1) {
            mainReceiver = emergencyWallet;
            _sendMoney(emergencyWallet, msg.value, "Emergency queue payment");
        } else if (msg.value >= vipPayment) {
            mainReceiver = hospitalWallet;
            uint256 hospitalShare = (msg.value * 70) / 100;
            uint256 emergencyShare = (msg.value * 20) / 100;

            _sendMoney(hospitalWallet, hospitalShare, "VIP hospital share");
            _sendMoney(emergencyWallet, emergencyShare, "VIP emergency reserve");
            // The remaining 10% stays in the contract and can be withdrawn only by owner.
        } else {
            mainReceiver = hospitalWallet;
            uint256 hospitalShare = (msg.value * 90) / 100;

            _sendMoney(hospitalWallet, hospitalShare, "Regular hospital share");
            // The remaining 10% stays in the contract and can be withdrawn only by owner.
        }

        emit QueuePaid(msg.sender, msg.value, queueNumber, serviceType, mainReceiver);
        return queueNumber;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No money to withdraw");

        _sendMoney(payable(owner), amount, "Owner withdrawal");
        emit Withdrawn(owner, amount);
    }

    function changeAllowedPayer(address newAllowedPayer) external onlyOwner {
        require(newAllowedPayer != address(0), "Allowed payer cannot be zero");

        address oldPayer = allowedPayer;
        allowedPayer = newAllowedPayer;

        emit AllowedPayerChanged(oldPayer, newAllowedPayer);
    }

    function changeWallets(address payable newHospitalWallet, address payable newEmergencyWallet) external onlyOwner {
        require(newHospitalWallet != address(0), "Hospital wallet cannot be zero");
        require(newEmergencyWallet != address(0), "Emergency wallet cannot be zero");

        hospitalWallet = newHospitalWallet;
        emergencyWallet = newEmergencyWallet;
    }

    function changePaymentLimits(uint256 newMinPayment, uint256 newVipPayment) external onlyOwner {
        require(newMinPayment > 0, "Minimum payment must be greater than zero");
        require(newVipPayment >= newMinPayment, "VIP payment must be at least minimum");

        minPayment = newMinPayment;
        vipPayment = newVipPayment;
    }

    function _sendMoney(address payable receiver, uint256 amount, string memory reason) private {
        require(amount > 0, "Transfer amount must be greater than zero");

        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Money transfer failed");

        emit MoneyRouted(receiver, amount, reason);
    }
}
