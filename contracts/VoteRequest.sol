// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/ICrossChainRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VoteRequest is Ownable {
    IERC20 public immutable stakingToken;
    ICrossChainRouter private _router;
    address private _vote;

    uint public totalSupply;

    // User address => staked amount
    mapping(address => uint) public balanceOf;

    constructor(address router, address voteAddr, address token) {
        _router = ICrossChainRouter(router);
        _vote = voteAddr;
        stakingToken = IERC20(token);
    }

    function requestVote(
        bool vote,
        uint32 protocolId,
        uint32 dstChainId,
        uint256 proposalId
    ) external payable {
        bytes memory p = abi.encode(vote, msg.sender, proposalId);
        bytes memory payload = abi.encode(1, p);
        _router.sendMessage{value: msg.value}(
            protocolId,
            dstChainId,
            msg.value,
            _vote,
            payload
        );
    }

    function stake(
        uint _amount,
        uint32 protocolId,
        uint32 dstChainId
    ) external payable {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;

        bytes memory p = abi.encode(_amount, msg.sender);
        bytes memory payload = abi.encode(2, p);
        _router.sendMessage{value: msg.value}(
            protocolId,
            dstChainId,
            msg.value,
            _vote,
            payload
        );
    }

    function withdraw(
        uint _amount,
        uint32 protocolId,
        uint32 dstChainId
    ) external payable {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);

        bytes memory p = abi.encode(_amount, msg.sender);
        bytes memory payload = abi.encode(3, p);
        _router.sendMessage{value: msg.value}(
            protocolId,
            dstChainId,
            msg.value,
            _vote,
            payload
        );
    }

    function setRouter(address router) public onlyOwner {
        _router = ICrossChainRouter(router);
    }

    function setVote(address voteAddr) public onlyOwner {
        _vote = voteAddr;
    }
}
