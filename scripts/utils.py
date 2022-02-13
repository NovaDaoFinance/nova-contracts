from brownie import *

from .contract_addresses import CONTRACTS

TEN18 = 10**18


def publish():
    if network.show_active() in ["development", "ftm-test"]:
        return False
    else:
        return True


def set_deployed_status():
    return False
    # if network.show_active() in ["ftm-test"]:
    #     return False
    # else:
    #     return True


def is_deployed(contract_name):
    return CONTRACTS[network.show_active()][contract_name] != ''


def fetch_storage_contract():
    return PhantomStorage.at(CONTRACTS[network.show_active()]['PhantomStorage'])