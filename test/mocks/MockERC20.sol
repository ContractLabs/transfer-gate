// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
  constructor() ERC20("MockToken", "MTK") {}

  function mint(address to_, uint256 amount_) external {
    _mint(to_, amount_);
  }

  function burn(address from_, uint256 amount_) external {
    _burn(from_, amount_);
  }
}
