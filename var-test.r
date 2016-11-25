library(vars)
library(forecast)

get.var.with.optimized.lag <- function() {
    bitcoinData <- read.csv(file = 'data-set.csv',
                            sep = ',')

    ## DONE: Test removing correlated variables with
    ## coeficients greater than 0.9
    bitcoinData$X <- NULL
    bitcoinData$NumTransactionsPerBlock <- NULL
    bitcoinData$NetworkDeficit <- NULL
    bitcoinData$TotalBitcoins <- NULL

    bitcoinData.ts <- as.ts(bitcoinData, frequency = 365.25)
    
    selection <- VARselect(bitcoinData.ts, lag.max = 8,
                           type = "const")$select

    minLag <- getMinMaxLags(selection)[1]
    maxLag <- getMinMaxLags(selection)[2] 

    lagResult <- 1

    for (i in minLag:maxLag) {
        lagResult <- i
        var <- VAR(bitcoinData.ts,
                   p = lagResult,
                   type = "const")

        test <- serial.test(var, lags.pt = 10,
                            type = "PT.asymptotic")

        if (test$serial$p.value < 0.05) {
            break
        }
    }

    return(var)
}

getMinMaxLags <- function(selection) {
    minLag <- .Machine$double.xmax
    maxLag <- .Machine$double.xmin
    
    for (i in 1:length(selection)) {
        if (minLag > selection[[i]]) {
            minLag <- selection[[i]]
        }

        if (maxLag < selection[[i]]) {
            maxLag <- selection[[i]]
        }
    }

    return(c(minLag, maxLag))
}

plot.forecast <- function() {
    ## Use "options(error = recover)" to debug the code.

    fcst <- forecast(get.var.with.optimized.lag())
    plot(fcst)
}

######################################################################
######################################################################
####################### Train/Test validation ########################
######################################################################
######################################################################

## TODO: Asses the accuracy of the prediction obtained

## The function accuracy can be used on a forecast like this:
## accuracy(fcst)

## 0 - Partition the time series
## 1 - Asses the accuracy on a single partitioned set.
## 1.1 - Pick a partition of all but the last 7 entries of each ts
## 1.2 - Get a VAR model and a forecast of 1,2,3,4,5,6,7 days ahead.
## 1.3 - Asses the accuracy of that prediction using the 7 last data
## points of the data-set.

######################################################################
######################################################################
###################### Rolling cross validation ######################
######################################################################
######################################################################
