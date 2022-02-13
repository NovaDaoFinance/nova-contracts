# ----------------------------------------------------------------------
# Script reads CSV file named "final_wl.csv" in its directory
# It writes the parsed 'address' & 'amount' for each whitelisted user
# ----------------------------------------------------------------------

import csv
from decimal import *
from brownie import *
from .contract_addresses import CONTRACTS


def fetch_founders_contract():
    return PhantomFounders.at(CONTRACTS[network.show_active()]['PhantomFounders'])


def main(account):
    acct = accounts.load(account)
    founders = fetch_founders_contract()
    with open("final_wl.csv", newline='') as f:
        reader = csv.reader(f)
        next(reader)  # Skip header
        for row in reader:
            address = row[2]
            allocation = int(Decimal(row[3]) * Decimal(1e18))
            if founders.remainingAllocation(address) == 0:
                founders.registerFounder(address, allocation, {"from": acct})
                print(reader.line_num-1, address, allocation, end='\n')
            else:
                print(f"{address} already registered!")
