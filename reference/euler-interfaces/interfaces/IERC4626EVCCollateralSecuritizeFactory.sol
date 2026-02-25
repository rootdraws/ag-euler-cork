// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC4626EVCCollateralSecuritizeFactory {
    error Factory_BadQuery();

    event ContractDeployed(address indexed deployedContract, address indexed deployer, uint256 deployedAt);

    function deploy(address controllerPerspective, address asset, string memory name, string memory symbol)
        external
        returns (address);
    function deployments(uint256) external view returns (address);
    function evc() external view returns (address);
    function getDeploymentInfo(address contractAddress) external view returns (address deployer, uint96 deployedAt);
    function getDeploymentsListLength() external view returns (uint256);
    function getDeploymentsListSlice(uint256 start, uint256 end) external view returns (address[] memory list);
    function isValidDeployment(address contractAddress) external view returns (bool);
    function permit2() external view returns (address);
}
