#!/usr/bin/env python

import datetime as dt
import pdb

print "Processing..."

with open('wikipedia-trends-bitcoin-may-2016.csv','r') as f:
    lines = f.readlines()

with open('wikipedia-trends-bitcoin-may-2016-formatted.csv','w') as f:
    f.write('Date,Value\n')
    
    for line in lines[1:]:
        dateStr, value = line.split(',')
        formattedDate = dt.datetime.strptime(dateStr,
                        "%Y/%m/%d").strftime("%d/%m/%Y %H:%M:%S")

        formattedLine = formattedDate + "," + value

        f.write(formattedLine)

print "Finished."
