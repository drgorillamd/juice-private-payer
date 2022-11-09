// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';

import './JBAnonPayer.sol';

/**
    @dev This contracts deploys the minions, the anon project payer, at the addresses
         of the create2.
 */
contract JBAnonPayerFactory {

    /**
        @notice The supported Juicebox version
    */
    uint256 public immutable juiceboxVersion;

    /**
        @notice The corresponding directory
    */
    IJBDirectory public immutable directory;

    constructor(uint256 _juiceboxVersion, IJBDirectory _directory) {
        juiceboxVersion = _juiceboxVersion;
        directory = _directory;
    }

    /**
        @notice Helper to get the address where to send fund, prior to anon payer deployment
        @param _projectId the project to pay
        @param _sender the address of the user that is paying
        @param _fcDeadline the funding cycle deadline after which the funds are returned to the user and not paid
        @param _pepper a random value used by the user to hide their identity
    */
    function getTargetAddress(
        uint256 _projectId,
        address _sender,
        uint256 _fcDeadline,
        bytes32 _pepper
    ) external view returns(address _target) {
        bytes memory _creationBytecode = type(JBAnonPayer).creationCode;
        bytes32 _salt = keccak256(abi.encode(_projectId, _sender, _fcDeadline, _pepper));

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(_creationBytecode))
        );

        return address(uint160(uint256(hash)));
    }

    /**
        @notice Deploy an anon payer on the address corresponding to a given project id, for a given sender,
                and trigger the call to pay() on the corresponding terminal.

        @dev    No access control on this deployment/pay, as the funds are considered as already in the
                Juicebox project
    */
    function deployMinion(
        uint256 _projectId,
        address _sender,
        uint256 _fcDeadline,
        bytes32 _pepper,
        address _token
    ) external {
        bytes32 _salt = keccak256(abi.encode(_projectId, _sender, _fcDeadline, _pepper));

        JBAnonPayer _minion = new JBAnonPayer{salt: _salt}(
            directory, _projectId, _sender, _fcDeadline
        );

        _minion.pay(_token);
    }
}