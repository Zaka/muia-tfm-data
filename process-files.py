#!/usr/bin/env python3

import pandas as pd
import numpy as np

print("Processing...")

# Transform dates to ISO 8601 date format

files = [ 'bitcoin-days-destroyed.csv', 'blocks-size.csv',
          'cost-per-transaction-percent.csv',
          'cost-per-transaction.csv', 'difficulty.csv',
          'estimated-transaction-volume-usd.csv',
          'estimated-transaction-volume.csv',
          'euro-price-in-usd.csv', 'hash-rate.csv',
          'market-cap.csv', 'market-price.csv',
          'median-confirmation-time.csv',
          'miners-revenue.csv',
          'n-transactions-excluding-chains-longer-than-10.csv',
          'n-transactions-excluding-chains-longer-than-100.csv',
          'n-transactions-excluding-chains-longer-than-1000.csv',
          'n-transactions-excluding-chains-longer-than-10000.csv',
          'n-transactions-excluding-popular.csv',
          'n-transactions-multiple.csv',
          'n-transactions-per-block.csv',
          'n-transactions-total.csv', 'n-transactions.csv',
          'n-unique-addresses.csv', 'network-deficit.csv',
          'output-volume.csv', 'standard-and-poors-500.csv',
          'total-bitcoins.csv', 'trade-volume.csv',
          'transaction-fees-usd.csv', 'transaction-fees.csv',
          'tx-trade-ratio.csv',
          'wikipedia-trends-bitcoin-may-2016.csv' ]

for f in files:
    df = pd.read_csv(f, parse_dates=True,
                     dayfirst=True, index_col=0)

    # Reindex between first and last date
    first = df.first_valid_index()
    last = df.last_valid_index()

    if first > last:
        temp = first.copy()
        first = last
        last = temp
    
    idx = pd.date_range(first, last)
    df = df.reindex(idx, fill_value='NaN')

    # Transform column type to float64

    df = df.astype(np.float64)
    
    # Interpolate missing dates

    df = df.interpolate()
    df.to_csv(f)

print("Finished!!")
