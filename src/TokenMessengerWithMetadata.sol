pragma solidity 0.7.6;

import "evm-cctp-contracts/src/TokenMessenger.sol";

/**
 * @title TokenMessengerWithMetadata
 * @notice A wrapper for a CCTP TokenMessenger contract that allows users to
 * supply additional metadata when initiating a transfer. This metadata is used
 * to initiate IBC forwards after transferring to Noble (Destination Domain = 4).
 */
contract TokenMessengerWithMetadata {
    // ============ Events ============
    event DepositForBurnMetadata(uint64 indexed nonce, string metadata);

    // ============ State Variables ============
    TokenMessenger public tokenMessenger;

    // ============ Constructor ============
    constructor(address _tokenMessenger) {
        tokenMessenger = TokenMessenger(_tokenMessenger);
    }

    // ============ External Functions  ============
    /**
     * @notice Wrapper function for "depositForBurn" that includes metadata.
     * Emits a `DepositForBurnMetadata` event.
     * @param metadata custom metadata to be included with transfer
     * @return nonce unique nonce reserved by message
     */
    function depositForBurn(
        string calldata metadata,
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 nonce) {
        nonce = tokenMessenger.depositForBurn(
            amount, destinationDomain, mintRecipient, burnToken
        );

        emit DepositForBurnMetadata(nonce, metadata);
    }

    /**
     * @notice Wrapper function for "depositForBurnWithCaller" that includes metadata.
     * Emits a `DepositForBurnMetadata` event.
     * @param metadata custom metadata to be included with transfer
     * @return nonce unique nonce reserved by message
     */
    function depositForBurnWithCaller(
        string calldata metadata,
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller
    ) external returns (uint64 nonce) {
        nonce = tokenMessenger.depositForBurnWithCaller(
            amount,
            destinationDomain,
            mintRecipient,
            burnToken,
            destinationCaller
        );

        emit DepositForBurnMetadata(nonce, metadata);
    }

    // TODO: Should we also wrap replaceDepositForBurn?
}
