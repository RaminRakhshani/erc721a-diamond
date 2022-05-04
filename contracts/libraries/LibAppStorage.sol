// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;
import {LibDiamond} from "../libraries/LibDiamond.sol";

struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Keeps track of the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
}

// Compiler will pack this into a single 256bit word.
struct AddressData {
    // Realistically, 2**64-1 is more than enough.
    uint64 balance;
    // Keeps track of mint count with minimal overhead for tokenomics.
    uint64 numberMinted;
    // Keeps track of burn count with minimal overhead for tokenomics.
    uint64 numberBurned;
    // For miscellaneous variable(s) pertaining to the address
    // (e.g. number of whitelist mint slots used).
    // If there are multiple variables, please pack them into a uint64.
    uint64 aux;
}

struct AppStorage {
    uint256 reentrancyGuardStatus;
    // The tokenId of the next token to be minted.
    uint256 currentIndex;
    // The number of tokens burned.
    uint256 burnCounter;
    // Token name
    string name;
    // Token symbol
    string symbol;
    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) ownerships;
    // Mapping owner address to address data
    mapping(address => AddressData) addressData;
    // Mapping from token ID to approved address
    mapping(uint256 => address) tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) operatorApprovals;
    bytes32 merkleRoot;
    mapping(address => bool) whitelistClaimed;
    string uriPrefix; // = "";
    string uriSuffix; // = ".json";
    string hiddenMetadataUri;
    uint256 cost;
    uint256 maxSupply;
    uint256 maxMintAmountPerTx;
    bool paused; // = true;
    bool whitelistMintEnabled; // = false;
    bool revealed; // = false;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}
