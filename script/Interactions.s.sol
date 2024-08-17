// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script{

    address private constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // 2nd address in input.json [index = 1]
    // this is actually also the default anvil address no. 1 [index = 0]
    uint256 private constant CLAIMING_AMOUNT = 25000000000000000000;
    bytes32 private constant PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 private constant PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [PROOF_ONE , PROOF_TWO];
    bytes private signature = hex"53664c6a72469973e51ccc89aa148ea8801200cfbc32e51d90f78c7e32918c152b1f3a6cb187e33e78884581d2543d6cf500d22cc34bc3e5a0ac9c00b27715ac1c";
    // got this sig my running the following 2 commands in CLI

    // FIRST
    // cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0  "getMessageHash(address,uint256)(bytes32)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 25000000000000000000 --rpc-url http://127.0.0.1:8545

    // 1. 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 -> MerkleAirdrop contract address (run make deploy)
    // 2. 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 -> address to pass in getMessageHash [this is the CLAIMING_ADDRESS]
    // 3. 25000000000000000000 -> amount to pass in getMessageHash [this is the CLAIMING_AMOUNT]

    // 4. for this address , the output comes out to be -> 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
    // this is the digest , the message hash , which now needs to be signed

    // SECOND
    // cast wallet sign --no-hash 0xd02c55a314e3df0be7e4396945a2b09a2695cc6c82fb9ea4d5cdf501340974b7 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 

    // sign the above digest
    // 1. 0xd02c55a314e3df0be7e4396945a2b09a2695cc6c82fb9ea4d5cdf501340974b7 -> digest
    // 2. 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -> pvt key of the first default anvil (jis account ka paisa claim karna he , usi se to sign karke denge bhai)

    error __ClaimAirdropScript__InvalidSignatureLength();

    function claimAirdrop(address airdrop) public{
        vm.startBroadcast();
        (uint8 v , bytes32 r , bytes32 s) = splitSig(signature);
        MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS , CLAIMING_AMOUNT , proof , v , r , s);
        vm.stopBroadcast();
    }

    function splitSig(bytes memory sig) public pure returns (uint8 v , bytes32 r , bytes32 s){
        if (sig.length != 65) {
            revert __ClaimAirdropScript__InvalidSignatureLength();
        }   
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() external{
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop" , block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }
}