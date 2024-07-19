// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// lib/chainlink/contracts/src/v0.8/automation/AutomationBase.sol

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function _preventExecution() internal view {
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin != address(0) && tx.origin != address(0x1111111111111111111111111111111111111111)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    _preventExecution();
    _;
  }
}

// lib/chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// lib/chainlink/contracts/src/v0.8/shared/interfaces/IERC677Receiver.sol

interface IERC677Receiver {
  function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external;
}

// lib/chainlink/contracts/src/v0.8/shared/interfaces/IOwnable.sol

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// lib/chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// lib/chainlink/contracts/src/v0.8/vendor/@arbitrum/nitro-contracts/src/precompiles/ArbGasInfo.sol
// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE

/// @title Provides insight into the cost of using the chain.
/// @notice These methods have been adjusted to account for Nitro's heavy use of calldata compression.
/// Of note to end-users, we no longer make a distinction between non-zero and zero-valued calldata bytes.
/// Precompiled contract that exists in every Arbitrum chain at 0x000000000000000000000000000000000000006c.
interface ArbGasInfo {
    /// @notice Get gas prices for a provided aggregator
    /// @return return gas prices in wei
    ///        (
    ///            per L2 tx,
    ///            per L1 calldata byte
    ///            per storage allocation,
    ///            per ArbGas base,
    ///            per ArbGas congestion,
    ///            per ArbGas total
    ///        )
    function getPricesInWeiWithAggregator(address aggregator)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    /// @notice Get gas prices. Uses the caller's preferred aggregator, or the default if the caller doesn't have a preferred one.
    /// @return return gas prices in wei
    ///        (
    ///            per L2 tx,
    ///            per L1 calldata byte
    ///            per storage allocation,
    ///            per ArbGas base,
    ///            per ArbGas congestion,
    ///            per ArbGas total
    ///        )
    function getPricesInWei()
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    /// @notice Get prices in ArbGas for the supplied aggregator
    /// @return (per L2 tx, per L1 calldata byte, per storage allocation)
    function getPricesInArbGasWithAggregator(address aggregator)
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    );

    /// @notice Get prices in ArbGas. Assumes the callers preferred validator, or the default if caller doesn't have a preferred one.
    /// @return (per L2 tx, per L1 calldata byte, per storage allocation)
    function getPricesInArbGas()
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    );

    /// @notice Get the gas accounting parameters. `gasPoolMax` is always zero, as the exponential pricing model has no such notion.
    /// @return (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams()
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    );

    /// @notice Get the minimum gas price needed for a tx to succeed
    function getMinimumGasPrice() external view returns (uint256);

    /// @notice Get ArbOS's estimate of the L1 basefee in wei
    function getL1BaseFeeEstimate() external view returns (uint256);

    /// @notice Get how slowly ArbOS updates its estimate of the L1 basefee
    function getL1BaseFeeEstimateInertia() external view returns (uint64);

    /// @notice Get the L1 pricer reward rate, in wei per unit
    /// Available in ArbOS version 11
    function getL1RewardRate() external view returns (uint64);

    /// @notice Get the L1 pricer reward recipient
    /// Available in ArbOS version 11
    function getL1RewardRecipient() external view returns (address);

    /// @notice Deprecated -- Same as getL1BaseFeeEstimate()
    function getL1GasPriceEstimate() external view returns (uint256);

    /// @notice Get L1 gas fees paid by the current transaction
    function getCurrentTxL1GasFees() external view returns (uint256);

    /// @notice Get the backlogged amount of gas burnt in excess of the speed limit
    function getGasBacklog() external view returns (uint64);

    /// @notice Get how slowly ArbOS updates the L2 basefee in response to backlogged gas
    function getPricingInertia() external view returns (uint64);

    /// @notice Get the forgivable amount of backlogged gas ArbOS will ignore when raising the basefee
    function getGasBacklogTolerance() external view returns (uint64);

    /// @notice Returns the surplus of funds for L1 batch posting payments (may be negative).
    function getL1PricingSurplus() external view returns (int256);

    /// @notice Returns the base charge (in L1 gas) attributed to each data batch in the calldata pricer
    function getPerBatchGasCharge() external view returns (int64);

    /// @notice Returns the cost amortization cap in basis points
    function getAmortizedCostCapBips() external view returns (uint64);

    /// @notice Returns the available funds from L1 fees
    function getL1FeesAvailable() external view returns (uint256);

    /// @notice Returns the equilibration units parameter for L1 price adjustment algorithm
    /// Available in ArbOS version 20
    function getL1PricingEquilibrationUnits() external view returns (uint256);

    /// @notice Returns the last time the L1 calldata pricer was updated.
    /// Available in ArbOS version 20
    function getLastL1PricingUpdateTime() external view returns (uint64);

    /// @notice Returns the amount of L1 calldata payments due for rewards (per the L1 reward rate)
    /// Available in ArbOS version 20
    function getL1PricingFundsDueForRewards() external view returns (uint256);

    /// @notice Returns the amount of L1 calldata posted since the last update.
    /// Available in ArbOS version 20
    function getL1PricingUnitsSinceUpdate() external view returns (uint64);

    /// @notice Returns the L1 pricing surplus as of the last update (may be negative).
    /// Available in ArbOS version 20
    function getLastL1PricingSurplus() external view returns (int256);
}

// lib/chainlink/contracts/src/v0.8/vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol
// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// lib/chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// lib/chainlink/contracts/src/v0.8/vrf/VRF.sol

