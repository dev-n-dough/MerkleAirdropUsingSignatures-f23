// SPDX-License-Indentifier: MIT

pragma solidity 0.8.25;

import {Test,console} from "forge-std/Test.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol"; // not really used zksync throughout the project tho
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

contract TestMerkleAirdrop is ZkSyncChainChecker, Test{
    BagelToken public token;
    MerkleAirdrop public airdrop;
    DeployMerkleAirdrop deployer;
    address user;
    uint256 userPrivKey;
    address gasPayer;

    bytes32 public constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public amountToWithdraw = 25 * 1e18;
    uint256 public initialContractBalance = amountToWithdraw * 4;
    bytes32 public proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 public proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne,proofTwo];

    function setUp() public{
        if(!isZkSyncChain()){
            // deploy using script
            deployer = new DeployMerkleAirdrop();
            (airdrop,token) = deployer.run();
        }
        token = new BagelToken();
        airdrop = new MerkleAirdrop(ROOT,token);
        token.mint(address(airdrop), initialContractBalance);
        (user,userPrivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    } 

    function testUserCanClaim() public{
        uint256 startingBalance = token.balanceOf(user);
        bytes32 digest = airdrop.getMessageHash(user , amountToWithdraw);

        // user signs the message
        (uint8 v , bytes32 r , bytes32 s ) = vm.sign(userPrivKey,digest);

        vm.prank(gasPayer);
        airdrop.claim(user , amountToWithdraw , PROOF , v , r , s);

        uint256 endingBalance = token.balanceOf(user);
        console.log("Ending user balance ", endingBalance);
        assertEq(endingBalance - startingBalance , amountToWithdraw);
    }

}