library(vars)
library(forecast)

get.data.as.ts <- function() {
    bitcoinData <- read.csv(file = 'data-set.csv',
                            sep = ',')

    bitcoinData$X <- NULL
    bitcoinData$NumTransactionsPerBlock <- NULL
    bitcoinData$NetworkDeficit <- NULL
    bitcoinData$TotalBitcoins <- NULL

    bitcoinData.ts <- as.ts(bitcoinData, frequency = 365.25)

    return(bitcoinData.ts)
}

## Get partition of all elements but the 7 last ones
get.train.partition <- function() {
    return(window(data.ts,
                  end = length(data.ts[,1]) - 8))
}

## Get a partition containing the last 7 elements
get.test.partition <- function() {
    return(window(data.ts,
                  start = length(data.ts[,1] - 7)))
}

get.var.model.for.ts <- function(data.ts) {
    selection <- VARselect(data.ts, lag.max = 8,
                           type = "const")$select

    minLag <- get.min.max.lags(selection)[1]
    maxLag <- get.min.max.lags(selection)[2]

    lagResult <- 1

    for (i in minLag:maxLag) {
        lagResult <- i
        var <- VAR(data.ts,
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

get.min.max.lags <- function(selection) {
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

get.forecast.of.var <- function() {
    return(forecast(get.var.model.for.ts(get.train.partition())))
}

compute.accuracy.of.forecast <- function() {
    forecast.accuracy <- accuracy(get.forecast.of.var(),
                                  x = data.ts)
    return(forecast.accuracy)
}

data.ts <- get.data.as.ts()

## Here are the results for MarketPrice accuracy after executing
## compute.accuracy.of.forecast():
## > forecast.accuracy <- compute.accuracy.of.forecast()
## > forecast.accuracy[,c("RMSE", "MAE","MAPE", "MASE")]
##
##                                RMSE        MAE     MAPE      MASE
## MarketPrice Training set 0.06039109 0.02225178 3.694272 1.0801889
## MarketPrice Test set     0.06114036 0.05217996 3.766113 2.5330198

