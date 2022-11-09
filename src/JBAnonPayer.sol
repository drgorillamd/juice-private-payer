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

  IJBDirectory internal directory;
  uint256 internal projectId;
  address internal sender;
  uint256 internal fcDeadline;

  constructor(
    IJBDirectory _directory,
    uint256 _projectId,
    address _sender,
    uint256 _fcDeadline
  ){
    directory = _directory;
    projectId = _projectId;
    sender = _sender;
    fcDeadline = _fcDeadline;
  }

  function pay(
    address _token
  ) external {
    address _sender = sender;
    uint256 _projectId = projectId;
    IJBDirectory _directory = directory;

    // If the fundingCycle deadline has already passed then the funds get refunded to the sender
    uint256 _currentFc = _directory.fundingCycleStore().currentOf(_projectId).number;
    if (_currentFc > fcDeadline) return _refund(_token, _sender);

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
      _sender, // Forward the tokens to the sender
      0,
      false, // prefer claimed?
      'ghost contribution',
      new bytes(0)
    );
  }

  function _refund(address _token, address _sender) internal {
    // Send the assets back to the original sender
    if(_token == JBTokens.ETH) {
      payable(_sender).transfer(address(this).balance);
    }
    else {
      uint256 _amount = IERC20(_token).balanceOf(address(this));
      IERC20(_token).transfer(_sender, _amount);
    }
  }
}