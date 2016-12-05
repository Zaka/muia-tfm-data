library(vars)
library(forecast)

get.var.with.optimized.lag <- function() {
    bitcoinData <- read.csv(file = 'data-set.csv',
                            sep = ',')

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
