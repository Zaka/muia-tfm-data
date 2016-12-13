library(vars)
library(forecast)

######################################################################
######################################################################
#################### Time series cross-validation ####################
######################################################################
######################################################################

## Choose a minimum partition size K

## For i in 1:length(data.ts):
##     * Create a model from a partition of size k, containing elements
##       i to K + i.
##     * Test the model using the (K + i + 1)-th element.
##     * Store the result of the test in a vector (if there are various
##       tests, store a vector per test)

## Compare the results with other models results

## Results:
##     "MAE:  0.0376852459544154"
##     user   system  elapsed 
## 1209.608 3552.036  727.973

## Given that MarketPrice was normalized using this formula:
## (MarketPrice - MarketPriceMean) / MarketPriceStdDev
## MarketPriceMean = 155.3755406486043852965
## MarketPriceStdDev = 218.3984954558443689621
## we can find the MAE in USD to be:
## (MarketPriceNorm * MarketPriceStdDev) + MarketPriceMean = 163.6059416659321641419 USD
######################################################################

get.data.as.ts <- function() {
    bitcoinData <- read.csv(file = 'data-set.csv',
                            sep = ',')

    bitcoinData$X <- NULL
    ## bitcoinData$NumTransactionsPerBlock <- NULL
    ## bitcoinData$NetworkDeficit <- NULL
    ## bitcoinData$TotalBitcoins <- NULL

    bitcoinData.ts <- as.ts(bitcoinData, frequency = 365.25)

    return(bitcoinData.ts)
}

train.var.model <- function(training.partition) {
    selection <- VARselect(training.partition, lag.max = 8,
                           type = "const")$select

    minLag <- get.min.max.lags(selection)[1]
    maxLag <- get.min.max.lags(selection)[2]

    lagResult <- 1

    for (i in minLag:maxLag) {
        lagResult <- i
        var <- VAR(training.partition,
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

test.model <- function(model, test.partition) {
    fcst <- forecast(model, h = 1)
    forecast.accuracy <- accuracy(fcst,
                                  x = test.partition)

    return(forecast.accuracy["MarketPrice Test set","MAE"])
}

main <- function() {
    ## The minimum partition size is = 365 * 3, 3 years
    ## This size had to be choosen because before this period there
    ## are multiple features which values are near zero, with high
    ## correlation and causing troubles in VAR function.
    K <- 1095

    data.ts <- get.data.as.ts()

    mae <- c()
    
    ## DEBUG:
    for (i in K:(length(data.ts[,1]) - 1)) {
        ## for (i in K:411) {

        print(i)
        
        training.partition <- window(data.ts,
                                     start = 1,
                                     end = i)
        test.partition <- window(data.ts,
                                 start = i + 1,
                                 end = i + 1)

        model <- train.var.model(training.partition)
        mae <- c(mae, test.model(model,test.partition))
    }

    result <- mean(mae)

    print(paste("MAE: ", result))
}

time.function <- function(fun) {
    print("Entrying time.function")

    ## Start the clock!
    ptm <- proc.time()

    fun()

    ## Stop the clock
    print(proc.time() - ptm)

    print("Going out...")
}