/** ****************************************************************************
  * @notice Verification of verifiable-random-function (VRF) proofs, following
  * @notice https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
  * @notice See https://eprint.iacr.org/2017/099.pdf for security proofs.

  * @dev Bibliographic references:

  * @dev Goldberg, et al., "Verifiable Random Functions (VRFs)", Internet Draft
  * @dev draft-irtf-cfrg-vrf-05, IETF, Aug 11 2019,
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05

  * @dev Papadopoulos, et al., "Making NSEC5 Practical for DNSSEC", Cryptology
  * @dev ePrint Archive, Report 2017/099, https://eprint.iacr.org/2017/099.pdf
  * ****************************************************************************
  * @dev USAGE

  * @dev The main entry point is _randomValueFromVRFProof. See its docstring.
  * ****************************************************************************
  * @dev PURPOSE

  * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
  * @dev to Vera the verifier in such a way that Vera can be sure he's not
  * @dev making his output up to suit himself. Reggie provides Vera a public key
  * @dev to which he knows the secret key. Each time Vera provides a seed to
  * @dev Reggie, he gives back a value which is computed completely
  * @dev deterministically from the seed and the secret key.

  * @dev Reggie provides a proof by which Vera can verify that the output was
  * @dev correctly computed once Reggie tells it to her, but without that proof,
  * @dev the output is computationally indistinguishable to her from a uniform
  * @dev random sample from the output space.

  * @dev The purpose of this contract is to perform that verification.
  * ****************************************************************************
  * @dev DESIGN NOTES

  * @dev The VRF algorithm verified here satisfies the full uniqueness, full
  * @dev collision resistance, and full pseudo-randomness security properties.
  * @dev See "SECURITY PROPERTIES" below, and
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-3

  * @dev An elliptic curve point is generally represented in the solidity code
  * @dev as a uint256[2], corresponding to its affine coordinates in
  * @dev GF(FIELD_SIZE).

  * @dev For the sake of efficiency, this implementation deviates from the spec
  * @dev in some minor ways:

  * @dev - Keccak hash rather than the SHA256 hash recommended in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
  * @dev   Keccak costs much less gas on the EVM, and provides similar security.

  * @dev - Secp256k1 curve instead of the P-256 or ED25519 curves recommended in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
  * @dev   For curve-point multiplication, it's much cheaper to abuse ECRECOVER

  * @dev - _hashToCurve recursively hashes until it finds a curve x-ordinate. On
  * @dev   the EVM, this is slightly more efficient than the recommendation in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
  * @dev   step 5, to concatenate with a nonce then hash, and rehash with the
  * @dev   nonce updated until a valid x-ordinate is found.

  * @dev - _hashToCurve does not include a cipher version string or the byte 0x1
  * @dev   in the hash message, as recommended in step 5.B of the draft
  * @dev   standard. They are unnecessary here because no variation in the
  * @dev   cipher suite is allowed.

  * @dev - Similarly, the hash input in _scalarFromCurvePoints does not include a
  * @dev   commitment to the cipher suite, either, which differs from step 2 of
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
  * @dev   . Also, the hash input is the concatenation of the uncompressed
  * @dev   points, not the compressed points as recommended in step 3.

  * @dev - In the calculation of the challenge value "c", the "u" value (i.e.
  * @dev   the value computed by Reggie as the nonce times the secp256k1
  * @dev   generator point, see steps 5 and 7 of
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
  * @dev   ) is replaced by its ethereum address, i.e. the lower 160 bits of the
  * @dev   keccak hash of the original u. This is because we only verify the
  * @dev   calculation of u up to its address, by abusing ECRECOVER.
  * ****************************************************************************
  * @dev   SECURITY PROPERTIES

  * @dev Here are the security properties for this VRF:

  * @dev Full uniqueness: For any seed and valid VRF public key, there is
  * @dev   exactly one VRF output which can be proved to come from that seed, in
  * @dev   the sense that the proof will pass _verifyVRFProof.

  * @dev Full collision resistance: It's cryptographically infeasible to find
  * @dev   two seeds with same VRF output from a fixed, valid VRF key

  * @dev Full pseudorandomness: Absent the proofs that the VRF outputs are
  * @dev   derived from a given seed, the outputs are computationally
  * @dev   indistinguishable from randomness.

  * @dev https://eprint.iacr.org/2017/099.pdf, Appendix B contains the proofs
  * @dev for these properties.

  * @dev For secp256k1, the key validation described in section
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.6
  * @dev is unnecessary, because secp256k1 has cofactor 1, and the
  * @dev representation of the public key used here (affine x- and y-ordinates
  * @dev of the secp256k1 point on the standard y^2=x^3+7 curve) cannot refer to
  * @dev the point at infinity.
  * ****************************************************************************
  * @dev OTHER SECURITY CONSIDERATIONS
  *
  * @dev The seed input to the VRF could in principle force an arbitrary amount
  * @dev of work in _hashToCurve, by requiring extra rounds of hashing and
  * @dev checking whether that's yielded the x ordinate of a secp256k1 point.
  * @dev However, under the Random Oracle Model the probability of choosing a
  * @dev point which forces n extra rounds in _hashToCurve is 2⁻ⁿ. The base cost
  * @dev for calling _hashToCurve is about 25,000 gas, and each round of checking
  * @dev for a valid x ordinate costs about 15,555 gas, so to find a seed for
  * @dev which _hashToCurve would cost more than 2,017,000 gas, one would have to
  * @dev try, in expectation, about 2¹²⁸ seeds, which is infeasible for any
  * @dev foreseeable computational resources. (25,000 + 128 * 15,555 < 2,017,000.)

  * @dev Since the gas block limit for the Ethereum main net is 10,000,000 gas,
  * @dev this means it is infeasible for an adversary to prevent correct
  * @dev operation of this contract by choosing an adverse seed.

  * @dev (See TestMeasureHashToCurveGasCost for verification of the gas cost for
  * @dev _hashToCurve.)

  * @dev It may be possible to make a secure constant-time _hashToCurve function.
  * @dev See notes in _hashToCurve docstring.
*/
contract VRF {
  // See https://www.secg.org/sec2-v2.pdf, section 2.4.1, for these constants.
  // Number of points in Secp256k1
  uint256 private constant GROUP_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
  // Prime characteristic of the galois field over which Secp256k1 is defined
  uint256 private constant FIELD_SIZE =
    // solium-disable-next-line indentation
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
  uint256 private constant WORD_LENGTH_BYTES = 0x20;

  // (base^exponent) % FIELD_SIZE
  // Cribbed from https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
  function _bigModExp(uint256 base, uint256 exponent) internal view returns (uint256 exponentiation) {
    uint256 callResult;
    uint256[6] memory bigModExpContractInputs;
    bigModExpContractInputs[0] = WORD_LENGTH_BYTES; // Length of base
    bigModExpContractInputs[1] = WORD_LENGTH_BYTES; // Length of exponent
    bigModExpContractInputs[2] = WORD_LENGTH_BYTES; // Length of modulus
    bigModExpContractInputs[3] = base;
    bigModExpContractInputs[4] = exponent;
    bigModExpContractInputs[5] = FIELD_SIZE;
    uint256[1] memory output;
    assembly {
      callResult := staticcall(
        not(0), // Gas cost: no limit
        0x05, // Bigmodexp contract address
        bigModExpContractInputs,
        0xc0, // Length of input segment: 6*0x20-bytes
        output,
        0x20 // Length of output segment
      )
    }
    if (callResult == 0) {
      // solhint-disable-next-line gas-custom-errors
      revert("bigModExp failure!");
    }
    return output[0];
  }

  // Let q=FIELD_SIZE. q % 4 = 3, ∴ x≡r^2 mod q ⇒ x^SQRT_POWER≡±r mod q.  See
  // https://en.wikipedia.org/wiki/Modular_square_root#Prime_or_prime_power_modulus
  uint256 private constant SQRT_POWER = (FIELD_SIZE + 1) >> 2;

  // Computes a s.t. a^2 = x in the field. Assumes a exists
  function _squareRoot(uint256 x) internal view returns (uint256) {
    return _bigModExp(x, SQRT_POWER);
  }

  // The value of y^2 given that (x,y) is on secp256k1.
  function _ySquared(uint256 x) internal pure returns (uint256) {
    // Curve is y^2=x^3+7. See section 2.4.1 of https://www.secg.org/sec2-v2.pdf
    uint256 xCubed = mulmod(x, mulmod(x, x, FIELD_SIZE), FIELD_SIZE);
    return addmod(xCubed, 7, FIELD_SIZE);
  }

  // True iff p is on secp256k1
  function _isOnCurve(uint256[2] memory p) internal pure returns (bool) {
    // Section 2.3.6. in https://www.secg.org/sec1-v2.pdf
    // requires each ordinate to be in [0, ..., FIELD_SIZE-1]
    // solhint-disable-next-line gas-custom-errors
    require(p[0] < FIELD_SIZE, "invalid x-ordinate");
    // solhint-disable-next-line gas-custom-errors
    require(p[1] < FIELD_SIZE, "invalid y-ordinate");
    return _ySquared(p[0]) == mulmod(p[1], p[1], FIELD_SIZE);
  }

  // Hash x uniformly into {0, ..., FIELD_SIZE-1}.
  function _fieldHash(bytes memory b) internal pure returns (uint256 x_) {
    x_ = uint256(keccak256(b));
    // Rejecting if x >= FIELD_SIZE corresponds to step 2.1 in section 2.3.4 of
    // http://www.secg.org/sec1-v2.pdf , which is part of the definition of
    // string_to_point in the IETF draft
    while (x_ >= FIELD_SIZE) {
      x_ = uint256(keccak256(abi.encodePacked(x_)));
    }
    return x_;
  }

  // Hash b to a random point which hopefully lies on secp256k1. The y ordinate
  // is always even, due to
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
  // step 5.C, which references arbitrary_string_to_point, defined in
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5 as
  // returning the point with given x ordinate, and even y ordinate.
  function _newCandidateSecp256k1Point(bytes memory b) internal view returns (uint256[2] memory p) {
    unchecked {
      p[0] = _fieldHash(b);
      p[1] = _squareRoot(_ySquared(p[0]));
      if (p[1] % 2 == 1) {
        // Note that 0 <= p[1] < FIELD_SIZE
        // so this cannot wrap, we use unchecked to save gas.
        p[1] = FIELD_SIZE - p[1];
      }
    }
    return p;
  }

  // Domain-separation tag for initial hash in _hashToCurve. Corresponds to
  // vrf.go/hashToCurveHashPrefix
  uint256 internal constant HASH_TO_CURVE_HASH_PREFIX = 1;

  // Cryptographic hash function onto the curve.
  //
  // Corresponds to algorithm in section 5.4.1.1 of the draft standard. (But see
  // DESIGN NOTES above for slight differences.)
  //
  // TODO(alx): Implement a bounded-computation hash-to-curve, as described in
  // "Construction of Rational Points on Elliptic Curves over Finite Fields"
  // http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.831.5299&rep=rep1&type=pdf
  // and suggested by
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-01#section-5.2.2
  // (Though we can't used exactly that because secp256k1's j-invariant is 0.)
  //
  // This would greatly simplify the analysis in "OTHER SECURITY CONSIDERATIONS"
  // https://www.pivotaltracker.com/story/show/171120900
  function _hashToCurve(uint256[2] memory pk, uint256 input) internal view returns (uint256[2] memory rv) {
    rv = _newCandidateSecp256k1Point(abi.encodePacked(HASH_TO_CURVE_HASH_PREFIX, pk, input));
    while (!_isOnCurve(rv)) {
      rv = _newCandidateSecp256k1Point(abi.encodePacked(rv[0]));
    }
    return rv;
  }

  /** *********************************************************************
   * @notice Check that product==scalar*multiplicand
   *
   * @dev Based on Vitalik Buterin's idea in ethresear.ch post cited below.
   *
   * @param multiplicand: secp256k1 point
   * @param scalar: non-zero GF(GROUP_ORDER) scalar
   * @param product: secp256k1 expected to be multiplier * multiplicand
   * @return verifies true iff product==scalar*multiplicand, with cryptographically high probability
   */
  function _ecmulVerify(
    uint256[2] memory multiplicand,
    uint256 scalar,
    uint256[2] memory product
  ) internal pure returns (bool verifies) {
    // solhint-disable-next-line gas-custom-errors
    require(scalar != 0, "zero scalar"); // Rules out an ecrecover failure case
    uint256 x = multiplicand[0]; // x ordinate of multiplicand
    uint8 v = multiplicand[1] % 2 == 0 ? 27 : 28; // parity of y ordinate
    // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    // Point corresponding to address ecrecover(0, v, x, s=scalar*x) is
    // (x⁻¹ mod GROUP_ORDER) * (scalar * x * multiplicand - 0 * g), i.e.
    // scalar*multiplicand. See https://crypto.stackexchange.com/a/18106
    bytes32 scalarTimesX = bytes32(mulmod(scalar, x, GROUP_ORDER));
    address actual = ecrecover(bytes32(0), v, bytes32(x), scalarTimesX);
    // Explicit conversion to address takes bottom 160 bits
    address expected = address(uint160(uint256(keccak256(abi.encodePacked(product)))));
    return (actual == expected);
  }

  // Returns x1/z1-x2/z2=(x1z2-x2z1)/(z1z2) in projective coordinates on P¹(𝔽ₙ)
  function _projectiveSub(
    uint256 x1,
    uint256 z1,
    uint256 x2,
    uint256 z2
  ) internal pure returns (uint256 x3, uint256 z3) {
    unchecked {
      uint256 num1 = mulmod(z2, x1, FIELD_SIZE);
      // Note this cannot wrap since x2 is a point in [0, FIELD_SIZE-1]
      // we use unchecked to save gas.
      uint256 num2 = mulmod(FIELD_SIZE - x2, z1, FIELD_SIZE);
      (x3, z3) = (addmod(num1, num2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    }
    return (x3, z3);
  }

  // Returns x1/z1*x2/z2=(x1x2)/(z1z2), in projective coordinates on P¹(𝔽ₙ)
  function _projectiveMul(
    uint256 x1,
    uint256 z1,
    uint256 x2,
    uint256 z2
  ) internal pure returns (uint256 x3, uint256 z3) {
    (x3, z3) = (mulmod(x1, x2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    return (x3, z3);
  }

  /** **************************************************************************
        @notice Computes elliptic-curve sum, in projective co-ordinates

        @dev Using projective coordinates avoids costly divisions

        @dev To use this with p and q in affine coordinates, call
        @dev _projectiveECAdd(px, py, qx, qy). This will return
        @dev the addition of (px, py, 1) and (qx, qy, 1), in the
        @dev secp256k1 group.

        @dev This can be used to calculate the z which is the inverse to zInv
        @dev in isValidVRFOutput. But consider using a faster
        @dev re-implementation such as ProjectiveECAdd in the golang vrf package.

        @dev This function assumes [px,py,1],[qx,qy,1] are valid projective
             coordinates of secp256k1 points. That is safe in this contract,
             because this method is only used by _linearCombination, which checks
             points are on the curve via ecrecover.
        **************************************************************************
        @param px The first affine coordinate of the first summand
        @param py The second affine coordinate of the first summand
        @param qx The first affine coordinate of the second summand
        @param qy The second affine coordinate of the second summand

        (px,py) and (qx,qy) must be distinct, valid secp256k1 points.
        **************************************************************************
        Return values are projective coordinates of [px,py,1]+[qx,qy,1] as points
        on secp256k1, in P²(𝔽ₙ)
        @return sx
        @return sy
        @return sz
    */
  function _projectiveECAdd(
    uint256 px,
    uint256 py,
    uint256 qx,
    uint256 qy
  ) internal pure returns (uint256 sx, uint256 sy, uint256 sz) {
    unchecked {
      // See "Group law for E/K : y^2 = x^3 + ax + b", in section 3.1.2, p. 80,
      // "Guide to Elliptic Curve Cryptography" by Hankerson, Menezes and Vanstone
      // We take the equations there for (sx,sy), and homogenize them to
      // projective coordinates. That way, no inverses are required, here, and we
      // only need the one inverse in _affineECAdd.

      // We only need the "point addition" equations from Hankerson et al. Can
      // skip the "point doubling" equations because p1 == p2 is cryptographically
      // impossible, and required not to be the case in _linearCombination.

      // Add extra "projective coordinate" to the two points
      (uint256 z1, uint256 z2) = (1, 1);

      // (lx, lz) = (qy-py)/(qx-px), i.e., gradient of secant line.
      // Cannot wrap since px and py are in [0, FIELD_SIZE-1]
      uint256 lx = addmod(qy, FIELD_SIZE - py, FIELD_SIZE);
      uint256 lz = addmod(qx, FIELD_SIZE - px, FIELD_SIZE);

      uint256 dx; // Accumulates denominator from sx calculation
      // sx=((qy-py)/(qx-px))^2-px-qx
      (sx, dx) = _projectiveMul(lx, lz, lx, lz); // ((qy-py)/(qx-px))^2
      (sx, dx) = _projectiveSub(sx, dx, px, z1); // ((qy-py)/(qx-px))^2-px
      (sx, dx) = _projectiveSub(sx, dx, qx, z2); // ((qy-py)/(qx-px))^2-px-qx

      uint256 dy; // Accumulates denominator from sy calculation
      // sy=((qy-py)/(qx-px))(px-sx)-py
      (sy, dy) = _projectiveSub(px, z1, sx, dx); // px-sx
      (sy, dy) = _projectiveMul(sy, dy, lx, lz); // ((qy-py)/(qx-px))(px-sx)
      (sy, dy) = _projectiveSub(sy, dy, py, z1); // ((qy-py)/(qx-px))(px-sx)-py

      if (dx != dy) {
        // Cross-multiply to put everything over a common denominator
        sx = mulmod(sx, dy, FIELD_SIZE);
        sy = mulmod(sy, dx, FIELD_SIZE);
        sz = mulmod(dx, dy, FIELD_SIZE);
      } else {
        // Already over a common denominator, use that for z ordinate
        sz = dx;
      }
    }
    return (sx, sy, sz);
  }

  // p1+p2, as affine points on secp256k1.
  //
  // invZ must be the inverse of the z returned by _projectiveECAdd(p1, p2).
  // It is computed off-chain to save gas.
  //
  // p1 and p2 must be distinct, because _projectiveECAdd doesn't handle
  // point doubling.
  function _affineECAdd(
    uint256[2] memory p1,
    uint256[2] memory p2,
    uint256 invZ
  ) internal pure returns (uint256[2] memory) {
    uint256 x;
    uint256 y;
    uint256 z;
    (x, y, z) = _projectiveECAdd(p1[0], p1[1], p2[0], p2[1]);
    // solhint-disable-next-line gas-custom-errors
    require(mulmod(z, invZ, FIELD_SIZE) == 1, "invZ must be inverse of z");
    // Clear the z ordinate of the projective representation by dividing through
    // by it, to obtain the affine representation
    return [mulmod(x, invZ, FIELD_SIZE), mulmod(y, invZ, FIELD_SIZE)];
  }

  // True iff address(c*p+s*g) == lcWitness, where g is generator. (With
  // cryptographically high probability.)
  function _verifyLinearCombinationWithGenerator(
    uint256 c,
    uint256[2] memory p,
    uint256 s,
    address lcWitness
  ) internal pure returns (bool) {
    // Rule out ecrecover failure modes which return address 0.
    unchecked {
      // solhint-disable-next-line gas-custom-errors
      require(lcWitness != address(0), "bad witness");
      uint8 v = (p[1] % 2 == 0) ? 27 : 28; // parity of y-ordinate of p
      // Note this cannot wrap (X - Y % X), but we use unchecked to save
      // gas.
      bytes32 pseudoHash = bytes32(GROUP_ORDER - mulmod(p[0], s, GROUP_ORDER)); // -s*p[0]
      bytes32 pseudoSignature = bytes32(mulmod(c, p[0], GROUP_ORDER)); // c*p[0]
      // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
      // The point corresponding to the address returned by
      // ecrecover(-s*p[0],v,p[0],c*p[0]) is
      // (p[0]⁻¹ mod GROUP_ORDER)*(c*p[0]-(-s)*p[0]*g)=c*p+s*g.
      // See https://crypto.stackexchange.com/a/18106
      // https://bitcoin.stackexchange.com/questions/38351/ecdsa-v-r-s-what-is-v
      address computed = ecrecover(pseudoHash, v, bytes32(p[0]), pseudoSignature);
      return computed == lcWitness;
    }
  }

  // c*p1 + s*p2. Requires cp1Witness=c*p1 and sp2Witness=s*p2. Also
  // requires cp1Witness != sp2Witness (which is fine for this application,
  // since it is cryptographically impossible for them to be equal. In the
  // (cryptographically impossible) case that a prover accidentally derives
  // a proof with equal c*p1 and s*p2, they should retry with a different
  // proof nonce.) Assumes that all points are on secp256k1
  // (which is checked in _verifyVRFProof below.)
  function _linearCombination(
    uint256 c,
    uint256[2] memory p1,
    uint256[2] memory cp1Witness,
    uint256 s,
    uint256[2] memory p2,
    uint256[2] memory sp2Witness,
    uint256 zInv
  ) internal pure returns (uint256[2] memory) {
    unchecked {
      // Note we are relying on the wrap around here
      // solhint-disable-next-line gas-custom-errors
      require((cp1Witness[0] % FIELD_SIZE) != (sp2Witness[0] % FIELD_SIZE), "points in sum must be distinct");
      // solhint-disable-next-line gas-custom-errors
      require(_ecmulVerify(p1, c, cp1Witness), "First mul check failed");
      // solhint-disable-next-line gas-custom-errors
      require(_ecmulVerify(p2, s, sp2Witness), "Second mul check failed");
      return _affineECAdd(cp1Witness, sp2Witness, zInv);
    }
  }

  // Domain-separation tag for the hash taken in _scalarFromCurvePoints.
  // Corresponds to scalarFromCurveHashPrefix in vrf.go
  uint256 internal constant SCALAR_FROM_CURVE_POINTS_HASH_PREFIX = 2;

  // Pseudo-random number from inputs. Matches vrf.go/_scalarFromCurvePoints, and
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
  // The draft calls (in step 7, via the definition of string_to_int, in
  // https://datatracker.ietf.org/doc/html/rfc8017#section-4.2 ) for taking the
  // first hash without checking that it corresponds to a number less than the
  // group order, which will lead to a slight bias in the sample.
  //
  // TODO(alx): We could save a bit of gas by following the standard here and
  // using the compressed representation of the points, if we collated the y
  // parities into a single bytes32.
  // https://www.pivotaltracker.com/story/show/171120588
  function _scalarFromCurvePoints(
    uint256[2] memory hash,
    uint256[2] memory pk,
    uint256[2] memory gamma,
    address uWitness,
    uint256[2] memory v
  ) internal pure returns (uint256 s) {
    return uint256(keccak256(abi.encodePacked(SCALAR_FROM_CURVE_POINTS_HASH_PREFIX, hash, pk, gamma, v, uWitness)));
  }

  // True if (gamma, c, s) is a correctly constructed randomness proof from pk
  // and seed. zInv must be the inverse of the third ordinate from
  // _projectiveECAdd applied to cGammaWitness and sHashWitness. Corresponds to
  // section 5.3 of the IETF draft.
  //
  // TODO(alx): Since I'm only using pk in the ecrecover call, I could only pass
  // the x ordinate, and the parity of the y ordinate in the top bit of uWitness
  // (which I could make a uint256 without using any extra space.) Would save
  // about 2000 gas. https://www.pivotaltracker.com/story/show/170828567
  function _verifyVRFProof(
    uint256[2] memory pk,
    uint256[2] memory gamma,
    uint256 c,
    uint256 s,
    uint256 seed,
    address uWitness,
    uint256[2] memory cGammaWitness,
    uint256[2] memory sHashWitness,
    uint256 zInv
  ) internal view {
    unchecked {
      // solhint-disable-next-line gas-custom-errors
      require(_isOnCurve(pk), "public key is not on curve");
      // solhint-disable-next-line gas-custom-errors
      require(_isOnCurve(gamma), "gamma is not on curve");
      // solhint-disable-next-line gas-custom-errors
      require(_isOnCurve(cGammaWitness), "cGammaWitness is not on curve");
      // solhint-disable-next-line gas-custom-errors
      require(_isOnCurve(sHashWitness), "sHashWitness is not on curve");
      // Step 5. of IETF draft section 5.3 (pk corresponds to 5.3's Y, and here
      // we use the address of u instead of u itself. Also, here we add the
      // terms instead of taking the difference, and in the proof construction in
      // vrf.GenerateProof, we correspondingly take the difference instead of
      // taking the sum as they do in step 7 of section 5.1.)
      // solhint-disable-next-line gas-custom-errors
      require(_verifyLinearCombinationWithGenerator(c, pk, s, uWitness), "addr(c*pk+s*g)!=_uWitness");
      // Step 4. of IETF draft section 5.3 (pk corresponds to Y, seed to alpha_string)
      uint256[2] memory hash = _hashToCurve(pk, seed);
      // Step 6. of IETF draft section 5.3, but see note for step 5 about +/- terms
      uint256[2] memory v = _linearCombination(c, gamma, cGammaWitness, s, hash, sHashWitness, zInv);
      // Steps 7. and 8. of IETF draft section 5.3
      uint256 derivedC = _scalarFromCurvePoints(hash, pk, gamma, uWitness, v);
      // solhint-disable-next-line gas-custom-errors
      require(c == derivedC, "invalid proof");
    }
  }

  // Domain-separation tag for the hash used as the final VRF output.
  // Corresponds to vrfRandomOutputHashPrefix in vrf.go
  uint256 internal constant VRF_RANDOM_OUTPUT_HASH_PREFIX = 3;

  struct Proof {
    uint256[2] pk;
    uint256[2] gamma;
    uint256 c;
    uint256 s;
    uint256 seed;
    address uWitness;
    uint256[2] cGammaWitness;
    uint256[2] sHashWitness;
    uint256 zInv;
  }

  /* ***************************************************************************
     * @notice Returns proof's output, if proof is valid. Otherwise reverts

     * @param proof vrf proof components
     * @param seed  seed used to generate the vrf output
     *
     * Throws if proof is invalid, otherwise:
     * @return output i.e., the random output implied by the proof
     * ***************************************************************************
     */
  function _randomValueFromVRFProof(Proof memory proof, uint256 seed) internal view returns (uint256 output) {
    _verifyVRFProof(
      proof.pk,
      proof.gamma,
      proof.c,
      proof.s,
      seed,
      proof.uWitness,
      proof.cGammaWitness,
      proof.sHashWitness,
      proof.zInv
    );
    output = uint256(keccak256(abi.encode(VRF_RANDOM_OUTPUT_HASH_PREFIX, proof.gamma)));
    return output;
  }
}

// lib/chainlink/contracts/src/v0.8/vrf/VRFTypes.sol

/**
 * @title VRFTypes
 * @notice The VRFTypes library is a collection of types that is required to fulfill VRF requests
 * 	on-chain. They must be ABI-compatible with the types used by the coordinator contracts.
 */
library VRFTypes {
  // ABI-compatible with VRF.Proof.
  // This proof is used for VRF V2 and V2Plus.
  struct Proof {
    uint256[2] pk;
    uint256[2] gamma;
    uint256 c;
    uint256 s;
    uint256 seed;
    address uWitness;
    uint256[2] cGammaWitness;
    uint256[2] sHashWitness;
    uint256 zInv;
  }

  // ABI-compatible with VRFCoordinatorV2.RequestCommitment.
  // This is only used for VRF V2.
  struct RequestCommitment {
    uint64 blockNum;
    uint64 subId;
    uint32 callbackGasLimit;
    uint32 numWords;
    address sender;
  }

  // ABI-compatible with VRFCoordinatorV2Plus.RequestCommitment.
  // This is only used for VRF V2Plus.
  struct RequestCommitmentV2Plus {
    uint64 blockNum;
    uint256 subId;
    uint32 callbackGasLimit;
    uint32 numWords;
    address sender;
    bytes extraArgs;
  }
}

// lib/chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2PlusMigration.sol

// Future versions of VRFCoordinatorV2Plus must implement IVRFCoordinatorV2PlusMigration
// to support migrations from previous versions
interface IVRFCoordinatorV2PlusMigration {
  /**
   * @notice called by older versions of coordinator for migration.
   * @notice only callable by older versions of coordinator
   * @notice supports transfer of native currency
   * @param encodedData - user data from older version of coordinator
   */
  function onMigration(bytes calldata encodedData) external payable;
}

// lib/chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFMigratableConsumerV2Plus.sol

/// @notice The IVRFMigratableConsumerV2Plus interface defines the
/// @notice method required to be implemented by all V2Plus consumers.
/// @dev This interface is designed to be used in VRFConsumerBaseV2Plus.
interface IVRFMigratableConsumerV2Plus {
  event CoordinatorSet(address vrfCoordinator);

  /// @notice Sets the VRF Coordinator address
  /// @notice This method should only be callable by the coordinator or contract owner
  function setCoordinator(address vrfCoordinator) external;
}

// lib/chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFSubscriptionV2Plus.sol

/// @notice The IVRFSubscriptionV2Plus interface defines the subscription
/// @notice related methods implemented by the V2Plus coordinator.
interface IVRFSubscriptionV2Plus {
  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint256 subId, address to) external;

  /**
   * @notice Accept subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint256 subId) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint256 subId, address newOwner) external;

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription with LINK, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   * @dev Note to fund the subscription with Native, use fundSubscriptionWithNative. Be sure
   * @dev  to send Native with the call, for example:
   * @dev COORDINATOR.fundSubscriptionWithNative{value: amount}(subId);
   */
  function createSubscription() external returns (uint256 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return nativeBalance - native balance of the subscription in wei.
   * @return reqCount - Requests count of subscription.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint256 subId
  )
    external
    view
    returns (uint96 balance, uint96 nativeBalance, uint64 reqCount, address owner, address[] memory consumers);

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint256 subId) external view returns (bool);

  /**
   * @notice Paginate through all active VRF subscriptions.
   * @param startIndex index of the subscription to start from
   * @param maxCount maximum number of subscriptions to return, 0 to return all
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * @dev should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveSubscriptionIds(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  /**
   * @notice Fund a subscription with native.
   * @param subId - ID of the subscription
   * @notice This method expects msg.value to be greater than or equal to 0.
   */
  function fundSubscriptionWithNative(uint256 subId) external payable;
}

// lib/chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol

// End consumer library.
library VRFV2PlusClient {
  // extraArgs will evolve to support new features
  bytes4 public constant EXTRA_ARGS_V1_TAG = bytes4(keccak256("VRF ExtraArgsV1"));
  struct ExtraArgsV1 {
    bool nativePayment;
  }

  struct RandomWordsRequest {
    bytes32 keyHash;
    uint256 subId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    bytes extraArgs;
  }

  function _argsToBytes(ExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// lib/chainlink/contracts/src/v0.8/vrf/interfaces/BlockhashStoreInterface.sol

interface BlockhashStoreInterface {
  function getBlockhash(uint256 number) external view returns (bytes32);
}

// lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// src/interfaces/IUniswap.sol

interface IUniswapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IUniswapRouter02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface ISNGRouter is IUniswapRouter02 {
    function weth() external view returns (address);

    function router() external view returns (address);
}

// lib/chainlink/contracts/src/v0.8/shared/access/ConfirmedOwnerWithProposal.sol

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line gas-custom-errors
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /// @notice Allows an owner to begin transferring ownership to a new address.
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /// @notice Allows an ownership transfer to be completed by the recipient.
  function acceptOwnership() external override {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /// @notice Get the current owner
  function owner() public view override returns (address) {
    return s_owner;
  }

  /// @notice validate, transfer ownership, and emit relevant events
  function _transferOwnership(address to) private {
    // solhint-disable-next-line gas-custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// lib/chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// lib/chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// lib/chainlink/contracts/src/v0.8/vendor/@eth-optimism/contracts/v0.8.9/contracts/L2/predeploys/OVM_GasPriceOracle.sol

/* External Imports */

/**
 * @title OVM_GasPriceOracle
 * @dev This contract exposes the current l2 gas price, a measure of how congested the network
 * currently is. This measure is used by the Sequencer to determine what fee to charge for
 * transactions. When the system is more congested, the l2 gas price will increase and fees
 * will also increase as a result.
 *
 * All public variables are set while generating the initial L2 state. The
 * constructor doesn't run in practice as the L2 state generation script uses
 * the deployed bytecode instead of running the initcode.
 */
contract OVM_GasPriceOracle is Ownable {
  /*************
   * Variables *
   *************/

  // Current L2 gas price
  uint256 public gasPrice;
  // Current L1 base fee
  uint256 public l1BaseFee;
  // Amortized cost of batch submission per transaction
  uint256 public overhead;
  // Value to scale the fee up by
  uint256 public scalar;
  // Number of decimals of the scalar
  uint256 public decimals;

  /***************
   * Constructor *
   ***************/

  /**
   * @param _owner Address that will initially own this contract.
   */
  constructor(address _owner) Ownable() {
    transferOwnership(_owner);
  }

  /**********
   * Events *
   **********/

  event GasPriceUpdated(uint256);
  event L1BaseFeeUpdated(uint256);
  event OverheadUpdated(uint256);
  event ScalarUpdated(uint256);
  event DecimalsUpdated(uint256);

  /********************
   * Public Functions *
   ********************/

  /**
   * Allows the owner to modify the l2 gas price.
   * @param _gasPrice New l2 gas price.
   */
  // slither-disable-next-line external-function
  function setGasPrice(uint256 _gasPrice) public onlyOwner {
    gasPrice = _gasPrice;
    emit GasPriceUpdated(_gasPrice);
  }

  /**
   * Allows the owner to modify the l1 base fee.
   * @param _baseFee New l1 base fee
   */
  // slither-disable-next-line external-function
  function setL1BaseFee(uint256 _baseFee) public onlyOwner {
    l1BaseFee = _baseFee;
    emit L1BaseFeeUpdated(_baseFee);
  }

  /**
   * Allows the owner to modify the overhead.
   * @param _overhead New overhead
   */
  // slither-disable-next-line external-function
  function setOverhead(uint256 _overhead) public onlyOwner {
    overhead = _overhead;
    emit OverheadUpdated(_overhead);
  }

  /**
   * Allows the owner to modify the scalar.
   * @param _scalar New scalar
   */
  // slither-disable-next-line external-function
  function setScalar(uint256 _scalar) public onlyOwner {
    scalar = _scalar;
    emit ScalarUpdated(_scalar);
  }

  /**
   * Allows the owner to modify the decimals.
   * @param _decimals New decimals
   */
  // slither-disable-next-line external-function
  function setDecimals(uint256 _decimals) public onlyOwner {
    decimals = _decimals;
    emit DecimalsUpdated(_decimals);
  }

  /**
   * Computes the L1 portion of the fee
   * based on the size of the RLP encoded tx
   * and the current l1BaseFee
   * @param _data Unsigned RLP encoded tx, 6 elements
   * @return L1 fee that should be paid for the tx
   */
  // slither-disable-next-line external-function
  function getL1Fee(bytes memory _data) public view returns (uint256) {
    uint256 l1GasUsed = getL1GasUsed(_data);
    uint256 l1Fee = l1GasUsed * l1BaseFee;
    uint256 divisor = 10 ** decimals;
    uint256 unscaled = l1Fee * scalar;
    uint256 scaled = unscaled / divisor;
    return scaled;
  }

  // solhint-disable max-line-length
  /**
   * Computes the amount of L1 gas used for a transaction
   * The overhead represents the per batch gas overhead of
   * posting both transaction and state roots to L1 given larger
   * batch sizes.
   * 4 gas for 0 byte
   * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L33
   * 16 gas for non zero byte
   * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L87
   * This will need to be updated if calldata gas prices change
   * Account for the transaction being unsigned
   * Padding is added to account for lack of signature on transaction
   * 1 byte for RLP V prefix
   * 1 byte for V
   * 1 byte for RLP R prefix
   * 32 bytes for R
   * 1 byte for RLP S prefix
   * 32 bytes for S
   * Total: 68 bytes of padding
   * @param _data Unsigned RLP encoded tx, 6 elements
   * @return Amount of L1 gas used for a transaction
   */
  // solhint-enable max-line-length
  function getL1GasUsed(bytes memory _data) public view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < _data.length; i++) {
      if (_data[i] == 0) {
        total += 4;
      } else {
        total += 16;
      }
    }
    uint256 unsigned = total + overhead;
    return unsigned + (68 * 16);
  }
}

// lib/chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol

// Interface that enables consumers of VRFCoordinatorV2Plus to be future-proof for upgrades
// This interface is supported by subsequent versions of VRFCoordinatorV2Plus
interface IVRFCoordinatorV2Plus is IVRFSubscriptionV2Plus {
  /**
   * @notice Request a set of random words.
   * @param req - a struct containing following fields for randomness request:
   * keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * requestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * extraArgs - abi-encoded extra args
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId);
}

// lib/chainlink/contracts/src/v0.8/ChainSpecificUtil.sol

/// @dev A library that abstracts out opcodes that behave differently across chains.
/// @dev The methods below return values that are pertinent to the given chain.
/// @dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
  // ------------ Start Arbitrum Constants ------------

  /// @dev ARBSYS_ADDR is the address of the ArbSys precompile on Arbitrum.
  /// @dev reference: https://github.com/OffchainLabs/nitro/blob/v2.0.14/contracts/src/precompiles/ArbSys.sol#L10
  address private constant ARBSYS_ADDR = address(0x0000000000000000000000000000000000000064);
  ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);

  /// @dev ARBGAS_ADDR is the address of the ArbGasInfo precompile on Arbitrum.
  /// @dev reference: https://github.com/OffchainLabs/nitro/blob/v2.0.14/contracts/src/precompiles/ArbGasInfo.sol#L10
  address private constant ARBGAS_ADDR = address(0x000000000000000000000000000000000000006C);
  ArbGasInfo private constant ARBGAS = ArbGasInfo(ARBGAS_ADDR);

  uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
  uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;
  uint256 private constant ARB_SEPOLIA_TESTNET_CHAIN_ID = 421614;

  // ------------ End Arbitrum Constants ------------

  // ------------ Start Optimism Constants ------------
  /// @dev L1_FEE_DATA_PADDING includes 35 bytes for L1 data padding for Optimism
  bytes internal constant L1_FEE_DATA_PADDING =
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  /// @dev OVM_GASPRICEORACLE_ADDR is the address of the OVM_GasPriceOracle precompile on Optimism.
  /// @dev reference: https://community.optimism.io/docs/developers/build/transaction-fees/#estimating-the-l1-data-fee
  address private constant OVM_GASPRICEORACLE_ADDR = address(0x420000000000000000000000000000000000000F);
  OVM_GasPriceOracle private constant OVM_GASPRICEORACLE = OVM_GasPriceOracle(OVM_GASPRICEORACLE_ADDR);

  uint256 private constant OP_MAINNET_CHAIN_ID = 10;
  uint256 private constant OP_GOERLI_CHAIN_ID = 420;
  uint256 private constant OP_SEPOLIA_CHAIN_ID = 11155420;

  /// @dev Base is a OP stack based rollup and follows the same L1 pricing logic as Optimism.
  uint256 private constant BASE_MAINNET_CHAIN_ID = 8453;
  uint256 private constant BASE_GOERLI_CHAIN_ID = 84531;

  // ------------ End Optimism Constants ------------

  /**
   * @notice Returns the blockhash for the given blockNumber.
   * @notice If the blockNumber is more than 256 blocks in the past, returns the empty string.
   * @notice When on a known Arbitrum chain, it uses ArbSys.arbBlockHash to get the blockhash.
   * @notice Otherwise, it uses the blockhash opcode.
   * @notice Note that the blockhash opcode will return the L2 blockhash on Optimism.
   */
  function _getBlockhash(uint64 blockNumber) internal view returns (bytes32) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      if ((_getBlockNumber() - blockNumber) > 256 || blockNumber >= _getBlockNumber()) {
        return "";
      }
      return ARBSYS.arbBlockHash(blockNumber);
    }
    return blockhash(blockNumber);
  }

  /**
   * @notice Returns the block number of the current block.
   * @notice When on a known Arbitrum chain, it uses ArbSys.arbBlockNumber to get the block number.
   * @notice Otherwise, it uses the block.number opcode.
   * @notice Note that the block.number opcode will return the L2 block number on Optimism.
   */
  function _getBlockNumber() internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      return ARBSYS.arbBlockNumber();
    }
    return block.number;
  }

  /**
   * @notice Returns the L1 fees that will be paid for the current transaction, given any calldata
   * @notice for the current transaction.
   * @notice When on a known Arbitrum chain, it uses ArbGas.getCurrentTxL1GasFees to get the fees.
   * @notice On Arbitrum, the provided calldata is not used to calculate the fees.
   * @notice On Optimism, the provided calldata is passed to the OVM_GasPriceOracle predeploy
   * @notice and getL1Fee is called to get the fees.
   */
  function _getCurrentTxL1GasFees(bytes memory txCallData) internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      return ARBGAS.getCurrentTxL1GasFees();
    } else if (_isOptimismChainId(chainid)) {
      return OVM_GASPRICEORACLE.getL1Fee(bytes.concat(txCallData, L1_FEE_DATA_PADDING));
    }
    return 0;
  }

  /**
   * @notice Returns the gas cost in wei of calldataSizeBytes of calldata being posted
   * @notice to L1.
   */
  function _getL1CalldataGasCost(uint256 calldataSizeBytes) internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      (, uint256 l1PricePerByte, , , , ) = ARBGAS.getPricesInWei();
      // see https://developer.arbitrum.io/devs-how-tos/how-to-estimate-gas#where-do-we-get-all-this-information-from
      // for the justification behind the 140 number.
      return l1PricePerByte * (calldataSizeBytes + 140);
    } else if (_isOptimismChainId(chainid)) {
      return _calculateOptimismL1DataFee(calldataSizeBytes);
    }
    return 0;
  }

  /**
   * @notice Return true if and only if the provided chain ID is an Arbitrum chain ID.
   */
  function _isArbitrumChainId(uint256 chainId) internal pure returns (bool) {
    return
      chainId == ARB_MAINNET_CHAIN_ID ||
      chainId == ARB_GOERLI_TESTNET_CHAIN_ID ||
      chainId == ARB_SEPOLIA_TESTNET_CHAIN_ID;
  }

  /**
   * @notice Return true if and only if the provided chain ID is an Optimism chain ID.
   * @notice Note that optimism chain id's are also OP stack chain id's.
   */
  function _isOptimismChainId(uint256 chainId) internal pure returns (bool) {
    return
      chainId == OP_MAINNET_CHAIN_ID ||
      chainId == OP_GOERLI_CHAIN_ID ||
      chainId == OP_SEPOLIA_CHAIN_ID ||
      chainId == BASE_MAINNET_CHAIN_ID ||
      chainId == BASE_GOERLI_CHAIN_ID;
  }

  function _calculateOptimismL1DataFee(uint256 calldataSizeBytes) internal view returns (uint256) {
    // from: https://community.optimism.io/docs/developers/build/transaction-fees/#the-l1-data-fee
    // l1_data_fee = l1_gas_price * (tx_data_gas + fixed_overhead) * dynamic_overhead
    // tx_data_gas = count_zero_bytes(tx_data) * 4 + count_non_zero_bytes(tx_data) * 16
    // note we conservatively assume all non-zero bytes.
    uint256 l1BaseFeeWei = OVM_GASPRICEORACLE.l1BaseFee();
    uint256 numZeroBytes = 0;
    uint256 numNonzeroBytes = calldataSizeBytes - numZeroBytes;
    uint256 txDataGas = numZeroBytes * 4 + numNonzeroBytes * 16;
    uint256 fixedOverhead = OVM_GASPRICEORACLE.overhead();

    // The scalar is some value like 0.684, but is represented as
    // that times 10 ^ number of scalar decimals.
    // e.g scalar = 0.684 * 10^6
    // The divisor is used to divide that and have a net result of the true scalar.
    uint256 scalar = OVM_GASPRICEORACLE.scalar();
    uint256 scalarDecimals = OVM_GASPRICEORACLE.decimals();
    uint256 divisor = 10 ** scalarDecimals;

    uint256 l1DataFee = (l1BaseFeeWei * (txDataGas + fixedOverhead) * scalar) / divisor;
    return l1DataFee;
  }
}

