# read from file
library(foreign)
data <- read.arff("yeast.arff")




# PT1, PT2, PT3 implementations. PT = problem transformation from multi-lable to single-lable

# PT1

pt1_data <- data

for (i in 1:nrow(pt1_data)){
  
  #get all the values of the labels of the current row
  row.labels <- as.numeric(pt1_data[i, 104:117]) - 1
  
  #get only the labels that are set as 1 of the current row
  row.correct.labels <- as.vector(which(row.labels==1))
  
  
  # select random label
  new.label <- sample(row.correct.labels, 1)
  
  # assign the new label to the row
  pt1_data[i, 104:117] <- 0
  pt1_data[i, 103+new.label] <- 1
}


# PT2

pt2_data <- pt1_data

pt2_data <- pt1_data[!duplicated(pt1_data[, 104]), ]






