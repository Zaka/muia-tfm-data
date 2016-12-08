main <- function() {
    bitcoinData <- read.csv(file = 'data-set.csv', sep = ',')
    bitcoinData$Date <- as.Date(as.character(bitcoinData$Date),
                                format('%Y-%m-%d'))
    bitcoinData$Date <- NULL

    diff.ts <- list()
    
    for (col in colnames(bitcoinData)) {
        diff.ts[[col]] <- diff.column(col)
    }

    return(diff.ts)
}

correlation.greater.than <- function(cor.matrix, threshold) {
    for (i in 1:nrow(cor.matrix)) {
        for (j in 1:ncol(cor.matrix)) {
            if (i != j & cor.matrix[i,j] >= threshold) {
                print(paste("(",
                            colnames(cor.matrix)[i],
                            ",",
                            colnames(cor.matrix)[j],
                            ")"))
            }                
        }
    }
}