// lib/chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinatorV2Plus.
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBaseV2Plus, and can
 * @dev initialize VRFConsumerBaseV2Plus's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumerV2Plus is VRFConsumerBaseV2Plus {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _subOwner)
 * @dev       VRFConsumerBaseV2Plus(_vrfCoordinator, _subOwner) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create a subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords, extraArgs),
 * @dev see (IVRFCoordinatorV2Plus for a description of the arguments).
 *
 * @dev Once the VRFCoordinatorV2Plus has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBaseV2Plus.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  // s_vrfCoordinator should be used by consumers to make requests to vrfCoordinator
  // so that coordinator reference is updated after migration
  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2Plus expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
    if (msg.sender != address(s_vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(msg.sender, address(s_vrfCoordinator));
    }
    fulfillRandomWords(requestId, randomWords);
  }

  /**
   * @inheritdoc IVRFMigratableConsumerV2Plus
   */
  function setCoordinator(address _vrfCoordinator) external override onlyOwnerOrCoordinator {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);

    emit CoordinatorSet(_vrfCoordinator);
  }

  modifier onlyOwnerOrCoordinator() {
    if (msg.sender != owner() && msg.sender != address(s_vrfCoordinator)) {
      revert OnlyOwnerOrCoordinator(msg.sender, owner(), address(s_vrfCoordinator));
    }
    _;
  }
}

