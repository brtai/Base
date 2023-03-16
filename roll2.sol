pragma solidity ^0.8.0;

contract OptimisticRollup {
    struct Block {
        uint blockNumber;
        bytes32 blockHash;
        uint timestamp;
        bytes32 stateRoot;
        uint numTransactions;
        bytes32[] transactionHashes;
    }

    struct Transaction {
        address from;
        address to;
        uint amount;
        bytes data;
    }

    struct InclusionProof {
        bytes32 blockHash;
        uint txIndex;
        bytes32[] siblings;
    }

    struct Dispute {
        uint blockNumber;
        bytes32 blockHash;
        uint timestamp;
        bytes32 stateRoot;
        uint numTransactions;
        bytes32[] transactionHashes;
        bytes32[] transactionData;
        bytes32[] transactionProofs;
        bytes32[] stateProofs;
        address challenger;
        bool resolved;
    }

    uint public lastBlockNumber;
    mapping(uint => Block) public blocks;
    mapping(bytes32 => Transaction) public transactions;
    mapping(bytes32 => bool) public transactionExists;
    mapping(bytes32 => InclusionProof) public inclusionProofs;
    mapping(bytes32 => Dispute) public disputes;

    event BlockSubmitted(uint blockNumber, bytes32 blockHash, uint timestamp, bytes32 stateRoot, uint numTransactions);
    event TransactionSubmitted(address from, address to, uint amount, bytes data, bytes32 txHash);
    event DisputeStarted(uint blockNumber, bytes32 blockHash, uint timestamp, bytes32 stateRoot, uint numTransactions, bytes32[] transactionHashes, bytes32[] transactionData, bytes32[] transactionProofs, bytes32[] stateProofs, address challenger);
    event DisputeResolved(bytes32 txHash, bool success);

    function submitBlock(bytes32 blockHash, uint timestamp, bytes32 stateRoot, uint numTransactions, bytes32[] memory transactionHashes) public {
        require(blockHash != bytes32(0), "Block hash cannot be zero");
        require(timestamp <= block.timestamp, "Block timestamp is in the future");
        require(stateRoot != bytes32(0), "State root cannot be zero");
        require(numTransactions == transactionHashes.length, "Number of transactions does not match transaction hashes");

        uint blockNumber = lastBlockNumber + 1;
        blocks[blockNumber] = Block(blockNumber, blockHash, timestamp, stateRoot, numTransactions, transactionHashes);

        emit BlockSubmitted(blockNumber, blockHash, timestamp, stateRoot, numTransactions);

        lastBlockNumber = blockNumber;
    }

    function submitTransaction(address to, uint amount, bytes memory data) public {
        bytes32 txHash = keccak256(abi.encodePacked(msg.sender, to, amount, data));

        require(!transactionExists[txHash], "Transaction already exists");

        transactions[txHash] = Transaction(msg.sender, to, amount, data);
        transactionExists[txHash] = true;

        emit TransactionSubmitted(msg.sender, to, amount, data, txHash);
    }

    function submitInclusionProof(bytes32 txHash, bytes32 blockHash, uint txIndex, bytes32[] memory siblings) public {
        require(blockHash != bytes32(0), "Block hash cannot be zero");
        require(siblings.length > 0, "Inclusion proof must have at least one sibling");

        inclusionProofs[txHash] = InclusionProof(blockHash, txIndex, siblings);
    }

    function startDispute(bytes32 txHash, bytes32 blockHash, uint txIndex, bytes32[] memory transactionData, bytes32[] memory transactionProofs, bytes32
