// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Migrate.s.sol";
import {JPYC} from "src/JPYC.sol";
import {TransferGate} from "src/TransferGate.sol";

interface IERC404 {
  function mintERC20(address to, uint256 amount) external;
}

contract Deployer is BaseMigrate {
  function run() external {
    deploy();
    // mint();
  }

  function deploy() public broadcast {
    // deployUUPSProxy("JPYC.sol:JPYC", abi.encodeCall(JPYC.initialize, ()));
    // deployUUPSProxy("TransferGate.sol:TransferGate", abi.encodeCall(TransferGate.initialize, (msg.sender)));
    upgradeProxy("TransferGate.sol:TransferGate", 0x3A182F2a41b3e48C595A9c0AA7F7C0a128BFFF96, EMPTY_ARGS);
  }

  // function mint() public broadcast {
  //   IERC404 erc404 = IERC404(0xE79044aBC6040a8d34ecbFB84252689aaB27B767);
  //   for (uint256 i; i < 15; ++i) {
  //     erc404.mintERC20(makeAddr(string.concat("account-", vm.toString(i))), 50_000 ether);
  //   }
  // }
}