// lib/chainlink/contracts/src/v0.8/vrf/dev/SubscriptionAPI.sol

abstract contract SubscriptionAPI is ConfirmedOwner, IERC677Receiver, IVRFSubscriptionV2Plus {
  using EnumerableSet for EnumerableSet.UintSet;

  /// @dev may not be provided upon construction on some chains due to lack of availability
  LinkTokenInterface public LINK;
  /// @dev may not be provided upon construction on some chains due to lack of availability
  AggregatorV3Interface public LINK_NATIVE_FEED;

  // We need to maintain a list of consuming addresses.
  // This bound ensures we are able to loop over them as needed.
  // Should a user require more consumers, they can use multiple subscriptions.
  uint16 public constant MAX_CONSUMERS = 100;
  error TooManyConsumers();
  error InsufficientBalance();
  error InvalidConsumer(uint256 subId, address consumer);
  error InvalidSubscription();
  error OnlyCallableFromLink();
  error InvalidCalldata();
  error MustBeSubOwner(address owner);
  error PendingRequestExists();
  error MustBeRequestedOwner(address proposedOwner);
  error BalanceInvariantViolated(uint256 internalBalance, uint256 externalBalance); // Should never happen
  event FundsRecovered(address to, uint256 amount);
  event NativeFundsRecovered(address to, uint256 amount);
  error LinkAlreadySet();
  error FailedToSendNative();
  error FailedToTransferLink();
  error IndexOutOfRange();
  error LinkNotSet();

  // We use the subscription struct (1 word)
  // at fulfillment time.
  struct Subscription {
    // There are only 1e9*1e18 = 1e27 juels in existence, so the balance can fit in uint96 (2^96 ~ 7e28)
    uint96 balance; // Common link balance used for all consumer requests.
    // a uint96 is large enough to hold around ~8e28 wei, or 80 billion ether.
    // That should be enough to cover most (if not all) subscriptions.
    uint96 nativeBalance; // Common native balance used for all consumer requests.
    uint64 reqCount;
  }
  // We use the config for the mgmt APIs
  struct SubscriptionConfig {
    address owner; // Owner can fund/withdraw/cancel the sub.
    address requestedOwner; // For safely transferring sub ownership.
    // Maintains the list of keys in s_consumers.
    // We do this for 2 reasons:
    // 1. To be able to clean up all keys from s_consumers when canceling a subscription.
    // 2. To be able to return the list of all consumers in getSubscription.
    // Note that we need the s_consumers map to be able to directly check if a
    // consumer is valid without reading all the consumers from storage.
    address[] consumers;
  }
  struct ConsumerConfig {
    bool active;
    uint64 nonce;
    uint64 pendingReqCount;
  }
  // Note a nonce of 0 indicates the consumer is not assigned to that subscription.
  mapping(address => mapping(uint256 => ConsumerConfig)) /* consumerAddress */ /* subId */ /* consumerConfig */
    internal s_consumers;
  mapping(uint256 => SubscriptionConfig) /* subId */ /* subscriptionConfig */ internal s_subscriptionConfigs;
  mapping(uint256 => Subscription) /* subId */ /* subscription */ internal s_subscriptions;
  // subscription nonce used to construct subId. Rises monotonically
  uint64 public s_currentSubNonce;
  // track all subscription id's that were created by this contract
  // note: access should be through the getActiveSubscriptionIds() view function
  // which takes a starting index and a max number to fetch in order to allow
  // "pagination" of the subscription ids. in the event a very large number of
  // subscription id's are stored in this set, they cannot be retrieved in a
  // single RPC call without violating various size limits.
  EnumerableSet.UintSet internal s_subIds;
  // s_totalBalance tracks the total link sent to/from
  // this contract through onTokenTransfer, cancelSubscription and oracleWithdraw.
  // A discrepancy with this contract's link balance indicates someone
  // sent tokens using transfer and so we may need to use recoverFunds.
  uint96 public s_totalBalance;
  // s_totalNativeBalance tracks the total native sent to/from
  // this contract through fundSubscription, cancelSubscription and oracleWithdrawNative.
  // A discrepancy with this contract's native balance indicates someone
  // sent native using transfer and so we may need to use recoverNativeFunds.
  uint96 public s_totalNativeBalance;
  uint96 internal s_withdrawableTokens;
  uint96 internal s_withdrawableNative;

  event SubscriptionCreated(uint256 indexed subId, address owner);
  event SubscriptionFunded(uint256 indexed subId, uint256 oldBalance, uint256 newBalance);
  event SubscriptionFundedWithNative(uint256 indexed subId, uint256 oldNativeBalance, uint256 newNativeBalance);
  event SubscriptionConsumerAdded(uint256 indexed subId, address consumer);
  event SubscriptionConsumerRemoved(uint256 indexed subId, address consumer);
  event SubscriptionCanceled(uint256 indexed subId, address to, uint256 amountLink, uint256 amountNative);
  event SubscriptionOwnerTransferRequested(uint256 indexed subId, address from, address to);
  event SubscriptionOwnerTransferred(uint256 indexed subId, address from, address to);

  struct Config {
    uint16 minimumRequestConfirmations;
    uint32 maxGasLimit;
    // Reentrancy protection.
    bool reentrancyLock;
    // stalenessSeconds is how long before we consider the feed price to be stale
    // and fallback to fallbackWeiPerUnitLink.
    uint32 stalenessSeconds;
    // Gas to cover oracle payment after we calculate the payment.
    // We make it configurable in case those operations are repriced.
    // The recommended number is below, though it may vary slightly
    // if certain chains do not implement certain EIP's.
    // 21000 + // base cost of the transaction
    // 100 + 5000 + // warm subscription balance read and update. See https://eips.ethereum.org/EIPS/eip-2929
    // 2*2100 + 5000 - // cold read oracle address and oracle balance and first time oracle balance update, note first time will be 20k, but 5k subsequently
    // 4800 + // request delete refund (refunds happen after execution), note pre-london fork was 15k. See https://eips.ethereum.org/EIPS/eip-3529
    // 6685 + // Positive static costs of argument encoding etc. note that it varies by +/- x*12 for every x bytes of non-zero data in the proof.
    // Total: 37,185 gas.
    uint32 gasAfterPaymentCalculation;
    // Flat fee charged per fulfillment in millionths of native.
    // So fee range is [0, 2^32/10^6].
    uint32 fulfillmentFlatFeeNativePPM;
    // Discount relative to fulfillmentFlatFeeNativePPM for link payment in millionths of native
    // Should not exceed fulfillmentFlatFeeNativePPM
    // So fee range is [0, 2^32/10^6].
    uint32 fulfillmentFlatFeeLinkDiscountPPM;
    // nativePremiumPercentage is the percentage of the total gas costs that is added to the final premium for native payment
    // nativePremiumPercentage = 10 means 10% of the total gas costs is added. only integral percentage is allowed
    uint8 nativePremiumPercentage;
    // linkPremiumPercentage is the percentage of total gas costs that is added to the final premium for link payment
    // linkPremiumPercentage = 10 means 10% of the total gas costs is added. only integral percentage is allowed
    uint8 linkPremiumPercentage;
  }
  Config public s_config;

  error Reentrant();
  modifier nonReentrant() {
    _nonReentrant();
    _;
  }

  function _nonReentrant() internal view {
    if (s_config.reentrancyLock) {
      revert Reentrant();
    }
  }

  constructor() ConfirmedOwner(msg.sender) {}

  /**
   * @notice set the LINK token contract and link native feed to be
   * used by this coordinator
   * @param link - address of link token
   * @param linkNativeFeed address of the link native feed
   */
  function setLINKAndLINKNativeFeed(address link, address linkNativeFeed) external onlyOwner {
    // Disallow re-setting link token because the logic wouldn't really make sense
    if (address(LINK) != address(0)) {
      revert LinkAlreadySet();
    }
    LINK = LinkTokenInterface(link);
    LINK_NATIVE_FEED = AggregatorV3Interface(linkNativeFeed);
  }

  /**
   * @notice Owner cancel subscription, sends remaining link directly to the subscription owner.
   * @param subId subscription id
   * @dev notably can be called even if there are pending requests, outstanding ones may fail onchain
   */
  function ownerCancelSubscription(uint256 subId) external onlyOwner {
    address subOwner = s_subscriptionConfigs[subId].owner;
    if (subOwner == address(0)) {
      revert InvalidSubscription();
    }
    _cancelSubscriptionHelper(subId, subOwner);
  }

  /**
   * @notice Recover link sent with transfer instead of transferAndCall.
   * @param to address to send link to
   */
  function recoverFunds(address to) external onlyOwner {
    // If LINK is not set, we cannot recover funds.
    // It is possible that this coordinator address was funded with LINK
    // by accident by a user but the LINK token needs to be set first
    // before we can recover it.
    if (address(LINK) == address(0)) {
      revert LinkNotSet();
    }

    uint256 externalBalance = LINK.balanceOf(address(this));
    uint256 internalBalance = uint256(s_totalBalance);
    if (internalBalance > externalBalance) {
      revert BalanceInvariantViolated(internalBalance, externalBalance);
    }
    if (internalBalance < externalBalance) {
      uint256 amount = externalBalance - internalBalance;
      if (!LINK.transfer(to, amount)) {
        revert FailedToTransferLink();
      }
      emit FundsRecovered(to, amount);
    }
    // If the balances are equal, nothing to be done.
  }

  /**
   * @notice Recover native sent with transfer/call/send instead of fundSubscription.
   * @param to address to send native to
   */
  function recoverNativeFunds(address payable to) external onlyOwner {
    uint256 externalBalance = address(this).balance;
    uint256 internalBalance = uint256(s_totalNativeBalance);
    if (internalBalance > externalBalance) {
      revert BalanceInvariantViolated(internalBalance, externalBalance);
    }
    if (internalBalance < externalBalance) {
      uint256 amount = externalBalance - internalBalance;
      (bool sent, ) = to.call{value: amount}("");
      if (!sent) {
        revert FailedToSendNative();
      }
      emit NativeFundsRecovered(to, amount);
    }
    // If the balances are equal, nothing to be done.
  }

  /*
   * @notice withdraw LINK earned through fulfilling requests
   * @param recipient where to send the funds
   * @param amount amount to withdraw
   */
  function withdraw(address recipient) external nonReentrant onlyOwner {
    if (address(LINK) == address(0)) {
      revert LinkNotSet();
    }
    if (s_withdrawableTokens == 0) {
      revert InsufficientBalance();
    }
    uint96 amount = s_withdrawableTokens;
    s_withdrawableTokens -= amount;
    s_totalBalance -= amount;
    if (!LINK.transfer(recipient, amount)) {
      revert InsufficientBalance();
    }
  }

  /*
   * @notice withdraw native earned through fulfilling requests
   * @param recipient where to send the funds
   * @param amount amount to withdraw
   */
  function withdrawNative(address payable recipient) external nonReentrant onlyOwner {
    if (s_withdrawableNative == 0) {
      revert InsufficientBalance();
    }
    // Prevent re-entrancy by updating state before transfer.
    uint96 amount = s_withdrawableNative;
    s_withdrawableNative -= amount;
    s_totalNativeBalance -= amount;
    (bool sent, ) = recipient.call{value: amount}("");
    if (!sent) {
      revert FailedToSendNative();
    }
  }

  function onTokenTransfer(address /* sender */, uint256 amount, bytes calldata data) external override nonReentrant {
    if (msg.sender != address(LINK)) {
      revert OnlyCallableFromLink();
    }
    if (data.length != 32) {
      revert InvalidCalldata();
    }
    uint256 subId = abi.decode(data, (uint256));
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    // We do not check that the sender is the subscription owner,
    // anyone can fund a subscription.
    uint256 oldBalance = s_subscriptions[subId].balance;
    s_subscriptions[subId].balance += uint96(amount);
    s_totalBalance += uint96(amount);
    emit SubscriptionFunded(subId, oldBalance, oldBalance + amount);
  }

  /**
   * @inheritdoc IVRFSubscriptionV2Plus
   */
  function fundSubscriptionWithNative(uint256 subId) external payable override nonReentrant {
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    // We do not check that the msg.sender is the subscription owner,
    // anyone can fund a subscription.
    // We also do not check that msg.value > 0, since that's just a no-op
    // and would be a waste of gas on the caller's part.
    uint256 oldNativeBalance = s_subscriptions[subId].nativeBalance;
    s_subscriptions[subId].nativeBalance += uint96(msg.value);
    s_totalNativeBalance += uint96(msg.value);
    emit SubscriptionFundedWithNative(subId, oldNativeBalance, oldNativeBalance + msg.value);
  }

  /**
   * @inheritdoc IVRFSubscriptionV2Plus
   */
  function getSubscription(
    uint256 subId
  )
    public
    view
    override
    returns (uint96 balance, uint96 nativeBalance, uint64 reqCount, address subOwner, address[] memory consumers)
  {
    subOwner = s_subscriptionConfigs[subId].owner;
    if (subOwner == address(0)) {
      revert InvalidSubscription();
    }
    return (
      s_subscriptions[subId].balance,
      s_subscriptions[subId].nativeBalance,
      s_subscriptions[subId].reqCount,
      subOwner,
      s_subscriptionConfigs[subId].consumers
    );
  }

  /**
   * @inheritdoc IVRFSubscriptionV2Plus
   */
  function getActiveSubscriptionIds(
    uint256 startIndex,
    uint256 maxCount
  ) external view override returns (uint256[] memory ids) {
    uint256 numSubs = s_subIds.length();
    if (startIndex >= numSubs) revert IndexOutOfRange();
    uint256 endIndex = startIndex + maxCount;
    endIndex = endIndex > numSubs || maxCount == 0 ? numSubs : endIndex;
    uint256 idsLength = endIndex - startIndex;
    ids = new uint256[](idsLength);
    for (uint256 idx = 0; idx < idsLength; ++idx) {
      ids[idx] = s_subIds.at(idx + startIndex);
    }
    return ids;
  }

  /**
   * @inheritdoc IVRFSubscriptionV2Plus
   */
  function createSubscription() external override nonReentrant returns (uint256 subId) {
    // Generate a subscription id that is globally unique.
    uint64 currentSubNonce = s_currentSubNonce;
    subId = uint256(
      keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1), address(this), currentSubNonce))
    );
    // Increment the subscription nonce counter.
    s_currentSubNonce = currentSubNonce + 1;
    // Initialize storage variables.
    address[] memory consumers = new address[](0);
    s_subscriptions[subId] = Subscription({balance: 0, nativeBalance: 0, reqCount: 0});
    s_subscriptionConfigs[subId] = SubscriptionConfig({
      owner: msg.sender,
      requestedOwner: address(0),
      consumers: consumers
    });
    // Update the s_subIds set, which tracks all subscription ids created in this contract.
    s_subIds.add(subId);

    emit SubscriptionCreated(subId, msg.sender);
    return subId;
  }

  /**
   * @inheritdoc IVRFSubscriptionV2Plus
   */
  function requestSubscriptionOwnerTransfer(
    uint256 subId,
    address newOwner
  ) external override onlySubOwner(subId) nonReentrant {
    // Proposing to address(0) would never be claimable so don't need to check.
    SubscriptionConfig storage subscriptionConfig = s_subscriptionConfigs[subId];
    if (subscriptionConfig.requestedOwner != newOwner) {
      subscriptionConfig.requestedOwner = newOwner;
      emit SubscriptionOwnerTransferRequested(subId, msg.sender, newOwner);
    }
  }

  /**
   * @inheritdoc IVRFSubscriptionV2Plus
   */
  function acceptSubscriptionOwnerTransfer(uint256 subId) external override nonReentrant {
    address oldOwner = s_subscriptionConfigs[subId].owner;
    if (oldOwner == address(0)) {
      revert InvalidSubscription();
    }
    if (s_subscriptionConfigs[subId].requestedOwner != msg.sender) {
      revert MustBeRequestedOwner(s_subscriptionConfigs[subId].requestedOwner);
    }
    s_subscriptionConfigs[subId].owner = msg.sender;
    s_subscriptionConfigs[subId].requestedOwner = address(0);
    emit SubscriptionOwnerTransferred(subId, oldOwner, msg.sender);
  }

  /**
   * @inheritdoc IVRFSubscriptionV2Plus
   */
  function addConsumer(uint256 subId, address consumer) external override onlySubOwner(subId) nonReentrant {
    ConsumerConfig storage consumerConfig = s_consumers[consumer][subId];
    if (consumerConfig.active) {
      // Idempotence - do nothing if already added.
      // Ensures uniqueness in s_subscriptions[subId].consumers.
      return;
    }
    // Already maxed, cannot add any more consumers.
    address[] storage consumers = s_subscriptionConfigs[subId].consumers;
    if (consumers.length == MAX_CONSUMERS) {
      revert TooManyConsumers();
    }
    // consumerConfig.nonce is 0 if the consumer had never sent a request to this subscription
    // otherwise, consumerConfig.nonce is non-zero
    // in both cases, use consumerConfig.nonce as is and set active status to true
    consumerConfig.active = true;
    consumers.push(consumer);

    emit SubscriptionConsumerAdded(subId, consumer);
  }

  function _deleteSubscription(uint256 subId) internal returns (uint96 balance, uint96 nativeBalance) {
    address[] storage consumers = s_subscriptionConfigs[subId].consumers;
    balance = s_subscriptions[subId].balance;
    nativeBalance = s_subscriptions[subId].nativeBalance;
    // Note bounded by MAX_CONSUMERS;
    // If no consumers, does nothing.
    uint256 consumersLength = consumers.length;
    for (uint256 i = 0; i < consumersLength; ++i) {
      delete s_consumers[consumers[i]][subId];
    }
    delete s_subscriptionConfigs[subId];
    delete s_subscriptions[subId];
    s_subIds.remove(subId);
    if (balance != 0) {
      s_totalBalance -= balance;
    }
    if (nativeBalance != 0) {
      s_totalNativeBalance -= nativeBalance;
    }
    return (balance, nativeBalance);
  }

  function _cancelSubscriptionHelper(uint256 subId, address to) internal {
    (uint96 balance, uint96 nativeBalance) = _deleteSubscription(subId);

    // Only withdraw LINK if the token is active and there is a balance.
    if (address(LINK) != address(0) && balance != 0) {
      if (!LINK.transfer(to, uint256(balance))) {
        revert InsufficientBalance();
      }
    }

    // send native to the "to" address using call
    (bool success, ) = to.call{value: uint256(nativeBalance)}("");
    if (!success) {
      revert FailedToSendNative();
    }
    emit SubscriptionCanceled(subId, to, balance, nativeBalance);
  }

  modifier onlySubOwner(uint256 subId) {
    _onlySubOwner(subId);
    _;
  }

  function _onlySubOwner(uint256 subId) internal view {
    address subOwner = s_subscriptionConfigs[subId].owner;
    if (subOwner == address(0)) {
      revert InvalidSubscription();
    }
    if (msg.sender != subOwner) {
      revert MustBeSubOwner(subOwner);
    }
  }
}

