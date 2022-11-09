// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


/**
    @dev This is the minimal payer deployed to the ghost deposit addresses.
         It includes sweeping
*/
contract JBAnonPayer {
  error JBAnonPayer_UNAUTHORIZED();
  error JBAnonPayer_TERMINAL_NOT_FOUND();

  address internal sender;
  
  function pay(
    IJBDirectory _directory,
    uint256 _projectId,
    address _token,
    address _sender
  ) external {
    // Find the terminal for the specified project.
    IJBPaymentTerminal _terminal = _directory.primaryTerminalOf(_projectId, _token);

    // There must be a terminal.
    if (_terminal == IJBPaymentTerminal(address(0))) revert JBAnonPayer_TERMINAL_NOT_FOUND();
    
    uint256 _payableValue;
    uint256 _amount;
    
    // If the token is ETH, send it in msg.value.
    if(_token == JBTokens.ETH) _payableValue = address(this).balance;
    // else approve the token balance
    else {
      _amount = IERC20(_token).balanceOf(address(this));
      IERC20(_token).approve(address(_terminal), _amount);
    }

    // Send funds to the terminal.
    // If the token is ETH, send it in msg.value.
    _terminal.pay{value: _payableValue}(
      _projectId,
      _amount, // ignored if the token is JBTokens.ETH.
      _token,
      address(this),
      0,
      false, // prefer claimed?
      'ghost contribution',
      new bytes(0)
    );

    // Keep trace of the original sender, to insure sweep beneficiary
    sender = _sender;
  }

  // sweep eth or token (authentication based on the deployer/funder address)
  function sweep() external {
    payable(sender).transfer(address(this).balance);
  }

  function sweep(address _token) external {
    IERC20(_token).transfer(sender, IERC20(_token).balanceOf(address(this)));
  }

}