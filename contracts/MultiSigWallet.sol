// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MultiSigWallet {

    // Transaction Struct
    struct Transaction{
        address to;
        uint256 value;
        bytes[] data;
        bool executed;
    }

    // state variables
    address[] private s_owners;
    mapping(address => bool) private s_isOwner;


    mapping(uint256 => mapping(address => bool)) s_approvals;
    Transaction[] private s_transactions;

    uint256 private immutable i_requiredSignatures; // minimum number of signatures

    

    // Define Events
        // approve
        event Approve(address owner, uint256 txId);        

        // revoke
        event Revoke(address owner, uint256 txId);

        // execute
        event Execute(uint256 txId);

        // new transaction
        event NewTransaction(uint256 txId);


    // Modifiers

        // only Owner
        modifier onlyOwner {
            require(s_isOwner[msg.sender], "not owner");
            _;
        }

        // isApproved
        modifier isApproved(uint256 txId) {
            require(!s_approvals[txId][msg.sender], "txn id already approved");
            _;
        }

        // transaction exists
        modifier txnExists(uint256 txId) {
            require(txId < s_transactions.length, "txn id does not exist" );
            _;
        }
        // isExecuted
        modifier isExecuted(uint256 txId) {
            require(!s_transactions[txId].executed, "txn Id already executed");
            _;
        }

    /**
     * @param required quorum needed to execute transactions
     * @param owners list of unique owners - no duplication of owners is allowed
     */
    constructor (uint256 required, address[] memory owners){
        // assign required quorum - this is immutable
        i_requiredSignatures = required;

        // assign owners and isOwner mapping
        for(uint256 i; i<owners.length; i++){
            // exit the first time you find duplicates
            address _owner = owners[i];
            require(!s_isOwner[_owner], "Duplicates found in owner list");
            s_owners.push(_owner);
            s_isOwner[_owner] = true;
        }
    }

    // create a new txn
    function createTx(address to, uint256 amount, bytes[] calldata data  ) external {
        s_transactions.push(Transaction({to:to, value: amount, data: data, executed: false} ));
        emit NewTransaction(s_transactions.length - 1);
    }

    // Approve
    function approve(uint256 txId) external onlyOwner txnExists(txId) isApproved(txId) {

        s_approvals[txId][msg.sender] = true;
        emit Approve(msg.sender, txId);

    }

    // Execute
    function execute(uint256 txId) external onlyOwner txnExists(txId) {
        require(countApprovals(txId) >= i_requiredSignatures, "Not enough owners have approved");

        Transaction storage transaction = s_transactions[txId];
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "transfer failed");

        emit Execute(txId);
        

    }
    // Revoke
    function revoke(uint256 txId) external onlyOwner txnExists(txId)  {
        require(s_approvals[txId][msg.sender], "txn id not approved");

        s_approvals[txId][msg.sender] = false;
        emit Revoke(msg.sender, txId);

    }

    // count number of approvals

    function countApprovals(uint256 txId) private view returns(uint256 count){
        
        for(uint i; i< s_owners.length; i++){
            if(s_approvals[txId][s_owners[i]]) {
                count++ ;
            }
        }
    }
}