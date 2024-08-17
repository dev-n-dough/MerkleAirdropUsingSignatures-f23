// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeployMerkleAirdrop is Script{

    bytes32 public constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4; // copied from ./target/output.json
    uint256 public amountToAirdrop = 25 * 1e18; 
    uint256 public initialContractBalance = amountToAirdrop * 4; // amount the airdrop contract must have 

    function deployMerkleAirdrop() public returns(MerkleAirdrop,BagelToken){
        vm.startBroadcast();
        BagelToken token = new BagelToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(ROOT,token);
        token.mint(address(airdrop),initialContractBalance);
        vm.stopBroadcast();
        return (airdrop,token);
    }

    function run() public returns(MerkleAirdrop,BagelToken){
        return deployMerkleAirdrop();
    }
}