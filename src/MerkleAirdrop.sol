// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import {IERC20,SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // importing IERC20 via SafeERC20
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";


contract MerkleAirdrop is EIP712{
    // make a list of users allowed to take a airdrop
    // allow any user to claim their airdrop

    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping (address claimer => bool claimed) private s_hasClaimed;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)"); 

    // this is the 'message struct'
    struct AirdropClaim { 
        address account ;
        uint256 amount ;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Claim(address account , uint256 amount);

    constructor(
        bytes32 merkleRoot,
        IERC20 airdropToken
    )
    EIP712("MerkleAirdrop" , "1"){
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(address account , uint256 amount , bytes32[] calldata merkleProof , uint8 v , bytes32 r , bytes32 s) external {
        if(s_hasClaimed[account]){
            revert MerkleAirdrop__AlreadyClaimed();
        }
        if(!_isValidSig(account , getMessageHash(account , amount) , v ,r,s)) 
        {
            revert MerkleAirdrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account,amount)))); // standard way of creating a leaf
        if(!MerkleProof.verify(merkleProof,i_merkleRoot,leaf)){ // MerkleProof is of open zeppelin
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account , amount);
        i_airdropToken.safeTransfer(account,amount);
    }

    // get the digest
    function getMessageHash(address account , uint256 amount) public view returns(bytes32){
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH , AirdropClaim({account: account , amount: amount})))
        );

        // AirdropClaim({account: account , amount: amount}) -> this isn't needed , this is just to make the code more verbose

        // _hashTypedDataV4 takes structHash(message) as input , adds all the other neccesary stuff to make it a EIP712 txn , and outputs the hash of the txn string keccak256(0x19...0x01... etc.)
    }

    function _isValidSig(address account , bytes32 digest , uint8 v , bytes32 r , bytes32 s) internal pure returns(bool){
        (address signer , , ) = ECDSA.tryRecover(digest, v, r, s);
        return (signer == account);
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getMerkleRoot() external view returns(bytes32){
        return i_merkleRoot;
    }
    function getAirdropToken() external view returns(IERC20){
        return i_airdropToken;
    }
}