// lib/chainlink/contracts/src/v0.8/vrf/dev/VRFCoordinatorV2_5.sol

// solhint-disable-next-line no-unused-import

// solhint-disable-next-line contract-name-camelcase
contract VRFCoordinatorV2_5 is VRF, SubscriptionAPI, IVRFCoordinatorV2Plus {
  /// @dev should always be available
  // solhint-disable-next-line chainlink-solidity/prefix-immutable-variables-with-i
  BlockhashStoreInterface public immutable BLOCKHASH_STORE;

  // Set this maximum to 200 to give us a 56 block window to fulfill
  // the request before requiring the block hash feeder.
  uint16 public constant MAX_REQUEST_CONFIRMATIONS = 200;
  uint32 public constant MAX_NUM_WORDS = 500;
  // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
  // and some arithmetic operations.
  uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
  // upper bound limit for premium percentages to make sure fee calculations don't overflow
  uint8 private constant PREMIUM_PERCENTAGE_MAX = 155;
  error InvalidRequestConfirmations(uint16 have, uint16 min, uint16 max);
  error GasLimitTooBig(uint32 have, uint32 want);
  error NumWordsTooBig(uint32 have, uint32 want);
  error MsgDataTooBig(uint256 have, uint32 max);
  error ProvingKeyAlreadyRegistered(bytes32 keyHash);
  error NoSuchProvingKey(bytes32 keyHash);
  error InvalidLinkWeiPrice(int256 linkWei);
  error LinkDiscountTooHigh(uint32 flatFeeLinkDiscountPPM, uint32 flatFeeNativePPM);
  error InvalidPremiumPercentage(uint8 premiumPercentage, uint8 max);
  error NoCorrespondingRequest();
  error IncorrectCommitment();
  error BlockhashNotInStore(uint256 blockNum);
  error PaymentTooLarge();
  error InvalidExtraArgsTag();
  error GasPriceExceeded(uint256 gasPrice, uint256 maxGas);

  struct ProvingKey {
    bool exists; // proving key exists
    uint64 maxGas; // gas lane max gas price for fulfilling requests
  }

  mapping(bytes32 => ProvingKey) /* keyHash */ /* provingKey */ public s_provingKeys;
  bytes32[] public s_provingKeyHashes;
  mapping(uint256 => bytes32) /* requestID */ /* commitment */ public s_requestCommitments;
  event ProvingKeyRegistered(bytes32 keyHash, uint64 maxGas);
  event ProvingKeyDeregistered(bytes32 keyHash, uint64 maxGas);

  event RandomWordsRequested(
    bytes32 indexed keyHash,
    uint256 requestId,
    uint256 preSeed,
    uint256 indexed subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords,
    bytes extraArgs,
    address indexed sender
  );

  event RandomWordsFulfilled(
    uint256 indexed requestId,
    uint256 outputSeed,
    uint256 indexed subId,
    uint96 payment,
    bool nativePayment,
    bool success,
    bool onlyPremium
  );

  int256 public s_fallbackWeiPerUnitLink;

  event ConfigSet(
    uint16 minimumRequestConfirmations,
    uint32 maxGasLimit,
    uint32 stalenessSeconds,
    uint32 gasAfterPaymentCalculation,
    int256 fallbackWeiPerUnitLink,
    uint32 fulfillmentFlatFeeNativePPM,
    uint32 fulfillmentFlatFeeLinkDiscountPPM,
    uint8 nativePremiumPercentage,
    uint8 linkPremiumPercentage
  );

  event FallbackWeiPerUnitLinkUsed(uint256 requestId, int256 fallbackWeiPerUnitLink);

  constructor(address blockhashStore) SubscriptionAPI() {
    BLOCKHASH_STORE = BlockhashStoreInterface(blockhashStore);
  }

  /**
   * @notice Registers a proving key to.
   * @param publicProvingKey key that oracle can use to submit vrf fulfillments
   */
  function registerProvingKey(uint256[2] calldata publicProvingKey, uint64 maxGas) external onlyOwner {
    bytes32 kh = hashOfKey(publicProvingKey);
    if (s_provingKeys[kh].exists) {
      revert ProvingKeyAlreadyRegistered(kh);
    }
    s_provingKeys[kh] = ProvingKey({exists: true, maxGas: maxGas});
    s_provingKeyHashes.push(kh);
    emit ProvingKeyRegistered(kh, maxGas);
  }

  /**
   * @notice Deregisters a proving key.
   * @param publicProvingKey key that oracle can use to submit vrf fulfillments
   */
  function deregisterProvingKey(uint256[2] calldata publicProvingKey) external onlyOwner {
    bytes32 kh = hashOfKey(publicProvingKey);
    ProvingKey memory key = s_provingKeys[kh];
    if (!key.exists) {
      revert NoSuchProvingKey(kh);
    }
    delete s_provingKeys[kh];
    uint256 s_provingKeyHashesLength = s_provingKeyHashes.length;
    for (uint256 i = 0; i < s_provingKeyHashesLength; ++i) {
      if (s_provingKeyHashes[i] == kh) {
        // Copy last element and overwrite kh to be deleted with it
        s_provingKeyHashes[i] = s_provingKeyHashes[s_provingKeyHashesLength - 1];
        s_provingKeyHashes.pop();
        break;
      }
    }
    emit ProvingKeyDeregistered(kh, key.maxGas);
  }

  /**
   * @notice Returns the proving key hash key associated with this public key
   * @param publicKey the key to return the hash of
   */
  function hashOfKey(uint256[2] memory publicKey) public pure returns (bytes32) {
    return keccak256(abi.encode(publicKey));
  }

  /**
   * @notice Sets the configuration of the vrfv2 coordinator
   * @param minimumRequestConfirmations global min for request confirmations
   * @param maxGasLimit global max for request gas limit
   * @param stalenessSeconds if the native/link feed is more stale then this, use the fallback price
   * @param gasAfterPaymentCalculation gas used in doing accounting after completing the gas measurement
   * @param fallbackWeiPerUnitLink fallback native/link price in the case of a stale feed
   * @param fulfillmentFlatFeeNativePPM flat fee in native for native payment
   * @param fulfillmentFlatFeeLinkDiscountPPM flat fee discount for link payment in native
   * @param nativePremiumPercentage native premium percentage
   * @param linkPremiumPercentage link premium percentage
   */
  function setConfig(
    uint16 minimumRequestConfirmations,
    uint32 maxGasLimit,
    uint32 stalenessSeconds,
    uint32 gasAfterPaymentCalculation,
    int256 fallbackWeiPerUnitLink,
    uint32 fulfillmentFlatFeeNativePPM,
    uint32 fulfillmentFlatFeeLinkDiscountPPM,
    uint8 nativePremiumPercentage,
    uint8 linkPremiumPercentage
  ) external onlyOwner {
    if (minimumRequestConfirmations > MAX_REQUEST_CONFIRMATIONS) {
      revert InvalidRequestConfirmations(
        minimumRequestConfirmations,
        minimumRequestConfirmations,
        MAX_REQUEST_CONFIRMATIONS
      );
    }
    if (fallbackWeiPerUnitLink <= 0) {
      revert InvalidLinkWeiPrice(fallbackWeiPerUnitLink);
    }
    if (fulfillmentFlatFeeLinkDiscountPPM > fulfillmentFlatFeeNativePPM) {
      revert LinkDiscountTooHigh(fulfillmentFlatFeeLinkDiscountPPM, fulfillmentFlatFeeNativePPM);
    }
    if (nativePremiumPercentage > PREMIUM_PERCENTAGE_MAX) {
      revert InvalidPremiumPercentage(nativePremiumPercentage, PREMIUM_PERCENTAGE_MAX);
    }
    if (linkPremiumPercentage > PREMIUM_PERCENTAGE_MAX) {
      revert InvalidPremiumPercentage(linkPremiumPercentage, PREMIUM_PERCENTAGE_MAX);
    }
    s_config = Config({
      minimumRequestConfirmations: minimumRequestConfirmations,
      maxGasLimit: maxGasLimit,
      stalenessSeconds: stalenessSeconds,
      gasAfterPaymentCalculation: gasAfterPaymentCalculation,
      reentrancyLock: false,
      fulfillmentFlatFeeNativePPM: fulfillmentFlatFeeNativePPM,
      fulfillmentFlatFeeLinkDiscountPPM: fulfillmentFlatFeeLinkDiscountPPM,
      nativePremiumPercentage: nativePremiumPercentage,
      linkPremiumPercentage: linkPremiumPercentage
    });
    s_fallbackWeiPerUnitLink = fallbackWeiPerUnitLink;
    emit ConfigSet(
      minimumRequestConfirmations,
      maxGasLimit,
      stalenessSeconds,
      gasAfterPaymentCalculation,
      fallbackWeiPerUnitLink,
      fulfillmentFlatFeeNativePPM,
      fulfillmentFlatFeeLinkDiscountPPM,
      nativePremiumPercentage,
      linkPremiumPercentage
    );
  }

  /// @dev Convert the extra args bytes into a struct
  /// @param extraArgs The extra args bytes
  /// @return The extra args struct
  function _fromBytes(bytes calldata extraArgs) internal pure returns (VRFV2PlusClient.ExtraArgsV1 memory) {
    if (extraArgs.length == 0) {
      return VRFV2PlusClient.ExtraArgsV1({nativePayment: false});
    }
    if (bytes4(extraArgs) != VRFV2PlusClient.EXTRA_ARGS_V1_TAG) revert InvalidExtraArgsTag();
    return abi.decode(extraArgs[4:], (VRFV2PlusClient.ExtraArgsV1));
  }

  /**
   * @notice Request a set of random words.
   * @param req - a struct containing following fiels for randomness request:
   * keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * requestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * extraArgs - Encoded extra arguments that has a boolean flag for whether payment
   * should be made in native or LINK. Payment in LINK is only available if the LINK token is available to this contract.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    VRFV2PlusClient.RandomWordsRequest calldata req
  ) external override nonReentrant returns (uint256 requestId) {
    // Input validation using the subscription storage.
    uint256 subId = req.subId;
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    // Its important to ensure that the consumer is in fact who they say they
    // are, otherwise they could use someone else's subscription balance.
    mapping(uint256 => ConsumerConfig) storage consumerConfigs = s_consumers[msg.sender];
    ConsumerConfig memory consumerConfig = consumerConfigs[subId];
    if (!consumerConfig.active) {
      revert InvalidConsumer(subId, msg.sender);
    }
    // Input validation using the config storage word.
    if (
      req.requestConfirmations < s_config.minimumRequestConfirmations ||
      req.requestConfirmations > MAX_REQUEST_CONFIRMATIONS
    ) {
      revert InvalidRequestConfirmations(
        req.requestConfirmations,
        s_config.minimumRequestConfirmations,
        MAX_REQUEST_CONFIRMATIONS
      );
    }
    // No lower bound on the requested gas limit. A user could request 0
    // and they would simply be billed for the proof verification and wouldn't be
    // able to do anything with the random value.
    if (req.callbackGasLimit > s_config.maxGasLimit) {
      revert GasLimitTooBig(req.callbackGasLimit, s_config.maxGasLimit);
    }
    if (req.numWords > MAX_NUM_WORDS) {
      revert NumWordsTooBig(req.numWords, MAX_NUM_WORDS);
    }

    // Note we do not check whether the keyHash is valid to save gas.
    // The consequence for users is that they can send requests
    // for invalid keyHashes which will simply not be fulfilled.
    ++consumerConfig.nonce;
    ++consumerConfig.pendingReqCount;
    uint256 preSeed;
    (requestId, preSeed) = _computeRequestId(req.keyHash, msg.sender, subId, consumerConfig.nonce);

    bytes memory extraArgsBytes = VRFV2PlusClient._argsToBytes(_fromBytes(req.extraArgs));
    s_requestCommitments[requestId] = keccak256(
      abi.encode(
        requestId,
        ChainSpecificUtil._getBlockNumber(),
        subId,
        req.callbackGasLimit,
        req.numWords,
        msg.sender,
        extraArgsBytes
      )
    );
    emit RandomWordsRequested(
      req.keyHash,
      requestId,
      preSeed,
      subId,
      req.requestConfirmations,
      req.callbackGasLimit,
      req.numWords,
      extraArgsBytes,
      msg.sender
    );
    consumerConfigs[subId] = consumerConfig;

    return requestId;
  }

  function _computeRequestId(
    bytes32 keyHash,
    address sender,
    uint256 subId,
    uint64 nonce
  ) internal pure returns (uint256, uint256) {
    uint256 preSeed = uint256(keccak256(abi.encode(keyHash, sender, subId, nonce)));
    return (uint256(keccak256(abi.encode(keyHash, preSeed))), preSeed);
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available.
   */
  function _callWithExactGas(uint256 gasAmount, address target, bytes memory data) private returns (bool success) {
    assembly {
      let g := gas()
      // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
      // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
      // We want to ensure that we revert if gasAmount >  63//64*gas available
      // as we do not want to provide them with less, however that check itself costs
      // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
      // to revert if gasAmount >  63//64*gas available.
      if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
        revert(0, 0)
      }
      g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  struct Output {
    ProvingKey provingKey;
    uint256 requestId;
    uint256 randomness;
  }

  function _getRandomnessFromProof(
    Proof memory proof,
    VRFTypes.RequestCommitmentV2Plus memory rc
  ) internal view returns (Output memory) {
    bytes32 keyHash = hashOfKey(proof.pk);
    ProvingKey memory key = s_provingKeys[keyHash];
    // Only registered proving keys are permitted.
    if (!key.exists) {
      revert NoSuchProvingKey(keyHash);
    }
    uint256 requestId = uint256(keccak256(abi.encode(keyHash, proof.seed)));
    bytes32 commitment = s_requestCommitments[requestId];
    if (commitment == 0) {
      revert NoCorrespondingRequest();
    }
    if (
      commitment !=
      keccak256(abi.encode(requestId, rc.blockNum, rc.subId, rc.callbackGasLimit, rc.numWords, rc.sender, rc.extraArgs))
    ) {
      revert IncorrectCommitment();
    }

    bytes32 blockHash = ChainSpecificUtil._getBlockhash(rc.blockNum);
    if (blockHash == bytes32(0)) {
      blockHash = BLOCKHASH_STORE.getBlockhash(rc.blockNum);
      if (blockHash == bytes32(0)) {
        revert BlockhashNotInStore(rc.blockNum);
      }
    }

    // The seed actually used by the VRF machinery, mixing in the blockhash
    uint256 actualSeed = uint256(keccak256(abi.encodePacked(proof.seed, blockHash)));
    uint256 randomness = VRF._randomValueFromVRFProof(proof, actualSeed); // Reverts on failure
    return Output(key, requestId, randomness);
  }

  function _getValidatedGasPrice(bool onlyPremium, uint64 gasLaneMaxGas) internal view returns (uint256 gasPrice) {
    if (tx.gasprice > gasLaneMaxGas) {
      if (onlyPremium) {
        // if only the premium amount needs to be billed, then the premium is capped by the gas lane max
        return uint256(gasLaneMaxGas);
      } else {
        // Ensure gas price does not exceed the gas lane max gas price
        revert GasPriceExceeded(tx.gasprice, gasLaneMaxGas);
      }
    }
    return tx.gasprice;
  }

  function _deliverRandomness(
    uint256 requestId,
    VRFTypes.RequestCommitmentV2Plus memory rc,
    uint256[] memory randomWords
  ) internal returns (bool success) {
    VRFConsumerBaseV2Plus v;
    bytes memory resp = abi.encodeWithSelector(v.rawFulfillRandomWords.selector, requestId, randomWords);
    // Call with explicitly the amount of callback gas requested
    // Important to not let them exhaust the gas budget and avoid oracle payment.
    // Do not allow any non-view/non-pure coordinator functions to be called
    // during the consumers callback code via reentrancyLock.
    // Note that _callWithExactGas will revert if we do not have sufficient gas
    // to give the callee their requested amount.
    s_config.reentrancyLock = true;
    success = _callWithExactGas(rc.callbackGasLimit, rc.sender, resp);
    s_config.reentrancyLock = false;
    return success;
  }

  /*
   * @notice Fulfill a randomness request.
   * @param proof contains the proof and randomness
   * @param rc request commitment pre-image, committed to at request time
   * @param onlyPremium only charge premium
   * @return payment amount billed to the subscription
   * @dev simulated offchain to determine if sufficient balance is present to fulfill the request
   */
  function fulfillRandomWords(
    Proof memory proof,
    VRFTypes.RequestCommitmentV2Plus memory rc,
    bool onlyPremium
  ) external nonReentrant returns (uint96 payment) {
    uint256 startGas = gasleft();
    // fulfillRandomWords msg.data has 772 bytes and with an additional
    // buffer of 32 bytes, we get 804 bytes.
    /* Data size split:
     * fulfillRandomWords function signature - 4 bytes
     * proof - 416 bytes
     *   pk - 64 bytes
     *   gamma - 64 bytes
     *   c - 32 bytes
     *   s - 32 bytes
     *   seed - 32 bytes
     *   uWitness - 32 bytes
     *   cGammaWitness - 64 bytes
     *   sHashWitness - 64 bytes
     *   zInv - 32 bytes
     * requestCommitment - 320 bytes
     *   blockNum - 32 bytes
     *   subId - 32 bytes
     *   callbackGasLimit - 32 bytes
     *   numWords - 32 bytes
     *   sender - 32 bytes
     *   extraArgs - 128 bytes
     * onlyPremium - 32 bytes
     */
    if (msg.data.length > 804) {
      revert MsgDataTooBig(msg.data.length, 804);
    }
    Output memory output = _getRandomnessFromProof(proof, rc);
    uint256 gasPrice = _getValidatedGasPrice(onlyPremium, output.provingKey.maxGas);

    uint256[] memory randomWords;
    uint256 randomness = output.randomness;
    // stack too deep error
    {
      uint256 numWords = rc.numWords;
      randomWords = new uint256[](numWords);
      for (uint256 i = 0; i < numWords; ++i) {
        randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
      }
    }

    delete s_requestCommitments[output.requestId];
    bool success = _deliverRandomness(output.requestId, rc, randomWords);

    // Increment the req count for the subscription.
    ++s_subscriptions[rc.subId].reqCount;
    // Decrement the pending req count for the consumer.
    --s_consumers[rc.sender][rc.subId].pendingReqCount;

    bool nativePayment = uint8(rc.extraArgs[rc.extraArgs.length - 1]) == 1;

    // stack too deep error
    {
      // We want to charge users exactly for how much gas they use in their callback with
      // an additional premium. If onlyPremium is true, only premium is charged without
      // the gas cost. The gasAfterPaymentCalculation is meant to cover these additional
      // operations where we decrement the subscription balance and increment the
      // withdrawable balance.
      bool isFeedStale;
      (payment, isFeedStale) = _calculatePaymentAmount(startGas, gasPrice, nativePayment, onlyPremium);
      if (isFeedStale) {
        emit FallbackWeiPerUnitLinkUsed(output.requestId, s_fallbackWeiPerUnitLink);
      }
    }

    _chargePayment(payment, nativePayment, rc.subId);

    // Include payment in the event for tracking costs.
    emit RandomWordsFulfilled(output.requestId, randomness, rc.subId, payment, nativePayment, success, onlyPremium);

    return payment;
  }

  function _chargePayment(uint96 payment, bool nativePayment, uint256 subId) internal {
    Subscription storage subcription = s_subscriptions[subId];
    if (nativePayment) {
      uint96 prevBal = subcription.nativeBalance;
      if (prevBal < payment) {
        revert InsufficientBalance();
      }
      subcription.nativeBalance = prevBal - payment;
      s_withdrawableNative += payment;
    } else {
      uint96 prevBal = subcription.balance;
      if (prevBal < payment) {
        revert InsufficientBalance();
      }
      subcription.balance = prevBal - payment;
      s_withdrawableTokens += payment;
    }
  }

  function _calculatePaymentAmount(
    uint256 startGas,
    uint256 weiPerUnitGas,
    bool nativePayment,
    bool onlyPremium
  ) internal view returns (uint96, bool) {
    if (nativePayment) {
      return (_calculatePaymentAmountNative(startGas, weiPerUnitGas, onlyPremium), false);
    }
    return _calculatePaymentAmountLink(startGas, weiPerUnitGas, onlyPremium);
  }

  function _calculatePaymentAmountNative(
    uint256 startGas,
    uint256 weiPerUnitGas,
    bool onlyPremium
  ) internal view returns (uint96) {
    // Will return non-zero on chains that have this enabled
    uint256 l1CostWei = ChainSpecificUtil._getCurrentTxL1GasFees(msg.data);
    // calculate the payment without the premium
    uint256 baseFeeWei = weiPerUnitGas * (s_config.gasAfterPaymentCalculation + startGas - gasleft());
    // calculate flat fee in native
    uint256 flatFeeWei = 1e12 * uint256(s_config.fulfillmentFlatFeeNativePPM);
    if (onlyPremium) {
      return uint96((((l1CostWei + baseFeeWei) * (s_config.nativePremiumPercentage)) / 100) + flatFeeWei);
    } else {
      return uint96((((l1CostWei + baseFeeWei) * (100 + s_config.nativePremiumPercentage)) / 100) + flatFeeWei);
    }
  }

  // Get the amount of gas used for fulfillment
  function _calculatePaymentAmountLink(
    uint256 startGas,
    uint256 weiPerUnitGas,
    bool onlyPremium
  ) internal view returns (uint96, bool) {
    (int256 weiPerUnitLink, bool isFeedStale) = _getFeedData();
    if (weiPerUnitLink <= 0) {
      revert InvalidLinkWeiPrice(weiPerUnitLink);
    }
    // Will return non-zero on chains that have this enabled
    uint256 l1CostWei = ChainSpecificUtil._getCurrentTxL1GasFees(msg.data);
    // (1e18 juels/link) ((wei/gas * gas) + l1wei) / (wei/link) = juels
    uint256 paymentNoFee = (1e18 *
      (weiPerUnitGas * (s_config.gasAfterPaymentCalculation + startGas - gasleft()) + l1CostWei)) /
      uint256(weiPerUnitLink);
    // calculate the flat fee in wei
    uint256 flatFeeWei = 1e12 *
      uint256(s_config.fulfillmentFlatFeeNativePPM - s_config.fulfillmentFlatFeeLinkDiscountPPM);
    uint256 flatFeeJuels = (1e18 * flatFeeWei) / uint256(weiPerUnitLink);
    uint256 payment;
    if (onlyPremium) {
      payment = ((paymentNoFee * (s_config.linkPremiumPercentage)) / 100 + flatFeeJuels);
    } else {
      payment = ((paymentNoFee * (100 + s_config.linkPremiumPercentage)) / 100 + flatFeeJuels);
    }
    if (payment > 1e27) {
      revert PaymentTooLarge(); // Payment + fee cannot be more than all of the link in existence.
    }
    return (uint96(payment), isFeedStale);
  }

  function _getFeedData() private view returns (int256 weiPerUnitLink, bool isFeedStale) {
    uint32 stalenessSeconds = s_config.stalenessSeconds;
    uint256 timestamp;
    (, weiPerUnitLink, , timestamp, ) = LINK_NATIVE_FEED.latestRoundData();
    // solhint-disable-next-line not-rely-on-time
    isFeedStale = stalenessSeconds > 0 && stalenessSeconds < block.timestamp - timestamp;
    if (isFeedStale) {
      weiPerUnitLink = s_fallbackWeiPerUnitLink;
    }
    return (weiPerUnitLink, isFeedStale);
  }

  /**
   * @inheritdoc IVRFSubscriptionV2Plus
   */
  function pendingRequestExists(uint256 subId) public view override returns (bool) {
    address[] storage consumers = s_subscriptionConfigs[subId].consumers;
    uint256 consumersLength = consumers.length;
    if (consumersLength == 0) {
      return false;
    }
    for (uint256 i = 0; i < consumersLength; ++i) {
      if (s_consumers[consumers[i]][subId].pendingReqCount > 0) {
        return true;
      }
    }
    return false;
  }

  /**
   * @inheritdoc IVRFSubscriptionV2Plus
   */
  function removeConsumer(uint256 subId, address consumer) external override onlySubOwner(subId) nonReentrant {
    if (pendingRequestExists(subId)) {
      revert PendingRequestExists();
    }
    if (!s_consumers[consumer][subId].active) {
      revert InvalidConsumer(subId, consumer);
    }
    // Note bounded by MAX_CONSUMERS
    address[] memory consumers = s_subscriptionConfigs[subId].consumers;
    uint256 lastConsumerIndex = consumers.length - 1;
    for (uint256 i = 0; i < consumers.length; ++i) {
      if (consumers[i] == consumer) {
        address last = consumers[lastConsumerIndex];
        // Storage write to preserve last element
        s_subscriptionConfigs[subId].consumers[i] = last;
        // Storage remove last element
        s_subscriptionConfigs[subId].consumers.pop();
        break;
      }
    }
    s_consumers[consumer][subId].active = false;
    emit SubscriptionConsumerRemoved(subId, consumer);
  }

  /**
   * @inheritdoc IVRFSubscriptionV2Plus
   */
  function cancelSubscription(uint256 subId, address to) external override onlySubOwner(subId) nonReentrant {
    if (pendingRequestExists(subId)) {
      revert PendingRequestExists();
    }
    _cancelSubscriptionHelper(subId, to);
  }

  /***************************************************************************
   * Section: Migration
   ***************************************************************************/

  address[] internal s_migrationTargets;

  /// @dev Emitted when new coordinator is registered as migratable target
  event CoordinatorRegistered(address coordinatorAddress);

  /// @dev Emitted when new coordinator is deregistered
  event CoordinatorDeregistered(address coordinatorAddress);

  /// @notice emitted when migration to new coordinator completes successfully
  /// @param newCoordinator coordinator address after migration
  /// @param subId subscription ID
  event MigrationCompleted(address newCoordinator, uint256 subId);

  /// @notice emitted when migrate() is called and given coordinator is not registered as migratable target
  error CoordinatorNotRegistered(address coordinatorAddress);

  /// @notice emitted when migrate() is called and given coordinator is registered as migratable target
  error CoordinatorAlreadyRegistered(address coordinatorAddress);

  /// @dev encapsulates data to be migrated from current coordinator
  struct V1MigrationData {
    uint8 fromVersion;
    uint256 subId;
    address subOwner;
    address[] consumers;
    uint96 linkBalance;
    uint96 nativeBalance;
  }

  function _isTargetRegistered(address target) internal view returns (bool) {
    uint256 migrationTargetsLength = s_migrationTargets.length;
    for (uint256 i = 0; i < migrationTargetsLength; ++i) {
      if (s_migrationTargets[i] == target) {
        return true;
      }
    }
    return false;
  }

  function registerMigratableCoordinator(address target) external onlyOwner {
    if (_isTargetRegistered(target)) {
      revert CoordinatorAlreadyRegistered(target);
    }
    s_migrationTargets.push(target);
    emit CoordinatorRegistered(target);
  }

  function deregisterMigratableCoordinator(address target) external onlyOwner {
    uint256 nTargets = s_migrationTargets.length;
    for (uint256 i = 0; i < nTargets; ++i) {
      if (s_migrationTargets[i] == target) {
        s_migrationTargets[i] = s_migrationTargets[nTargets - 1];
        s_migrationTargets.pop();
        emit CoordinatorDeregistered(target);
        return;
      }
    }
    revert CoordinatorNotRegistered(target);
  }

  function migrate(uint256 subId, address newCoordinator) external nonReentrant {
    if (!_isTargetRegistered(newCoordinator)) {
      revert CoordinatorNotRegistered(newCoordinator);
    }
    (uint96 balance, uint96 nativeBalance, , address subOwner, address[] memory consumers) = getSubscription(subId);
    // solhint-disable-next-line gas-custom-errors
    require(subOwner == msg.sender, "Not subscription owner");
    // solhint-disable-next-line gas-custom-errors
    require(!pendingRequestExists(subId), "Pending request exists");

    V1MigrationData memory migrationData = V1MigrationData({
      fromVersion: 1,
      subId: subId,
      subOwner: subOwner,
      consumers: consumers,
      linkBalance: balance,
      nativeBalance: nativeBalance
    });
    bytes memory encodedData = abi.encode(migrationData);
    _deleteSubscription(subId);
    IVRFCoordinatorV2PlusMigration(newCoordinator).onMigration{value: nativeBalance}(encodedData);

    // Only transfer LINK if the token is active and there is a balance.
    if (address(LINK) != address(0) && balance != 0) {
      // solhint-disable-next-line gas-custom-errors
      require(LINK.transfer(address(newCoordinator), balance), "insufficient funds");
    }

    // despite the fact that we follow best practices this is still probably safest
    // to prevent any re-entrancy possibilities.
    s_config.reentrancyLock = true;
    for (uint256 i = 0; i < consumers.length; ++i) {
      IVRFMigratableConsumerV2Plus(consumers[i]).setCoordinator(newCoordinator);
    }
    s_config.reentrancyLock = false;

    emit MigrationCompleted(newCoordinator, subId);
  }
}

//-------------------------------------------------------------------------
//    ERRORS
//-------------------------------------------------------------------------
error SNGLot__RoundInactive(uint256);
error SNGLot__InsufficientTickets();
error SNGLot__InvalidMatchers();
error SNGLot__InvalidMatchRound();
error SNGLot__InvalidUpkeeper();
error SNGLot__InvalidRoundEndConditions();
error SNGLot__InvalidRound();
error SNGLot__TransferFailed();
error SNGLot__ETHTransferFailed();
error SNGLot__InvalidClaim();
error SNGLot__DuplicateTicketIdClaim(uint _round, uint _ticketIndex);
error SNGLot__InvalidClaimMatch(uint ticketIndex);
error SNGLot__InvalidDistribution(uint totalDistribution);
error SNGLot__InvalidToken();
error SNGLot__InvalidETHAmount(uint received, uint expected);
error SNGLot__InvalidCurrencyClaim();
error SNGLot__InvalidTokenPair();
error SNGLot__InvalidChainId();

contract SNGLottery is
    ReentrancyGuard,
    AutomationCompatible,
    VRFConsumerBaseV2Plus
{
    //-------------------------------------------------------------------------
    //    TYPE DECLARATIONS
    //-------------------------------------------------------------------------
    struct RoundInfo {
        uint256[3] distribution; // This is the total pot distributed to each item - NOT the percentages
        uint256 pot;
        uint256 ticketsBought;
        uint256 price;
        uint256 endRound; // Timestamp OR block number when round ends
        uint256 randomnessRequestID;
        bool active;
    }
    struct UserTickets {
        uint64[] tickets;
        bool[] claimed;
    }
    struct Matches {
        uint256 match1;
        uint256 match2;
        uint256 match3;
        uint256 match4;
        uint256 match5;
        uint256 roundId;
        uint64 winnerNumber; // We'll need to process this so it matches the same format as the tickets
        bool completed;
    }
    //-------------------------------------------------------------------------
    //    State Variables
    //-------------------------------------------------------------------------
    // kept for coverage purposes
    // mapping(address => bool ) public upkeeper;
    // mapping(uint  => Matches ) public matches;
    // mapping(uint => RoundInfo) public roundInfo;
    // mapping(uint => address[]) private roundUsers;
    // mapping(address  => mapping(uint => UserTickets))
    //     private userTickets;

    mapping(address _upkeep => bool _enabled) public upkeeper;
    mapping(uint _randomnessRequestID => Matches _winnerMatches) public matches;
    mapping(uint _roundId => RoundInfo) public roundInfo;
    mapping(uint _roundId => address[] participatingUsers) private roundUsers;
    mapping(address _user => mapping(uint _round => UserTickets _all))
        private userTickets;

    uint256 public teamFee; // 25% fee for team
    uint[3] public distributionPercentages; // This percentage allocates to the different distribution amounts per ROUND
    // [match3, match4, match5]
    // 25% Match 5 [0]
    // 25% Match 4 [1]
    // 25% Match 3 [2]
    // 0% Match 2 (ommited)
    // 0% Match 1 (ommited)

    address private immutable WETH;
    address public constant DEAD_WALLET =
        0x000000000000000000000000000000000000dEaD;
    AggregatorV3Interface private immutable priceFeed;
    //-------------------------------------------------------------------------
    //    VRF Config Variables
    //-------------------------------------------------------------------------
    address public immutable vrfCoordinator;
    bytes32 public immutable keyHash;
    uint256 private immutable subscriptionId;
    uint16 private constant minimumRequestConfirmations = 4;
    uint32 private callbackGasLimit = 100000;

    address payable public teamWallet;
    ISNGRouter public sngRouter;
    IUniswapRouter02 public pcsRouter;
    IERC20 public currency;
    uint256 public currentRound;
    uint256 public roundDuration;
    uint256 public constant PERCENTAGE_BASE = 100;
    uint64 public constant BIT_8_MASK = 0x00000000000000FF;
    uint64 public constant BIT_6_MASK = 0x000000000000003F;
    uint8 public constant BIT_1_MASK = 0x01;

    //-------------------------------------------------------------------------
    //    Events
    //-------------------------------------------------------------------------
    event AddToPot(address indexed user, uint256 indexed round, uint256 amount);
    event BoughtTickets(address indexed user, uint _round, uint amount);
    event EditRoundPrice(uint _round, uint _newPrice);
    event RolloverPot(uint _round, uint _newPot);
    event RoundEnded(uint indexed _round);
    event StartRound(uint indexed _round);
    event UpkeeperSet(address indexed upkeeper, bool isUpkeeper);
    event RewardClaimed(address indexed _user, uint rewardAmount);
    event RoundDurationSet(uint _oldDuration, uint _newDuration);
    event TransferFailed(address _to, uint _amount);
    event AltDistributionChanged(
        address _token,
        uint m3,
        uint m4,
        uint m5,
        uint dev,
        uint burn
    );
    event AltAcceptanceChanged(address indexed _token, bool status);
    event EditAltPrice(address _token, uint _newPrice);

    //-------------------------------------------------------------------------
    //    Modifiers
    //-------------------------------------------------------------------------
    modifier onlyUpkeeper() {
        if (!upkeeper[msg.sender]) revert SNGLot__InvalidUpkeeper();
        _;
    }

    modifier activeRound() {
        RoundInfo storage playingRound = roundInfo[currentRound];
        if (!playingRound.active || block.timestamp > playingRound.endRound)
            revert SNGLot__RoundInactive(currentRound);
        _;
    }

    //-------------------------------------------------------------------------
    //    Constructor
    //-------------------------------------------------------------------------
    constructor(
        address _tokenAccepted,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subscriptionId,
        address _team
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        // _tokenAccepted is BLZ token
        currency = IERC20(_tokenAccepted);

        roundDuration = 1 weeks;
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        address tempWETH;
        address tempFeed;

        if (block.chainid == 56) {
            sngRouter = ISNGRouter(0x19702801AC5319825286E8eE10B3bFE62B904Ba0);
            pcsRouter = IUniswapRouter02(sngRouter.router());
            tempWETH = sngRouter.weth();
            tempFeed = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        } else if (block.chainid == 97) {
            sngRouter = ISNGRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
            pcsRouter = IUniswapRouter02(sngRouter);
            tempWETH = pcsRouter.WETH();
            tempFeed = 0x1605C8A4937b2f84ef7967017a8633a135a62513;
        } else revert SNGLot__InvalidChainId();

        priceFeed = AggregatorV3Interface(tempFeed);
        WETH = tempWETH;
        distributionPercentages = [25, 25, 25];
        teamWallet = payable(_team);
        teamFee = 25;
    }

    receive() external payable {}

    fallback() external payable {}

    //-------------------------------------------------------------------------
    //    EXTERNAL Functions
    //-------------------------------------------------------------------------
    /**
     * @notice Buy tickets with ALT tokens or ETH
     * @param tickets Array of tickets to buy. The tickets need to have 5 numbers each spanning 8 bits in length
     * @param token Address of the token to use to buy tickets
     */
    function buyTickets(
        uint64[] calldata tickets,
        address token
    ) external payable nonReentrant activeRound {
        uint toBuy = 0;
        if (tickets.length == 0) revert SNGLot__InsufficientTickets();
        //========================
        //========================
        // get BNB price per ticket
        uint totalPrice = getBNBPricePerTicket(roundInfo[currentRound].price);
        totalPrice = totalPrice * tickets.length;
        //========================
        //========================
        // calculate team wallet amount
        uint bnbForTeam = (totalPrice * teamFee) / PERCENTAGE_BASE;
        totalPrice -= bnbForTeam;

        if (token == address(0)) {
            if (msg.value < totalPrice + bnbForTeam)
                revert SNGLot__InvalidETHAmount(msg.value, totalPrice);

            // swap ETH for CURRENCY
            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = address(currency);
            // reusing variable to save gas
            toBuy = currency.balanceOf(address(this));

            sngRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: totalPrice
            }(0, path, address(this), block.timestamp);
            _sendToTeamWallet(bnbForTeam);
            bnbForTeam = 0; // resets
            transferBNB(msg.sender, address(this).balance);
            toBuy = currency.balanceOf(address(this)) - toBuy;
        } else if (token == address(currency)) {
            // how many tokens to get from client
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;
            // Reuse variable
            uint[] memory amounts = pcsRouter.getAmountsIn(
                totalPrice + bnbForTeam,
                path
            );
            currency.transferFrom(msg.sender, address(this), amounts[0]);
            // 25% is sold for BNB
            bnbForTeam = (amounts[0] * teamFee) / PERCENTAGE_BASE;
            // 75% is kept as SNG for prize pot
            toBuy = amounts[0] - bnbForTeam;
            // swap the BNB for team amount
            currency.approve(address(sngRouter), type(uint).max);
            sngRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                bnbForTeam,
                0,
                path,
                address(this),
                block.timestamp
            );
            bnbForTeam = address(this).balance;
        } else {
            // how many tokens to get from client
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;
            // Reuse variable
            uint[] memory amounts = pcsRouter.getAmountsIn(
                totalPrice + bnbForTeam,
                path
            );
            ///@todo change for safe transfer
            IERC20 customToken = IERC20(token);
            customToken.transferFrom(msg.sender, address(this), amounts[0]);
            customToken.approve(address(sngRouter), type(uint).max);
            // swap tokens for BNB
            sngRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amounts[0],
                0,
                path,
                address(this),
                block.timestamp
            );
            toBuy = address(this).balance;
            bnbForTeam = (toBuy * teamFee) / PERCENTAGE_BASE;
            toBuy -= bnbForTeam;
            // swap BNB for SNG
            path[0] = WETH;
            path[1] = address(currency);
            // Amounts [1] holds the current balance of the contract
            amounts[1] = currency.balanceOf(address(this));
            sngRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: toBuy
            }(0, path, address(this), block.timestamp);
            // tokens to distribute are the new balance - the old balance which is the amount bought
            toBuy = currency.balanceOf(address(this)) - amounts[1];
            // @note this amount is restated so that no tokens are left behind
            bnbForTeam = address(this).balance;
        }

        uint[] memory dist = new uint[](3);
        dist[0] = distributionPercentages[0];
        dist[1] = distributionPercentages[1];
        dist[2] = distributionPercentages[2];
        _sendToTeamWallet(bnbForTeam);
        _addToPot(toBuy, currentRound, dist);
        // Buy Tickets
        _buyTickets(tickets, msg.sender);
    }

    /**
     *
     * @param _round round to claim tickets from
     * @param _userTicketIndexes Indexes / IDs of the tickets to claim
     * @param _matches matching number of the ticket/id to claim
     */
    function claimTickets(
        uint _round,
        uint[] calldata _userTicketIndexes,
        uint8[] calldata _matches
    ) public nonReentrant {
        uint toReward = _claimTickets(_round, _userTicketIndexes, _matches);
        if (toReward > 0) currency.transfer(msg.sender, toReward);
        emit RewardClaimed(msg.sender, toReward);
    }

    /**
     *
     * @param _rounds array of all rounds that will be claimed
     * @param _ticketsPerRound number of tickets that will be claimed in this call
     * @param _ticketIndexes array of ticket indexes to be claimed, the length of this array should be equal to the sum of _ticketsPerRound
     * @param _matches array to matches per ticket, the length of this array should be equal to the sum of _ticketsPerRound
     */
    function claimMultipleRounds(
        uint[] calldata _rounds,
        uint[] calldata _ticketsPerRound,
        uint[] calldata _ticketIndexes,
        uint8[] calldata _matches
    ) external nonReentrant {
        if (
            _rounds.length != _ticketsPerRound.length ||
            _rounds.length == 0 ||
            _ticketIndexes.length != _matches.length ||
            _ticketIndexes.length == 0
        ) revert SNGLot__InvalidClaim();
        uint ticketOffset;
        uint rewards;
        for (uint i = 0; i < _rounds.length; i++) {
            uint round = _rounds[i];
            uint endOffset = _ticketsPerRound[i] - 1;
            uint[] memory tickets = _ticketIndexes[ticketOffset:ticketOffset +
                endOffset];
            uint8[] memory allegedMatch = _matches[ticketOffset:ticketOffset +
                endOffset];

            rewards += _claimTickets(round, tickets, allegedMatch);
            ticketOffset += _ticketsPerRound[i];
        }
        if (rewards > 0) currency.transfer(msg.sender, rewards);
        emit RewardClaimed(msg.sender, rewards);
    }

    /**
     * @notice Edit the price for an upcoming round
     * @param _newPrice Price for the next upcoming round
     * @param _roundId ID of the upcoming round to edit
     * @dev If this is not called, on round end, the price will be the same as the previous round
     * @dev price is in USD and we'll be using the CHAINLINK DATAFEED to get BNB price.
     */
    function setUSDPrice(
        uint256 _newPrice,
        uint256 _roundId
    ) external onlyOwner {
        require(_roundId > currentRound, "Invalid ID");
        roundInfo[_roundId].price = _newPrice;
        emit EditRoundPrice(_roundId, _newPrice);
    }

    /**
     *
     * @param initPrice Price for the first round
     * @param firstRoundEnd the Time when the first round ends
     * @dev This function can only be called once by owner and sets the initial price
     */
    function activateLottery(
        uint initPrice,
        uint firstRoundEnd
    ) external onlyOwner {
        require(currentRound == 0, "Lottery started");
        currentRound++;
        RoundInfo storage startRound = roundInfo[1];
        startRound.price = initPrice;
        startRound.active = true;
        startRound.endRound = firstRoundEnd;
        emit StartRound(1);
    }

    /**
     * @param _upkeeper Address of the upkeeper
     * @param _status Status of the upkeeper
     * @dev enable or disable an address that can call performUpkeep
     */
    function setUpkeeper(address _upkeeper, bool _status) external onlyOwner {
        upkeeper[_upkeeper] = _status;
        emit UpkeeperSet(_upkeeper, _status);
    }

    /**
     *
     * @param performData Data to perform upkeep
     * @dev performData is abi encoded as (bool, uint256[])
     *      - bool is if it's a round end request upkeep or winner array request upkeep
     *      - uint256[] is the array of winners that match the criteria
     */
    function performUpkeep(bytes calldata performData) external onlyUpkeeper {
        //Only upkeepers can do this
        if (!upkeeper[msg.sender]) revert SNGLot__InvalidUpkeeper();

        (bool isRandomRequest, uint256[] memory matchers) = abi.decode(
            performData,
            (bool, uint256[])
        );
        RoundInfo storage playingRound = roundInfo[currentRound];
        if (isRandomRequest) {
            endRound();
        } else {
            if (matchers.length != 5 || playingRound.active)
                revert SNGLot__InvalidMatchers();
            Matches storage currentMatches = matches[
                playingRound.randomnessRequestID
            ];
            if (currentMatches.winnerNumber == 0 || currentMatches.completed)
                revert SNGLot__InvalidMatchRound();
            currentMatches.match1 = matchers[0];
            currentMatches.match2 = matchers[1];
            currentMatches.match3 = matchers[2];
            currentMatches.match4 = matchers[3];
            currentMatches.match5 = matchers[4];
            currentMatches.completed = true;
            rolloverAmount(currentRound, currentMatches);
            newRound(playingRound);
        }
    }

    function setRoundDuration(uint256 _newDuration) external onlyOwner {
        emit RoundDurationSet(roundDuration, _newDuration);
        roundDuration = _newDuration;
    }

    function claimNonPrizeTokens(address _token) external onlyOwner {
        if (_token == address(currency)) revert SNGLot__InvalidCurrencyClaim();
        if (_token == address(0)) {
            (bool succ, ) = payable(owner()).call{value: address(this).balance}(
                ""
            );
            if (!succ) emit TransferFailed(owner(), address(this).balance);
        } else {
            IERC20 token = IERC20(_token);
            token.transfer(owner(), token.balanceOf(address(this)));
        }
    }

    function addToPot(
        uint amount,
        uint round,
        uint[] memory customDistribution
    ) external {
        currency.transferFrom(msg.sender, address(this), amount);
        _addToPot(amount, round, customDistribution);
    }

    //-------------------------------------------------------------------------
    //    PUBLIC FUNCTIONS
    //-------------------------------------------------------------------------

    /**
     * @notice End the current round
     * @dev this function can be called by anyone as long as the conditions to end the round are met
     */
    function endRound() public {
        RoundInfo storage playingRound = roundInfo[currentRound];
        // Check that endRound of current Round is passed
        if (
            block.timestamp > playingRound.endRound &&
            playingRound.active &&
            playingRound.randomnessRequestID == 0
        ) {
            playingRound.active = false;
            emit RoundEnded(currentRound);
            if (playingRound.ticketsBought == 0) {
                rolloverAmount(currentRound, matches[0]);
                newRound(playingRound);
            } else {
                uint requestId = VRFCoordinatorV2_5(vrfCoordinator)
                    .requestRandomWords(
                        VRFV2PlusClient.RandomWordsRequest({
                            keyHash: keyHash,
                            subId: subscriptionId,
                            requestConfirmations: minimumRequestConfirmations,
                            callbackGasLimit: callbackGasLimit,
                            numWords: 1,
                            extraArgs: VRFV2PlusClient._argsToBytes(
                                VRFV2PlusClient.ExtraArgsV1({
                                    nativePayment: false
                                })
                            )
                        })
                    );
                playingRound.randomnessRequestID = requestId;
                matches[requestId].roundId = currentRound;
            }
        } else revert SNGLot__InvalidRoundEndConditions();
    }

    //-------------------------------------------------------------------------
    //    INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     * @notice Add SNG to the POT of the selected round
     * @param amount Amount of SNG to add to the pot
     * @param round Round to add the SNG to
     * @param customDistribution Distribution of the funds into the pot
        // 25% Match 3   0
        // 25% Match 4   1
        // 25% Match 5   2
     */
    function _addToPot(
        uint amount,
        uint round,
        uint[] memory customDistribution
    ) internal {
        if (round < currentRound || round == 0) revert SNGLot__InvalidRound();
        uint distributionLength = customDistribution.length;
        uint totalPercentage = PERCENTAGE_BASE - teamFee;
        if (distributionLength == 0 || distributionLength != 3) {
            customDistribution = new uint[](3);
            customDistribution[0] = distributionPercentages[0];
            customDistribution[1] = distributionPercentages[1];
            customDistribution[2] = distributionPercentages[2];
        } else {
            totalPercentage = 0;
            for (uint i = 0; i < 3; i++) {
                totalPercentage += customDistribution[i];
            }
        }
        RoundInfo storage playingRound = roundInfo[round];
        for (uint i = 0; i < 3; i++) {
            playingRound.distribution[i] +=
                (customDistribution[i] * amount) /
                totalPercentage;
        }

        playingRound.pot += amount;

        emit AddToPot(msg.sender, amount, round);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint64 winnerNumber = uint64(randomWords[0]);
        uint64 addedMask = 0;
        for (uint8 i = 0; i < 5; i++) {
            uint64 currentNumber = (winnerNumber >> (8 * i)) & BIT_6_MASK;
            if (i == 0) {
                addedMask += currentNumber;
                continue;
            }
            for (uint8 j = 1; j < i + 1; j++) {
                if (
                    currentNumber == ((addedMask >> (8 * (j - 1))) & BIT_6_MASK)
                ) {
                    currentNumber++;
                    j = 1;
                    continue;
                }
            }
            // pass a 6 bit mask to get the last 6 bits of each number
            addedMask += (currentNumber & BIT_6_MASK) << (8 * i);
        }
        if (addedMask == 0) addedMask = uint64(1);
        matches[requestId].winnerNumber = addedMask;
    }

    function _claimTickets(
        uint _round,
        uint[] memory _userTicketIndexes,
        uint8[] memory _matches
    ) internal returns (uint) {
        if (_round >= currentRound) revert SNGLot__InvalidRound();
        if (
            _userTicketIndexes.length != _matches.length ||
            _userTicketIndexes.length == 0
        ) revert SNGLot__InvalidClaim();
        RoundInfo storage round = roundInfo[_round];

        UserTickets storage user = userTickets[msg.sender][_round];
        if (user.tickets.length < _userTicketIndexes.length)
            revert SNGLot__InvalidClaim();

        Matches storage roundMatches = matches[round.randomnessRequestID];
        uint toReward;

        // Cycle through all tickets to claim
        for (uint i = 0; i < _userTicketIndexes.length; i++) {
            uint ticketIndex = _userTicketIndexes[i];
            // index is checked and if out of bounds, will revert
            if (_matches[i] < 3 || _matches[i] > 5)
                revert SNGLot__InvalidClaimMatch(i);

            if (user.claimed[ticketIndex])
                revert SNGLot__DuplicateTicketIdClaim(_round, ticketIndex);

            uint64 ticket = user.tickets[ticketIndex];

            if (
                _compareTickets(roundMatches.winnerNumber, ticket) ==
                _matches[i]
            ) {
                uint totalMatches = getTotalMatches(roundMatches, _matches[i]);

                user.claimed[ticketIndex] = true;

                uint256 matchReward = round.distribution[_matches[i] - 3] /
                    totalMatches;
                toReward += matchReward;
            } else {
                revert SNGLot__InvalidClaimMatch(i);
            }
        }
        return toReward;
    }

    //-------------------------------------------------------------------------
    //    PRIVATE FUNCTIONS
    //-------------------------------------------------------------------------

    function _buyTickets(uint64[] calldata tickets, address _user) private {
        RoundInfo storage playingRound = roundInfo[currentRound];
        if (!playingRound.active || block.timestamp > playingRound.endRound)
            revert SNGLot__RoundInactive(currentRound);
        // Check ticket array
        uint256 ticketAmount = tickets.length;
        if (ticketAmount == 0) {
            revert SNGLot__InsufficientTickets();
        }

        playingRound.ticketsBought += ticketAmount;
        // Save Ticket to current Round
        UserTickets storage user = userTickets[_user][currentRound];
        // Add user to the list of users to check for winners
        if (user.tickets.length == 0) roundUsers[currentRound].push(_user);

        for (uint i = 0; i < ticketAmount; i++) {
            user.tickets.push(tickets[i]);
            user.claimed.push(false);
        }
        emit BoughtTickets(_user, currentRound, ticketAmount);
    }

    function rolloverAmount(uint round, Matches storage matchInfo) private {
        RoundInfo storage playingRound = roundInfo[round];
        RoundInfo storage nextRound = roundInfo[round + 1];

        uint nextPot = 0;
        if (playingRound.pot == 0) return;
        // Check amount of winners of each match type and their distribution percentages
        // if (matchInfo.match1 == 0 && playingRound.distribution[0] > 0)
        //     nextPot += (currentPot * playingRound.distribution[0]) / 100;
        // if (matchInfo.match2 == 0 && playingRound.distribution[1] > 0)
        //     nextPot += (currentPot * playingRound.distribution[1]) / 100;
        if (matchInfo.match3 == 0) {
            nextPot += playingRound.distribution[0];
            nextRound.distribution[0] = playingRound.distribution[0];
        }
        if (matchInfo.match4 == 0) {
            nextPot += playingRound.distribution[1];
            nextRound.distribution[1] = playingRound.distribution[1];
        }
        if (matchInfo.match5 == 0) {
            nextPot += playingRound.distribution[2];
            nextRound.distribution[2] = playingRound.distribution[2];
        }
        // Send the appropriate percent to the team wallet
        nextRound.pot += nextPot;
        emit RolloverPot(round, nextPot);
    }

    function newRound(RoundInfo storage playingRound) private {
        currentRound++;
        roundInfo[currentRound].active = true;
        roundInfo[currentRound].endRound =
            playingRound.endRound +
            roundDuration;
        if (roundInfo[currentRound].price == 0)
            roundInfo[currentRound].price = playingRound.price;
    }

    function transferBNB(address to, uint amount) private {
        if (amount == 0) return;
        (bool succ, ) = payable(to).call{value: amount}("");
        if (!succ) revert SNGLot__ETHTransferFailed();
    }

    function getTotalMatches(
        Matches storage winners,
        uint8 matched
    ) private view returns (uint) {
        if (matched == 1) return winners.match1;
        if (matched == 2) return winners.match2;
        if (matched == 3) return winners.match3;
        if (matched == 4) return winners.match4;
        if (matched == 5) return winners.match5;
        return 0;
    }

    //-------------------------------------------------------------------------
    //    INTERNAL & PRIVATE VIEW & PURE FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     *
     * @param winnerNumber Base Number to check against
     * @param ticketNumber Number to check against the base number
     * @return matchAmount Number of matches between the two numbers
     */
    function _compareTickets(
        uint64 winnerNumber,
        uint64 ticketNumber
    ) private pure returns (uint8 matchAmount) {
        uint64 winnerMask;
        uint64 ticketMask;
        uint8 matchesChecked = 0x00;

        // cycle through all 5 numbers on winnerNumber
        for (uint8 i = 0; i < 5; i++) {
            winnerMask = (winnerNumber >> (8 * i)) & BIT_6_MASK;
            // cycle through all 5 numbers on ticketNumber
            for (uint8 j = 0; j < 5; j++) {
                // check if this ticket Mask has already been matched
                uint8 maskCheck = BIT_1_MASK << j;
                if (matchesChecked & maskCheck == maskCheck) {
                    continue;
                }
                ticketMask = (ticketNumber >> (8 * j)) & BIT_8_MASK;
                // If number is larger than 6 bits, ignore
                if (ticketMask > BIT_6_MASK) {
                    matchesChecked = matchesChecked | maskCheck;
                    continue;
                }

                if (winnerMask == ticketMask) {
                    matchAmount++;
                    matchesChecked = matchesChecked | maskCheck;
                    break;
                }
            }
        }
    }

    function _sendToTeamWallet(uint256 amount) private {
        if (amount == 0) return;
        (bool succ, ) = teamWallet.call{value: amount}("");
        if (!succ) revert SNGLot__ETHTransferFailed();
    }

    //-------------------------------------------------------------------------
    //    EXTERNAL AND PUBLIC VIEW & PURE FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     * @notice Check if upkeep is needed
     * @param checkData Data to check for upkeep
     * @return upkeepNeeded Whether upkeep is needed
     * @return performData Data to perform upkeep
     *          - We use two types of upkeeps here. 1 Time , 2 Custom logic
     *          - 1. Time based upkeep is used to end the round and request for randomness
     *          - 2. Custom logic is used to check for winners
     *          - performData has 2 values, endRoundRequest (bool) and matching numbers (uint[])
     *           if endRoundRequest is true, then we will end the round and request for randomness
     *          if matching numbers is not empty, then we will check for winners
     *          after winners are selected we increase the round number and activate it
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        checkData; // Dummy to remove unused var warning
        // Is this a endRound request or a checkWinner request?
        RoundInfo storage playingRound = roundInfo[currentRound];
        uint[] memory matchingNumbers = new uint[](5);
        performData = bytes("");
        if (playingRound.active) {
            upkeepNeeded = playingRound.endRound < block.timestamp;
            performData = abi.encode(true, matchingNumbers);
        } else if (
            playingRound.randomnessRequestID > 0 &&
            !matches[playingRound.randomnessRequestID].completed &&
            matches[playingRound.randomnessRequestID].winnerNumber > 0
        ) {
            upkeepNeeded = true;
            address[] storage participants = roundUsers[currentRound];
            uint participantsLength = participants.length;
            uint64 winnerNumber = matches[playingRound.randomnessRequestID]
                .winnerNumber;
            for (uint i = 0; i < participantsLength; i++) {
                UserTickets storage user = userTickets[participants[i]][
                    currentRound
                ];
                uint ticketsLength = user.tickets.length;
                for (uint j = 0; j < ticketsLength; j++) {
                    uint8 matchAmount = _compareTickets(
                        winnerNumber,
                        user.tickets[j]
                    );
                    if (matchAmount > 0) {
                        matchingNumbers[matchAmount - 1]++;
                    }
                }
            }
            performData = abi.encode(false, matchingNumbers);
        } else upkeepNeeded = false;
    }

    function checkTicket(
        uint round,
        uint _userTicketIndex,
        address _user
    ) external view returns (uint) {
        uint pot = roundInfo[round].pot;
        uint64 winnerNumber = matches[roundInfo[round].randomnessRequestID]
            .winnerNumber;
        if (pot == 0 || winnerNumber == 0) return 0;
        // Check if user has claimed this ticket
        if (userTickets[_user][round].claimed[_userTicketIndex]) return 0;

        uint8 _matched_ = _compareTickets(
            matches[roundInfo[round].randomnessRequestID].winnerNumber,
            userTickets[_user][round].tickets[_userTicketIndex]
        );
        if (_matched_ < 3) return 0;
        uint totalMatches = getTotalMatches(
            matches[roundInfo[round].randomnessRequestID],
            _matched_
        );
        if (totalMatches == 0) return 0;
        return roundInfo[round].distribution[_matched_ - 3] / totalMatches;
    }

    function checkTickets(
        uint round,
        uint[] calldata _userTicketIndexes,
        address _user
    ) external view returns (uint) {
        uint pot = roundInfo[round].pot;
        uint64 winnerNumber = matches[roundInfo[round].randomnessRequestID]
            .winnerNumber;
        if (pot == 0 || winnerNumber == 0) return 0;

        uint totalReward;
        uint rndId = roundInfo[round].randomnessRequestID;

        for (uint i = 0; i < _userTicketIndexes.length; i++) {
            uint ticketIndex = _userTicketIndexes[i];
            // Check if user has claimed this ticket
            if (userTickets[_user][round].claimed[ticketIndex]) continue;

            uint8 _matched_ = _compareTickets(
                matches[rndId].winnerNumber,
                userTickets[_user][round].tickets[ticketIndex]
            );
            if (_matched_ < 3) continue;
            uint totalMatches = getTotalMatches(matches[rndId], _matched_);
            if (totalMatches == 0) continue;
            totalReward +=
                roundInfo[round].distribution[_matched_ - 3] /
                totalMatches;
        }
        return totalReward;
    }

    function getUserTickets(
        address _user,
        uint round
    )
        external
        view
        returns (
            uint64[] memory _userTickets,
            bool[] memory claimed,
            uint tickets
        )
    {
        UserTickets storage user = userTickets[_user][round];
        tickets = user.tickets.length;
        _userTickets = new uint64[](tickets);
        claimed = new bool[](tickets);
        for (uint i = 0; i < tickets; i++) {
            _userTickets[i] = user.tickets[i];
            claimed[i] = user.claimed[i];
        }
    }

    function checkTicketMatching(
        uint64 ticket1,
        uint64 ticket2
    ) external pure returns (uint8) {
        return _compareTickets(ticket1, ticket2);
    }

    function roundDistribution(
        uint round
    ) external view returns (uint[] memory) {
        uint distLen = roundInfo[round].distribution.length;
        uint[] memory distribution = new uint[](distLen);
        for (uint i = 0; i < distLen; i++) {
            distribution[i] = roundInfo[round].distribution[i];
        }
        return distribution;
    }

    //=================================================================
    // INTERNAL / PRIVATE VIEW PURE FUNCTIONS
    //=================================================================
    function getBNBPricePerTicket(
        uint currentRoundPrice
    ) public view returns (uint) {
        uint8 remainingDecimals = priceFeed.decimals();
        (, int bnbPrice, , , ) = priceFeed.latestRoundData();
        // What is needed for price to be in ether
        remainingDecimals = 18 - remainingDecimals;
        uint bnbPriceInEther = uint256(bnbPrice) * 10 ** remainingDecimals;
        // How much BNB is 1 ticket.
        return (currentRoundPrice * 1 ether) / bnbPriceInEther;
    }
}
