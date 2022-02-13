/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {ERC20} from "./SolmateERC20.sol";
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IfPHM} from "../../../interfaces/core/erc20/IfPHM.sol";

/**
 * @title fPHM
 * @author PhantomDao Team
 * @notice The Founder Phantom Token
 */
contract fPHM is IfPHM, ERC20, PhantomStorageMixin {
    using PRBMathUD60x18 for uint256;

    mapping(address => bool) public isApprovedAddress;
    uint256 private immutable _cap;

    constructor(address storageFactoryAddress, uint256 cap_)
        ERC20("Founder Phantom", "fPHM", 18)
        PhantomStorageMixin(storageFactoryAddress)
    {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;

        _addApprovedAddress(address(this));
        _addApprovedAddress(address(PhantomVault()));
        _addApprovedAddress(address(PhantomTreasury()));
        _addApprovedAddress(address(0x0000));
    }

    //=================================================================================================================
    // Internal functions
    //=================================================================================================================

    function _addApprovedAddress(address addr) internal {
        isApprovedAddress[addr] = true;
    }

    function _removeApprovedAddress(address addr) internal {
        isApprovedAddress[addr] = false;
    }

    //=================================================================================================================
    // External functions
    //=================================================================================================================

    function addApprovedAddress(address addr) external onlyRegisteredContracts {
        _addApprovedAddress(addr);
    }

    function addApprovedAddresses(address[] calldata addrs) external onlyRegisteredContracts {
        for (uint256 iteration; addrs.length > iteration; iteration++) {
            _addApprovedAddress(addrs[iteration]);
        }
    }

    function removeApprovedAddress(address addr) external onlyRegisteredContracts {
        _removeApprovedAddress(addr);
    }

    function removeApprovedAddresses(address[] calldata addrs) external onlyRegisteredContracts {
        for (uint256 iteration; addrs.length > iteration; iteration++) {
            _removeApprovedAddress(addrs[iteration]);
        }
    }

    //=================================================================================================================
    // Public functions
    //=================================================================================================================

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    //=================================================================================================================
    // ERC20 Overrides
    //=================================================================================================================

    function burn(address account, uint256 amount) external onlyRegisteredContracts {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external onlyRegisteredContracts {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            (isApprovedAddress[from] == true || isApprovedAddress[to] == true),
            "Account not approved to transfer fPHM."
        );
    }
}