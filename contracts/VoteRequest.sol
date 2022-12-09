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

    struct Voter {
        bool vote;
        uint256 weight;
    }

    // User address => staked amount
    mapping(address => uint) public balanceOf;

    constructor(address router, address voteAddr, address token) {
        _router = ICrossChainRouter(router);
        _vote = voteAddr;
        stakingToken = IERC20(token);
    }

    function requestVote() external {}

    function stake(uint _amount) external {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint _amount) external {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function setRouter(address router) public onlyOwner {
        _router = ICrossChainRouter(router);
    }

    function setVote(address voteAddr) public onlyOwner {
        _vote = voteAddr;
    }
}
