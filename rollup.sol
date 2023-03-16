pragma solidity ^0.8.0;

contract BaseRollup {
    uint public rollupBlockNumber;
    uint public rollupBlockTimestamp;

    function submitBlock(uint blockNumber, uint blockTimestamp) public {
        // Verify that the block has not already been submitted
        require(blockNumber > rollupBlockNumber, "Block already submitted");

        // Verify that the block timestamp is not in the future
        require(blockTimestamp <= block.timestamp, "Block timestamp is in the future");

        // Update the rollup block number and timestamp
        rollupBlockNumber = blockNumber;
        rollupBlockTimestamp = blockTimestamp;
    }
}
