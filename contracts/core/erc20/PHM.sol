/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {ERC20} from "./SolmateERC20.sol";
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";

/* Interface Imports */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IPHM} from "../../../interfaces/core/erc20/IPHM.sol";

/**
 * @title PHM
 * @author PhantomDao Team
 * @notice The Phantom Token
 */
contract PHM is IPHM, ERC20, PhantomStorageMixin {
    using PRBMathUD60x18 for uint256;

    mapping(address => bool) public uncappedHolders;

    constructor(address storageAddress) ERC20("Phantom", "PHM", 18) PhantomStorageMixin(storageAddress) {
        return;
    }


    //=================================================================================================================
    // External functions
    //=================================================================================================================

    function addUncappedHolder(address addr) external onlyRegisteredContracts {
        _addUncappedHolder(addr);
    }

    function removeUncappedHolder(address addr) external onlyRegisteredContracts {
        _removeUncappedHolder(addr);
    }

    function mint(address to, uint256 amount) external onlyRegisteredContracts {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external onlyRegisteredContracts {
        _burn(account, amount);
    }

    //=================================================================================================================
    // Public functions
    //=================================================================================================================

    function totalSupply() public view virtual override(ERC20, IERC20) returns (uint256) {
        return
            _totalSupply +
            sPHM().totalSupply() +
            gPHM().totalSupply().mul(sPHM().scalingFactor()) +
            fPHM().totalSupply().mul(sPHM().scalingFactor());
    }

    function balanceAllDenoms(address user) public view virtual returns (uint256) {
        uint256 phmBal = balanceOf(user);
        uint256 sphmBal = sPHM().balanceOf(user);
        uint256 gphmBal = gPHM().balanceToPHM(gPHM().balanceOf(user));
        uint256 fphmBal = gPHM().balanceToPHM(fPHM().balanceOf(user));
        return phmBal + sphmBal + gphmBal + fphmBal;
    }

    function maxBalancePerWallet() public view virtual returns (uint256) {
        return totalSupply() / 21;
    }

    //=================================================================================================================
    // Internal functions
    //=================================================================================================================

    function _addUncappedHolder(address addr) internal {
        uncappedHolders[addr] = true;
    }

    function _removeUncappedHolder(address addr) internal {
        delete uncappedHolders[addr];
    }

    /**
     * @dev prevent more than 4.76% ownership unless you are the treasury
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        if (to != address(PhantomVault()) && to != address(0) && uncappedHolders[to] == false) {
            require(
                balanceAllDenoms(to) < maxBalancePerWallet(), // 4.76%
                "PHM transfer blocked due to owning over 4.76% of supply"
            );
        }
    }
}
