// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@jbx-protocol/juice-contracts-v3/contracts/system_tests/helpers/TestBaseWorkflow.sol";

import "../JBAnonPayerFactory.sol";

contract JBAnonPayerFactoryTest is TestBaseWorkflow {

    // If this gets changed without changing the `_factory` in the payer then the tests will break
    address deployer = 0x622633eb25E5dC34D5Fd38A0dC2cCCcEf6941691;
    uint256 projectId;

    JBAnonPayerFactory factory;

    // Standard Juicebox properties
    JBProjectMetadata _projectMetadata;
    JBFundingCycleData _data;
    JBFundingCycleMetadata _metadata;
    JBGroupedSplits[] _groupedSplits; // Default empty
    JBFundAccessConstraints[] _fundAccessConstraints; // Default empty
    IJBPaymentTerminal[] _terminals; // Default empty

    function setUp() public virtual override {
        super.setUp();

        evm.prank(deployer);
        factory = new JBAnonPayerFactory(
            3,
            jbDirectory()
        );

        _projectMetadata = JBProjectMetadata({content: 'myIPFSHash', domain: 1});

        _data = JBFundingCycleData({
            duration: 14,
            weight: 1000 * 10**18,
            discountRate: 450000000,
            ballot: IJBFundingCycleBallot(address(0))
            });

            _metadata = JBFundingCycleMetadata({
            global: JBGlobalFundingCycleMetadata({
                allowSetTerminals: false,
                allowSetController: false,
                pauseTransfers: false
            }),
            reservedRate: 5000, //50%
            redemptionRate: 5000, //50%
            ballotRedemptionRate: 0,
            pausePay: false,
            pauseDistributions: false,
            pauseRedeem: false,
            pauseBurn: false,
            allowMinting: false,
            allowTerminalMigration: false,
            allowControllerMigration: false,
            holdFees: false,
            preferClaimedTokenOverride: false,
            useTotalOverflowForRedemptions: false,
            useDataSourceForPay: false,
            useDataSourceForRedeem: false,
            dataSource: address(0),
            metadata: 0
        });

        _terminals.push(jbETHPaymentTerminal());
        _terminals.push(jbERC20PaymentTerminal());

        projectId = jbController().launchProjectFor(
            msg.sender,
            _projectMetadata,
            _data,
            _metadata,
            block.timestamp,
            _groupedSplits,
            _fundAccessConstraints,
            _terminals,
            ''
        );
    }

    function testRevealEth(
        address _sender,
        uint256 _fcDeadline,
        bytes32 _pepper,
        uint128 _amount
    ) public {
        // This way we don't get a 0 address or precompile addresses
        evm.assume(uint160(_sender) > 100);

        address _target = factory.getTargetAddress(
            projectId,
            _sender, 
            _fcDeadline,
            _pepper
        );

        // Fund the ghost payer
        evm.deal(_target, _amount);

        // Deploy and forward the funds to the project
        factory.deployMinion(
            projectId,
            _sender, 
            _fcDeadline,
            _pepper,
            JBTokens.ETH
        );
    }
}