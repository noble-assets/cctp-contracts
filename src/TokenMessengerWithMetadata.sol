// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "evm-cctp-contracts/src/interfaces/IMessageTransmitter.sol";
import "evm-cctp-contracts/src/interfaces/IMintBurnToken.sol";
import "evm-cctp-contracts/src/messages/Message.sol";
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
    IMessageTransmitter public immutable messageTransmitter;

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

    // ============ External Functions ============
    /**
     * @notice Wrapper function for "depositForBurn" that includes metadata.
     * Emits a `DepositForBurnMetadata` event.
     * @param channel channel id to be used when ibc forwarding
     * @param destinationRecipient address of recipient once ibc forwarded
     * @param amount amount of tokens to burn
     * @param mintRecipient address of mint recipient on destination domain
     * @param burnToken address of contract to burn deposited tokens, on local domain
     * @param memo arbitrary memo to be included when ibc forwarding
     * @return nonce unique nonce reserved by message
     */
    function depositForBurn(
        uint64 channel,
        bytes32 destinationRecipient,
        uint256 amount,
        bytes32 mintRecipient,
        address burnToken,
        bytes calldata memo
    ) external returns (uint64 nonce) {
        bytes memory metadata =
            abi.encodePacked(channel, destinationRecipient, memo);

        return rawDepositForBurn(amount, mintRecipient, burnToken, metadata);
    }

    /**
     * @notice Wrapper function for "depositForBurn" that includes metadata.
     * Emits a `DepositForBurnMetadata` event.
     * @param amount amount of tokens to burn
     * @param mintRecipient address of mint recipient on destination domain
     * @param burnToken address of contract to burn deposited tokens, on local domain
     * @param metadata custom metadata to be included with transfer
     * @return nonce unique nonce reserved by message
     */
    function rawDepositForBurn(
        uint256 amount,
        bytes32 mintRecipient,
        address burnToken,
        bytes memory metadata
    ) public returns (uint64 nonce) {
        IMintBurnToken token = IMintBurnToken(burnToken);
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(tokenMessenger), amount);

        nonce = tokenMessenger.depositForBurn(
            amount, domainNumber, mintRecipient, burnToken
        );

        bytes32 sender = Message.addressToBytes32(msg.sender);
        bytes memory message = abi.encodePacked(nonce, sender, metadata);
        uint64 metadataNonce = messageTransmitter.sendMessage(
            domainNumber, domainRecipient, message
        );

        emit DepositForBurnMetadata(nonce, metadataNonce, metadata);
    }

    /**
     * @notice Wrapper function for "depositForBurnWithCaller" that includes metadata.
     * Emits a `DepositForBurnMetadata` event.
     * @param channel channel id to be used when ibc forwarding
     * @param destinationRecipient address of recipient once ibc forwarded
     * @param amount amount of tokens to burn
     * @param mintRecipient address of mint recipient on destination domain
     * @param burnToken address of contract to burn deposited tokens, on local domain
     * @param destinationCaller caller on the destination domain, as bytes32
     * @param memo arbitrary memo to be included when ibc forwarding
     * @return nonce unique nonce reserved by message
     */
    function depositForBurnWithCaller(
        uint64 channel,
        bytes32 destinationRecipient,
        uint256 amount,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller,
        bytes calldata memo
    ) external returns (uint64 nonce) {
        bytes memory metadata =
            abi.encodePacked(channel, destinationRecipient, memo);

        return rawDepositForBurnWithCaller(
            amount, mintRecipient, burnToken, destinationCaller, metadata
        );
    }

    /**
     * @notice Wrapper function for "depositForBurnWithCaller" that includes metadata.
     * Emits a `DepositForBurnMetadata` event.
     * @param amount amount of tokens to burn
     * @param mintRecipient address of mint recipient on destination domain
     * @param burnToken address of contract to burn deposited tokens, on local domain
     * @param destinationCaller caller on the destination domain, as bytes32
     * @param metadata custom metadata to be included with transfer
     * @return nonce unique nonce reserved by message
     */
    function rawDepositForBurnWithCaller(
        uint256 amount,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller,
        bytes memory metadata
    ) public returns (uint64 nonce) {
        IMintBurnToken token = IMintBurnToken(burnToken);
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(tokenMessenger), amount);

        nonce = tokenMessenger.depositForBurnWithCaller(
            amount, domainNumber, mintRecipient, burnToken, destinationCaller
        );

        bytes32 sender = Message.addressToBytes32(msg.sender);
        bytes memory message = abi.encodePacked(nonce, sender, metadata);
        uint64 metadataNonce = messageTransmitter.sendMessageWithCaller(
            domainNumber, domainRecipient, destinationCaller, message
        );

        emit DepositForBurnMetadata(nonce, metadataNonce, metadata);
    }
}
