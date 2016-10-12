options(show.error.locations = TRUE)

library(forecast)

## Forecast seasonal component with seasonal naïve model

marketPrice.data <- read.csv(file = '~/projects/muia-tfm-data/MarketPrice.csv',
                             sep = ',')

marketPrice.ts <- ts(marketPrice.data$seasonal,
                     start = c(2009,3),
                     frequency = 365.25)

nValid <- 14
nTrain <- length(marketPrice.ts) - nValid

t <- seq(from = as.Date('2009-01-03'), by = "day", length = nTrain)
train.ts <- window(marketPrice.ts,
                   start = c(2009, 3),
                   end = c(2009, 3 + nTrain - 1))

tNew <- seq(from = as.Date('2009-01-03') + nTrain,
            by = "day", length = nValid)

validation.ts <- window(marketPrice.ts,
                        start = c(2009, 3 + nTrain))

fit <- snaive(train.ts, h = nValid)

plot(fit)
lines(validation.ts, col = "green")


