/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import "../libs/DSAuth.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IPhantomGuard} from "../../interfaces/auth/IPhantomGuard.sol";

contract DSGuardEvents {
}

contract PhantomGuard is DSAuthority, DSGuardEvents, PhantomStorageMixin, IPhantomGuard {
    bytes32 public constant ANY = bytes32(type(uint256).max);

    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => bool))) public acl;

    constructor(address storageAddress) PhantomStorageMixin(storageAddress) {
        return;
    }

    function canCall(address src_, address dst_, bytes4 sig_) public view returns (bool) {
        bytes32 src = bytes32(bytes20(src_));
        bytes32 dst = bytes32(bytes20(dst_));
        bytes32 sig = bytes32(sig_);

        return
            acl[src][dst][sig] ||
            acl[src][dst][ANY] ||
            acl[src][ANY][sig] ||
            acl[src][ANY][ANY] ||
            acl[ANY][dst][sig] ||
            acl[ANY][dst][ANY] ||
            acl[ANY][ANY][sig] ||
            acl[ANY][ANY][ANY];
    }

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public onlyRegisteredContracts {
        acl[src][dst][sig] = true;
        emit LogPermit(src, dst, sig);
    }

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public onlyRegisteredContracts {
        acl[src][dst][sig] = false;
        emit LogForbid(src, dst, sig);
    }

    function permit(address src, address dst, bytes4 sig) public onlyRegisteredContracts {
        permit(bytes32(bytes20(src)), bytes32(bytes20(dst)), bytes32(sig));
    }

    function forbid(address src, address dst, bytes4 sig) public onlyRegisteredContracts {
        forbid(bytes32(bytes20(src)), bytes32(bytes20(dst)), bytes32(sig));
    }
}