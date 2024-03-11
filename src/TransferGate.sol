// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Currency} from "src/libraries/LibCurrency.sol";
import {LibRoles as Roles} from "src/libraries/LibRoles.sol";
import {UniqueChecker} from "src/internal/UniqueChecker.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract TransferGate is Initializable, UniqueChecker, AccessControlUpgradeable, UUPSUpgradeable {
  error LengthMismatch();

  event BatchTransfer(address indexed by, TransferDetail detail);
  event RecoverToken(address indexed by, address indexed token, uint256 amount);

  struct TransferDetail {
    bytes32 key;
    Currency currency;
    uint256[] amounts;
    address[] recipients;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address defaultAdmin_) public initializer {
    _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);
    __AccessControl_init_unchained();
    __UUPSUpgradeable_init_unchained();
  }

  function recover(Currency currency_, uint256 amount_) external onlyRole(Roles.TREASURER_ROLE) {
    currency_.transfer(_msgSender(), amount_);
    emit RecoverToken(_msgSender(), Currency.unwrap(currency_), amount_);
  }

  function batchTransfer(TransferDetail calldata transferDetail_) external onlyRole(Roles.OPERATOR_ROLE) {
    _setUsed(uint256(transferDetail_.key));
    _lengthValidate(transferDetail_.recipients, transferDetail_.amounts);
    _batchTransfer(transferDetail_.currency, transferDetail_.recipients, transferDetail_.amounts);

    emit BatchTransfer(_msgSender(), transferDetail_);
  }

  function _lengthValidate(address[] calldata recipients_, uint256[] calldata amounts_) internal pure {
    if (recipients_.length != amounts_.length) {
      revert LengthMismatch();
    }
  }

  function _batchTransfer(Currency currency_, address[] calldata recipients_, uint256[] calldata amounts_) internal {
    uint256 amount;
    address recipient;
    for (uint256 i; i < recipients_.length;) {
      amount = amounts_[i];
      recipient = recipients_[i];
      currency_.transfer(recipient, amount);
      unchecked {
        ++i;
      }
    }
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyRole(Roles.UPGRADER_ROLE) {}
}
