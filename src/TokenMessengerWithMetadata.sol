pragma solidity 0.7.6;

import "evm-cctp-contracts/src/interfaces/IMessageTransmitter.sol";
import "evm-cctp-contracts/src/interfaces/IMintBurnToken.sol";
import "evm-cctp-contracts/src/TokenMessenger.sol";

/**
 * @title TokenMessengerWithMetadata
 * @notice A wrapper for a CCTP TokenMessenger contract that allows users to
 * supply additional metadata when initiating a transfer. This metadata is used
 * to initiate IBC forwards after transferring to Noble (Destination Domain = 4).
 */
contract TokenMessengerWithMetadata {
    // ============ Events ============
    event DepositForBurnMetadata(
        uint64 indexed nonce, uint64 indexed metadataNonce, bytes metadata
    );

    // ============ State Variables ============
    TokenMessenger public tokenMessenger;
    IMessageTransmitter public messageTransmitter;

    uint32 public immutable domainNumber;
    bytes32 public immutable domainRecipient;

    // ============ Constructor ============
    /**
     * @param _tokenMessenger Token messenger address
     * @param _domainNumber Noble's domain number
     * @param _domainRecipient Noble's domain recipient
     */
    constructor(
        address _tokenMessenger,
        uint32 _domainNumber,
        bytes32 _domainRecipient
    ) {
        require(_tokenMessenger != address(0), "TokenMessenger not set");
        tokenMessenger = TokenMessenger(_tokenMessenger);
        messageTransmitter = tokenMessenger.localMessageTransmitter();

        domainNumber = _domainNumber;
        domainRecipient = _domainRecipient;
    }

    // ============ External Functions  ============
    /**
     * @notice Wrapper function for "depositForBurn" that includes metadata.
     * Emits a `DepositForBurnMetadata` event.
     * @param metadata custom metadata to be included with transfer
     * @return nonce unique nonce reserved by message
     */
    function depositForBurn(
        bytes calldata metadata,
        uint256 amount,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 nonce) {
        IMintBurnToken token = IMintBurnToken(burnToken);
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer operation failed"
        );
        require(
            token.approve(address(tokenMessenger), amount),
            "Approve operation failed"
        );

        nonce = tokenMessenger.depositForBurn(
            amount, domainNumber, mintRecipient, burnToken
        );

        bytes memory message = abi.encodePacked(nonce, metadata);
        uint64 metadataNonce = messageTransmitter.sendMessage(
            domainNumber, domainRecipient, message
        );

        emit DepositForBurnMetadata(nonce, metadataNonce, metadata);
    }

    /**
     * @notice Wrapper function for "depositForBurnWithCaller" that includes metadata.
     * Emits a `DepositForBurnMetadata` event.
     * @param metadata custom metadata to be included with transfer
     * @return nonce unique nonce reserved by message
     */
    function depositForBurnWithCaller(
        bytes calldata metadata,
        uint256 amount,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller
    ) external returns (uint64 nonce) {
        IMintBurnToken token = IMintBurnToken(burnToken);
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer operation failed"
        );
        require(
            token.approve(address(tokenMessenger), amount),
            "Approve operation failed"
        );

        nonce = tokenMessenger.depositForBurnWithCaller(
            amount, domainNumber, mintRecipient, burnToken, destinationCaller
        );

        bytes memory message = abi.encodePacked(nonce, metadata);
        uint64 metadataNonce = messageTransmitter.sendMessageWithCaller(
            domainNumber, domainRecipient, destinationCaller, message
        );

        emit DepositForBurnMetadata(nonce, metadataNonce, metadata);
    }
}
