// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "../src/LimeToken.sol";
import "../src/StakeToken.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");
        vm.startBroadcast(deployerPrivateKey);

        IERC20 limeToken = new LimeToken();
        StakeToken stakeToken = new StakeToken(limeToken);

        vm.stopBroadcast();
    }
}
