main <- function() {
    data <- read.csv(file = 'data-set.csv', sep = ',')
    data$Date <- as.Date(as.character(data$Date), format('%Y-%m-%d'))

    store.column(data, 'MarketPrice')
}

store.column <- function(data, col.name) {
    ts.name <- paste("ts.", col.name, sep = "")
    ts.name <- ts(data[[col.name]], frequency = 365.25)

    decomposition.stl <- stl(ts.name,
                             t.window = 15,
                             s.window = "periodic",
                             robust = TRUE)

    decomposition.df <- as.data.frame(decomposition.stl$time.series)

    decom.col.names <- colnames(decomposition.df)
    
    decomposition.df[col.name] <- ts.name

    decomposition.df <- decomposition.df[c(col.name, decom.col.names)]
    
    write.csv(decomposition.df,
              paste(col.name, '.csv', sep = ""),
              row.names=F)
}
