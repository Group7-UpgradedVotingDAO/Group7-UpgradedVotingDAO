// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VotingDAO} from "../src/VotingDAO.sol";

contract DeployVotingDAO is Script {
    function run() external returns (VotingDAO dao) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        dao = new VotingDAO();
        vm.stopBroadcast();
    }
}
