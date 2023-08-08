pragma solidity 0.7.6;

import "evm-cctp-contracts/src/TokenMessenger.sol";
import "evm-cctp-contracts/src/messages/Message.sol";
import "evm-cctp-contracts/src/messages/BurnMessage.sol";
import "evm-cctp-contracts/src/MessageTransmitter.sol";
import "evm-cctp-contracts/test/TestUtils.sol";
import "../src/TokenMessengerWithMetadata.sol";

contract TokenMessengerWithMetadataTest is Test, TestUtils {
    // ============ State Variables ============
    uint32 public constant LOCAL_DOMAIN = 0;
    uint32 public constant MESSAGE_BODY_VERSION = 1;

    uint32 public constant REMOTE_DOMAIN = 4;
    bytes32 public constant REMOTE_TOKEN_MESSENGER =
        0x00000000000000000000000057d4eaf1091577a6b7d121202afbd2808134f117;

    uint32 public constant ALLOWED_BURN_AMOUNT = 42;
    MockMintBurnToken public token = new MockMintBurnToken();
    TokenMinter public tokenMinter = new TokenMinter(tokenController);

    MessageTransmitter public messageTransmitter = new MessageTransmitter(
            LOCAL_DOMAIN,
            attester,
            maxMessageBodySize,
            version
        );

    TokenMessenger public tokenMessenger;
    TokenMessengerWithMetadata public tokenMessengerWrapper;

    // ============ Setup ============
    function setUp() public {
        tokenMessenger = new TokenMessenger(
            address(messageTransmitter),
            MESSAGE_BODY_VERSION
        );
        tokenMessengerWrapper = new TokenMessengerWithMetadata(
            address(tokenMessenger),
            REMOTE_DOMAIN,
            REMOTE_TOKEN_MESSENGER
        );

        tokenMessenger.addLocalMinter(address(tokenMinter));
        tokenMessenger.addRemoteTokenMessenger(
            REMOTE_DOMAIN, REMOTE_TOKEN_MESSENGER
        );

        linkTokenPair(
            tokenMinter, address(token), REMOTE_DOMAIN, REMOTE_TOKEN_MESSENGER
        );
        tokenMinter.addLocalTokenMessenger(address(tokenMessenger));

        vm.prank(tokenController);
        tokenMinter.setMaxBurnAmountPerMessage(
            address(token), ALLOWED_BURN_AMOUNT
        );
    }

    // ============ Tests ============
    function testConstructor_rejectsZeroAddressTokenMessenger() public {
        vm.expectRevert("TokenMessenger not set");

        tokenMessengerWrapper = new TokenMessengerWithMetadata(
            address(0),
            REMOTE_DOMAIN,
            REMOTE_TOKEN_MESSENGER
        );
    }

    function testDepositForBurn_succeeds(
        uint256 _amount,
        address _mintRecipient
    ) public {
        _amount = bound(_amount, 1, ALLOWED_BURN_AMOUNT);

        vm.assume(_mintRecipient != address(0));
        bytes32 _mintRecipientRaw = Message.addressToBytes32(_mintRecipient);

        bytes memory metadata = "";

        //
        token.mint(owner, _amount * 2);

        vm.prank(owner);
        token.approve(address(tokenMessengerWrapper), _amount);

        //
        vm.prank(owner);
        tokenMessengerWrapper.rawDepositForBurn(
            _amount, _mintRecipientRaw, address(token), metadata
        );
    }

    function testDepositForBurnWithCaller_succeeds(
        uint256 _amount,
        address _mintRecipient
    ) public {
        _amount = bound(_amount, 1, ALLOWED_BURN_AMOUNT);

        vm.assume(_mintRecipient != address(0));
        bytes32 _mintRecipientRaw = Message.addressToBytes32(_mintRecipient);

        bytes memory metadata = "";

        //
        token.mint(owner, _amount * 2);

        vm.prank(owner);
        token.approve(address(tokenMessengerWrapper), _amount);

        //
        vm.prank(owner);
        tokenMessengerWrapper.rawDepositForBurnWithCaller(
            _amount,
            _mintRecipientRaw,
            address(token),
            destinationCaller,
            metadata
        );
    }
}
