// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {TransferGate} from "src/TransferGate.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {LibRoles as Roles} from "src/libraries/LibRoles.sol";
import {Currency, LibCurrency} from "src/libraries/LibCurrency.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TransferGateTest is Test {
  MockERC20 token;
  TransferGate transferGate;

  address admin;
  address operator;
  address upgrader;
  address treasurer;

  function setUp() public {
    token = new MockERC20();
    admin = makeAddr("admin");
    operator = makeAddr("operator");
    upgrader = makeAddr("upgrader");
    treasurer = makeAddr("treasurer");

    _setUpTransferGate();
    vm.startPrank(admin);
    transferGate.grantRole(Roles.OPERATOR_ROLE, operator);
    transferGate.grantRole(Roles.UPGRADER_ROLE, upgrader);
    transferGate.grantRole(Roles.TREASURER_ROLE, treasurer);
    vm.stopPrank();

    token.mint(operator, 100 ether);
    vm.startPrank(operator, operator);
    token.approve(address(transferGate), 100 ether);
    token.transfer(address(transferGate), 100 ether);
    vm.stopPrank();
  }

  function testConcrete_batchTransfer() public {
    address recipient1 = makeAddr("recipient1");
    address recipient2 = makeAddr("recipient2");

    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 50 ether;
    amounts[1] = 50 ether;

    address[] memory recipients = new address[](2);
    recipients[0] = recipient1;
    recipients[1] = recipient2;

    TransferGate.TransferDetail memory detail = TransferGate.TransferDetail({
      key: bytes32(uint256(1)),
      currency: Currency.wrap(address(token)),
      amounts: amounts,
      recipients: recipients
    });

    vm.prank(operator, operator);
    vm.expectEmit(address(transferGate));
    emit TransferGate.BatchTransfer(operator, detail);
    transferGate.batchTransfer(detail);
  }

  function testConcrete_batchTransfer_RevertWhenLengthMismatch() public {
    address recipient1 = makeAddr("recipient1");

    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 50 ether;
    amounts[1] = 50 ether;

    address[] memory recipients = new address[](1);
    recipients[0] = recipient1;

    TransferGate.TransferDetail memory detail = TransferGate.TransferDetail({
      key: bytes32(uint256(1)),
      currency: Currency.wrap(address(token)),
      amounts: amounts,
      recipients: recipients
    });

    vm.prank(operator, operator);
    vm.expectRevert(TransferGate.LengthMismatch.selector);
    transferGate.batchTransfer(detail);
  }

  function testConcrete_batchTransfer_RevertIfTransferZero() public {
    address recipient1 = makeAddr("recipient1");
    address recipient2 = makeAddr("recipient2");

    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 0 ether;
    amounts[1] = 50 ether;

    address[] memory recipients = new address[](2);
    recipients[0] = recipient1;
    recipients[1] = recipient2;

    TransferGate.TransferDetail memory detail = TransferGate.TransferDetail({
      key: bytes32(uint256(1)),
      currency: Currency.wrap(address(token)),
      amounts: amounts,
      recipients: recipients
    });

    vm.prank(operator, operator);
    vm.expectRevert(abi.encodeWithSelector(LibCurrency.TransferZeroAmount.selector, Currency.wrap(address(token))));
    transferGate.batchTransfer(detail); 
  }

  function testConcrete_recoverToken() public {
    vm.prank(treasurer, treasurer);
    vm.expectEmit(address(transferGate));
    emit TransferGate.RecoverToken(treasurer, address(token), 100 ether);
    transferGate.recover(Currency.wrap(address(token)), 100 ether);
  }

  function testConcrete_upgrateContract() public {
    vm.startPrank(upgrader, upgrader);
    address logic = address(new TransferGate());
    transferGate.upgradeToAndCall(logic, abi.encode());
    vm.stopPrank();
  }

  function _setUpTransferGate() internal {
    vm.startPrank(admin);
    address logic = address(new TransferGate());
    transferGate = TransferGate(payable(new ERC1967Proxy(logic, abi.encodeCall(TransferGate.initialize, (admin)))));
    vm.stopPrank();
  }
}
