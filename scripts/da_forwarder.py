# ----------------------------------------------------------------------
# Script reads CSV file named "final_wl.csv" in its directory
# It writes the parsed 'address' & 'amount' for each whitelisted user
# ----------------------------------------------------------------------

import csv
from decimal import *
from collections import Counter
import time

from brownie import *
from .contract_addresses import CONTRACTS


def fetch_auctionclaim_contract():
    return PhantomAuctionClaim.at(CONTRACTS[network.show_active()]['PhantomAuctionClaim'])



def main(account):
    acct = accounts.load(account)
    allocations = Counter()

    with open("auction_claims.csv", newline='') as f:
        reader = csv.reader(f)
        next(reader)  # Skip header
        i = 0

        for row in reader:
            allocation = int(Decimal(row[2]) * Decimal(1e18))
            allocations[row[1]] += allocation
            print(f'Iteration {i}: Added {allocation} FRAX to wallet {row[1]}')
            i += 1
        print(f'Total frax committed: {sum(allocations.values())}')
        print(f'Total aPHM allotment: {int(Decimal(sum(allocations.values())) / Decimal(50))}')
        print(f'Total wallets: {len(allocations)}')

    auctionclaim = fetch_auctionclaim_contract()
    for wallet, frax in allocations.items():
        if auctionclaim.remainingAllotment(wallet) > 0:
            print(f'{wallet} already registered')
            time.sleep(0.25)
            continue
        auctionclaim.registerAllotment(wallet, frax, {"from": acct})
