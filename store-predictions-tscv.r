library(vars)
library(forecast)

######################################################################
############################# Wrapper FSS ############################
######################################################################

get.data.as.ts <- function() {
    bitcoinData <- read.csv(file = '../muia-tfm-dataset/dataset.csv',
                            sep = ',')

    bitcoinData$NumTransactions <- NULL
    bitcoinData$TotalBitcoins <- NULL
    bitcoinData$Difficulty <- NULL
    bitcoinData$BitcoinDaysDestroyed <- NULL
    bitcoinData$CostPerTransaction <- NULL
    bitcoinData$TransactionFeesUSD <- NULL
    bitcoinData$TransactionFees <- NULL
    bitcoinData$MedianConfirmationTime <- NULL
    bitcoinData$TxTradeRatio <- NULL
    bitcoinData$TradeVolume <- NULL
    bitcoinData$OutputVolume <- NULL
    bitcoinData$WikipediaTrend <- NULL
    
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

## Returns the "denormalized" prediction for MarketPrice
test.model <- function(model, test.partition) {
    fcst <- forecast(model, h = 1)

    market.price.prediction <-
        denormalize.market.price(fcst$mean$MarketPrice[1])

    return(market.price.prediction)
}

denormalize.market.price <- function(norm.market.price) {
    market.price.std.dev <- 218.3985
    market.price.mean <- 155.3755

    return(norm.market.price * market.price.std.dev + market.price.mean)
}

tscv.score <- function(data.ts) {
    ## This size had to be choosen because before this period there
    ## are multiple features which values are near zero, with high
    ## correlation and causing troubles in VAR function.
    K <- 1095

    predictions <- c()
    
    ## DEBUG:
    ## for (i in K:1099) {
    for (i in K:(length(data.ts[,1]) - 1)) {
        print(i)
        
        training.partition <- window(data.ts,
                                     start = 1,
                                     end = i)
        test.partition <- window(data.ts,
                                 start = i + 1,
                                 end = i + 1)

        model <- train.var.model(training.partition)

        ## Store the predicted value in a vector
        predictions <- c(predictions,
                         test.model(model,test.partition))
    }

    ## ## DEBUG Begin
    ## ## This code only for debugging

    ## pred.length <- length(predictions)

    ## mark.length <- K + pred.length

    ## market.price <- window(data.ts[,"MarketPrice"],
    ##                        start = 1,
    ##                        end = mark.length)
    
    ## ## DEBUG End
    
    market.price <- data.ts[,"MarketPrice"]
    
    predictions <- c(rep(NA,
                         length(market.price) - length(predictions)),
                     predictions)

    output.results <- data.frame(market.price, predictions)
    colnames(output.results) <- c("MarketPrice", "VAR-Prediction")
    
    ## Guardar en CSV COPÓN
    write.csv(output.results,
              file = paste("output.var.",
                           format(Sys.time(), "%Y%m%d-%H%M%S"),
                           ".csv", sep = ""),
              row.names = FALSE)
}

time.it <- function(fun,args = NULL) {
    print("Timing function...")

    ## Start the clock!
    ptm <- proc.time()

    if (is.null(args)) {
        result <- fun()
    } else {
        result <- fun(args)
    }

    ## Stop the clock
    print(paste("Elapsed time in seconds is", (proc.time() - ptm)[[3]]))

    print("Going out...")

    return(result)
}

main <- function() {
    time.it(tscv.score, get.data.as.ts())
}
