/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20Mock
 */
contract ERC20Mock is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        return;
    }

    function mint(address account, uint256 amount) external {
        super._mint(account, amount);
    }

    function _mint_for_testing(address account, uint256 amount) external {
        super._mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        super._burn(account, amount);
    }
}
