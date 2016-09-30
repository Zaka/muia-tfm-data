library(xts)

main <- function() {
    data <- read.csv(file = 'data-set.csv', sep = ',')

    data$Date <- as.Date(as.character(data$Date), format('%Y-%m-%d'))

    ts.MarketPrice <- ts(data$MarketPrice, frequency = 365.25)

    decomposition.stl <- stl(ts.MarketPrice,
                             t.window = 15,
                             s.window = "periodic",
                             robust = TRUE)

    decomposition.df <- as.data.frame(decomposition.stl$time.series)

    decom.col.names <- colnames(decomposition.df)
    
    decomposition.df$MarketPrice <- ts.MarketPrice

    decomposition.df <- decomposition.df[c('MarketPrice', decom.col.names)]
    
    write.csv(decomposition.df, 'MarketPrice.csv', row.names=F)
}

