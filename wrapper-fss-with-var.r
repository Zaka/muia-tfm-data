library(vars)
library(forecast)

######################################################################
############################# Wrapper FSS ############################
######################################################################

get.data.as.ts <- function() {
    bitcoinData <- read.csv(file = 'data-set.csv',
                            sep = ',')

    bitcoinData$X <- NULL
    bitcoinData$Index <- NULL
    bitcoinData$Y <- NULL
 
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

## Returns the MAE in USD of the forecast obtained from
## the model given as parameter.
test.model <- function(model, test.partition) {
    fcst <- forecast(model, h = 1)

    market.price.prediction <-
        denormalize.market.price(fcst$mean$MarketPrice[1])
    market.price.test <-
        denormalize.market.price(test.partition[[1,"MarketPrice"]])
    
    return(abs(market.price.test - market.price.prediction))
}

denormalize.market.price <- function(norm.market.price) {
    market.price.std.dev <- 218.3985
    market.price.mean <- 155.3755

    return(norm.market.price * market.price.std.dev + market.price.mean)
}

tscv.score <- function(data.ts) {
    ## The minimum partition size is = 365 * 3, 3 years
    ## This size had to be choosen because before this period there
    ## are multiple features which values are near zero, with high
    ## correlation and causing troubles in VAR function.
    K <- 1095

    mae <- c()
    
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
        mae <- c(mae, test.model(model,test.partition))
    }

    result <- mean(mae)

    return(result)
}

time.it <- function(fun,args) {
    print("Timing function...")

    ## Start the clock!
    ptm <- proc.time()

    result <- fun(args)

    ## Stop the clock
    print(paste("Elapsed time in seconds is", (proc.time() - ptm)[[3]]))

    print("Going out...")

    return(result)
}

## Wrapper Greedy Feature Subset Selection
wrapper.greedy.fss <- function() {
    data.ts <- get.data.as.ts()
    
    mae <- .Machine$integer.max
    selected.features <- c("MarketPrice")
    not.selected.features <- colnames(data.ts)
    not.selected.features <- not.selected.features[not.selected.features != "MarketPrice"]

    repeat {
        new.mae <- .Machine$integer.max
        selected.feature <- ""
        
        for (col in not.selected.features) {
            temp.selected.features <- c(selected.features, col)

            print(paste("Features been scored: ",
                        toString(temp.selected.features)))
            
            temp.mae <-time.it(
                tscv.score, data.ts[,temp.selected.features])
                
            if (temp.mae < new.mae) {
                new.mae <- temp.mae
                selected.feature <- col
            }
        }
        
        if (new.mae < mae) {
            mae <- new.mae
            selected.features <- c(selected.features, selected.feature)
            not.selected.features <-
                not.selected.features[not.selected.features != selected.feature]

            print(paste("Add new feature", toString(selected.feature)))
            print(paste("New MAE:", mae))

        } else {
            print("Finished")
            print(paste("Selected features are:", toString(selected.features)))
            break
        }
    }
}

main <- function() {
    time.it(wrapper.greedy.fss)
}
