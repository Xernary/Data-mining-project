# read from file
library(foreign)
data <- read.arff("yeast.arff")


# PT1, PT2, PT3 implementations. PT = problem transformation from multi-lable to single-lable

# PT1

pt1.data <- data

for (i in 1:nrow(pt1.data)){
  
  #get all the values of the labels of the current row
  row.labels <- as.numeric(pt1.data[i, 104:117]) - 1
  
  #get only the labels that are set as 1 of the current row
  row.correct.labels <- as.vector(which(row.labels==1))
  
  
  # select random label
  new.label <- sample(row.correct.labels, 1)
  
  # assign the new label to the row
  pt1.data[i, 104:117] <- 0
  pt1.data[i, 103+new.label] <- 1
}



# PT2

pt2.data <- pt1.data

# gets the first 14 unique rows based on the labels only
pt2.data <- pt1.data[!duplicated(pt1.data[, 104:117]), ]



# PT3

pt3.data <- data
 
for (i in 1:nrow(pt3.data)){
  
  
  #get all the values of the labels of the current row
  row.labels <- as.numeric(pt3.data[i, 104:117]) - 1
  
  #get only the labels that are set as 1 of the current row
  row.correct.labels <- as.vector(which(row.labels==1))
  
  col.name <- ''
  c <- 1
  for(j in row.correct.labels){
    temp <- paste('∩', paste('class' , as.character(j), sep = ''), sep = '')
    if(c == 1) temp <- paste('class' , as.character(j), sep = '')
    col.name <- paste(col.name, temp, sep = '')
    col.name <- paste(col.name, '_', sep = '')
    c <- c+1
  }

  # add new column made up of label set of the instance
  pt3.data[i, col.name] <- 1
  
}

# remove old label columns
pt3.data <- pt3.data[, -104:-117]


pt3.data[is.na(pt3.data)] <- 0



# PT4

pt4.data <- data[, -104:-117]

tmp.data <- data[, 104:117]

for(i in 1:14){
  colnames(tmp.data)[which(names(tmp.data) == paste("Class", as.character(i), sep=""))] <- paste("Class", as.character(i), sep="")
}


for(i in 1:14){
  pt4.data[paste("Class", as.character(i), sep='')] <- (data[paste("Class", as.character(i), sep='')])
  pt4.data[paste("⌐Class", as.character(i), sep='')] <- (data[paste("Class", as.character(i), sep='')])
}


# Binary Relevance 

# create n different datasets each containing only one label,
# where n is the number of total labels of the original dataset

br.data <- list()
arr <- list()
for(i in 1:14){
  column <- paste('Class', i, sep = '')
  arr[[i]] <- data[column]
  br.data[[i]] <- data[-104:-117]
  br.data[[i]][column] <- arr[[i]]
}


#-----------------------------------------------------------------------------------------

# Classification CART

# CART on PT1 

pt1.data.2 <- pt1.data[, -104:-117]

for(i in 1:nrow(pt1.data.2 )){
  
  #get all the values of the labels of the current row
  row.labels <- as.numeric(pt1.data[i, 104:117]) - 1
  
  #get only the label that is set as 1 of the current row
  row.correct.label <- as.numeric(which(row.labels==1))
  
  #add the new class label column
  pt1.data.2[i, "Class"] <- as.character(row.correct.label)  #pt1_data[i,(pt1_data[1, ]) == 1] #paste("Class", pt1_data[i, ], sep="")
}



# Partitioning and sampling training and testing data
perc.splitting <- 0.75
nobs.training <- round(perc.splitting*nrow(pt1.data.2))
sampled.pos <- sample(1:nrow(pt1.data.2),nobs.training)
pt1.training <- pt1.data.2[sampled.pos,]
pt1.testing <- pt1.data.2[-sampled.pos,]
true.classes <- pt1.testing[,104]
pt1.testing <- pt1.testing[,-104]



# CART

library(rpart)
library(rpart.plot)

#cp = “value” is the assigned a numeric value that will determine how deep you want your tree to grow.
#The smaller the value (closer to 0), the larger the tree. The default value is 0.01, which will render a very pruned tree.
pt1.cart <- rpart(Class ~ ., data = pt1.training,  cp = 0.001) 

pt1.cart

printcp(pt1.cart)

rpart.plot(pt1.cart)

rpart.plot(pt1.cart, type = 0, extra = 104)

# cp and error info
pt1.cart$cptable

plotcp(pt1.cart)

rpart.rules(pt1.cart,cover = T)

#PRUNING 

# Choosing best CP (relerror+xstd < xerror)
best.cp <- pt1.cart$cptable[2,"CP"]
pt1.cart.pruned <- prune(pt1.cart, cp=best.cp)
rpart.plot(pt1.cart.pruned, type = 0, extra = 104)

rpart.rules(pt1.cart.pruned,cover = T)


# ACCURACY 

predict(pt1.cart.pruned, pt1.testing)
cart.predict <- predict(pt1.cart,pt1.testing,type="class")
cart.predict.pruned <- predict(pt1.cart.pruned,pt1.testing,type="class")
cart.results <- data.frame(real=true.classes,predicted=cart.predict)
cart.pruned.results <- data.frame(real=true.classes,predicted=cart.predict.pruned)
cart.accuracy <- sum(c==cart.results$predicted)/nrow(cart.results)
cart.pruned.accuracy <- sum(cart.pruned.results$real==cart.pruned.results$predicted)/nrow(cart.pruned.results)


# Data conversion from single-lable to multi-lable format

# converts pt1 predicted data to multi-label formal
pt1.predicted.multi <- data.frame(matrix(nrow=nrow(cart.pruned.results), ncol=14))
for(i in 1:nrow(cart.pruned.results)){
  pt1.predicted.multi[i,] <- 0
  pt1.predicted.multi[i, as.numeric(as.character(cart.pruned.results[i,2]))] <- 1
}


# JACCARD SIMILARITY

# calculate jaccard similarity of data in multi-label format
calculate.jaccard <- function(predicted.data.classes, true.data.classes){
  total.jaccard <- 0
  row.jaccard <- 0
  for(i in 1:nrow(true.data.classes)){
    a <- 0
    b <- 0
    c <- 0
    for(j in 1:ncol(true.data.classes)){
      if((true.data.classes[i,j] == predicted.data.classes[i,j]) && predicted.data.classes[i,j] == 1) {a <- a+1}
      else if(true.data.classes[i,j] == 0 && predicted.data.classes[i,j] == 1) {b <- b+1}
      else if(true.data.classes[i,j] == 1 && predicted.data.classes[i,j] == 0) {c <- c+1}
    }
    row.jaccard <- a / (a + b + c)
    total.jaccard <- total.jaccard + row.jaccard
  }
  return (total.jaccard / nrow(true.data.classes))
}

pt1.true.multi <- data[-sampled.pos,]
pt1.jaccard <- calculate.jaccard(pt1.predicted.multi, pt1.true.multi[, 104:117])


#--------------------------------------------------------------------------------------------------

# CART on PT2

pt2.data.2 <- pt2.data[, -104:-117]

for(i in 1:nrow(pt2.data.2 )){
  
  #get all the values of the labels of the current row
  row.labels <- as.numeric(pt2.data[i, 104:117]) - 1
  
  #get only the label that is set as 1 of the current row
  row.correct.label <- as.numeric(which(row.labels==1))
  
  #add the new class label column
  pt2.data.2 [i, "Class"] <- as.character(row.correct.label)  #pt1_data[i,(pt1_data[1, ]) == 1] #paste("Class", pt1_data[i, ], sep="")
}




#all the dataset will be used so perc.splitting = 1
#only the 13 tuples with unique classes will be used for training (pt2.data.2)
#the full dataset will be used as testing (pt1.data.2)
perc.splitting <- 1
nobs.training <- round(perc.splitting*nrow(pt2.data.2))
sampled.pos <- sample(1:nrow(pt2.data.2),nobs.training)
pt2.training <- pt2.data.2[sampled.pos,]
pt2.testing <- pt1.data.2
true.classes <- pt2.testing[,104]
pt2.testing <- pt2.testing[,-104]


# CART


#cp = “value” is the assigned a numeric value that will determine how deep you want your tree to grow.
#The smaller the value (closer to 0), the larger the tree. The default value is 0.01, which will render a very pruned tree.
pt2.cart <- rpart(Class ~ ., data = pt2.training,  cp = 0.001)

pt2.cart

printcp(pt2.cart)

rpart.plot(pt2.cart, box.palette="Blues")



rpart.plot(pt2.cart, type = 0, extra = 104, box.palette="Blues")

pt2.cart$cptable

plotcp(pt2.cart)

rpart.rules(pt2.cart,cover = T)

#PRUNING 

# Choosing best CP (relerror+xstd < xerror)
best.cp <- pt2.cart$cptable[1,"CP"]
pt2.cart.pruned <- prune(pt2.cart, cp=best.cp)
rpart.plot(pt2.cart.pruned, type = 0, extra = 104, box.palette="Blues")

rpart.rules(pt2.cart.pruned,cover = T)


# ACCURACY 

predict(pt2.cart.pruned, pt2.testing)
cart.predict <- predict(pt2.cart,pt2.testing,type="class")
cart.predict.pruned <- predict(pt2.cart.pruned,pt2.testing,type="class")
cart.results <- data.frame(real=true.classes,predicted=cart.predict)
cart.pruned.results <- data.frame(real=true.classes,predicted=cart.predict.pruned)
cart.accuracy <- sum(cart.results$real==cart.results$predicted)/nrow(cart.results)
cart.pruned.accuracy <- sum(cart.pruned.results$real==cart.pruned.results$predicted)/nrow(cart.pruned.results)


# Data conversion from single-lable to multi-lable format

# converts pt1 predicted data to multi-label formal
pt2.predicted.multi <- data.frame(matrix(nrow=nrow(cart.pruned.results), ncol=14))
for(i in 1:nrow(cart.pruned.results)){
  pt2.predicted.multi[i,] <- 0
  pt2.predicted.multi[i, as.numeric(as.character(cart.pruned.results[i,2]))] <- 1
}


# JACCARD SIMILARITY

pt2.true.multi <- data[-sampled.pos,]
pt2.jaccard <- calculate.jaccard(pt2.predicted.multi, pt2.true.multi[, 104:117])

#-----------------------------------------------------------------------------------------------



# CART on PT3

pt3.data.2 <- pt3.data[, -104:-ncol(pt3.data)]


for(i in 1:nrow(pt3.data.2)){

  #get all the values of the labels of the current row
  row.labels <- as.numeric(pt3.data[i, 104:ncol(pt3.data)])

  #get only the label that is set as 1 of the current row
  row.correct.label <- as.numeric(which(row.labels==1))

  #add the new class label column
  pt3.data.2[i, "Class"] <- as.character(row.correct.label) 

}

# Partitioning and sampling training and testing data
perc.splitting <- 0.75
nobs.training <- round(perc.splitting*nrow(pt3.data.2))
sampled.pos <- sample(1:nrow(pt3.data.2),nobs.training)
pt3.training <- pt3.data.2[sampled.pos,]
pt3.testing <- pt3.data.2[-sampled.pos,]
true.classes <- pt3.testing[,104]
pt3.testing <- pt3.testing[,-104]


#1) CART

library(rpart)
library(rpart.plot)

#cp = “value” is the assigned a numeric value that will determine how deep you want your tree to grow.
#The smaller the value (closer to 0), the larger the tree. The default value is 0.01, which will render a very pruned tree.
pt3.cart <- rpart(Class ~ ., data = pt3.training,  cp = 0.001)

pt3.cart

printcp(pt3.cart)

rpart.plot(pt3.cart)



rpart.plot(pt3.cart, type = 0, extra = 104)

pt3.cart$cptable

plotcp(pt3.cart)

rpart.rules(pt3.cart,cover = T)

#PRUNING

# Choosing best CP (relerror+xstd < xerror)
best.cp <- pt3.cart$cptable[6,"CP"]
pt3.cart.pruned <- prune(pt3.cart, cp=best.cp)
rpart.plot(pt3.cart.pruned, type = 0, extra = 104)

rpart.rules(pt3.cart.pruned,cover = T)


# ACCURACY

predict(pt3.cart.pruned, pt3.testing)
cart.predict <- predict(pt3.cart,pt3.testing,type="class")
cart.predict.pruned <- predict(pt3.cart.pruned,pt3.testing,type="class")
cart.results <- data.frame(real=true.classes,predicted=cart.predict)
cart.pruned.results <- data.frame(real=true.classes,predicted=cart.predict.pruned)
cart.accuracy <- sum(cart.results$real==cart.results$predicted)/nrow(cart.results)
cart.pruned.accuracy <- sum(cart.pruned.results$real==cart.pruned.results$predicted)/nrow(cart.pruned.results)



# Data conversion from single-lable to multi-lable format

pt3.predicted.multi <- data.frame(matrix(nrow=nrow(cart.pruned.results), ncol=14))
pt3.classes <- pt3.data[104:ncol(pt3.data)]

for(i in 1:nrow(cart.pruned.results)){
  pt3.predicted.multi[i,] <- 0
  
  # condition check selected column name in pt3.data
  for(j in 1:14){
    if(grepl( paste('class', paste(as.character(j), '_', sep=''), sep=''), names(pt3.classes)[as.numeric(as.character(cart.pruned.results[i,2]))])){
      pt3.predicted.multi[i, j] <- 1
    }
  }
}




# converts pt3 predicted data to multi-label formal
pt3.predicted.multi <- data.frame(matrix(nrow=nrow(cart.pruned.results), ncol=ncol(pt3.data[, -1:-103])))
for(i in 1:nrow(cart.pruned.results)){
  pt3.predicted.multi[i,] <- 0
  pt3.predicted.multi[i, as.numeric(as.character(cart.pruned.results[i,2]))] <- 1
}


# JACCARD SIMILARITY

pt3.true.multi <- data[-sampled.pos,]
pt3.jaccard <- calculate.jaccard(pt3.predicted.multi, pt3.true.multi[, -1:-103])


#--------------------------------------------------------------------------------------------------


# CART on PT4 (not applicable because instances have more than one label)
# PT4 is the exact same as Binary Relevance, the data is just represented in multi-label format in pt4 

library(e1071)


# SVM on Binary Relevance 

br.predicted.multi <- data.frame(matrix(nrow=nrow(cart.pruned.results), ncol=14))

# Do SVM for each different dataframe in br.data list, where every dataframe has only one 
# of the 14 total classes
for(i in 1:14){
  # Splitting and sampling data
  current <- data.frame(br.data[i])
  colnames(current)[104] <- "Class"
  nobs.training <- round(perc.splitting*nrow(current))
  sampled.pos <- sample(1:nrow(current),nobs.training)
  br.training <- current[sampled.pos,]
  br.testing <- current[-sampled.pos,]
  true.classes <- br.testing[,104]
  br.testing <- br.testing[,-104]
  
  
  # SVM
  
  library(e1071)
  
  # Trying all the possible kernels
  br.svm <- svm(Class ~ ., data = br.training, probability=T, type="C")
  br.svm.linear <- svm(Class ~ ., data = br.training, kernel="linear", type="C")
  br.svm.polynomial <- svm(Class ~ ., data = br.training, kernel="polynomial", type="C")
  br.svm.sigmoid <- svm(Class ~ ., data = br.training, kernel="sigmoid", type="C")
  
  br.svm
  
  #Prediction
  svm.predict <- predict(br.svm,br.testing,type="class")
  svm.predict.linear <- predict(br.svm.linear,br.testing,type="class")
  svm.predict.polynomial <- predict(br.svm.polynomial,br.testing,type="class")
  svm.predict.sigmoid <- predict(br.svm.sigmoid,br.testing,type="class")
  
  #Getting results
  svm.results <- data.frame(real=true.classes,predicted=svm.predict)
  svm.results.linear <- data.frame(real=true.classes,predicted=svm.predict.linear)
  svm.results.polynomial <- data.frame(real=true.classes,predicted=svm.predict.polynomial)
  svm.results.sigmoid <- data.frame(real=true.classes,predicted=svm.predict.sigmoid)
  
  #Accuracy
  svm.accuracy <- sum(svm.results$real==svm.results$predicted)/nrow(svm.results)
  svm.accuracy.linear <- sum(svm.results.linear$real==svm.results.linear$predicted)/nrow(svm.results.linear)
  svm.accuracy.polynomial <- sum(svm.results.polynomial$real==svm.results.polynomial$predicted)/nrow(svm.results.polynomial)
  svm.accuracy.sigmoid <- sum(svm.results.sigmoid$real==svm.results.sigmoid$predicted)/nrow(svm.results.sigmoid)
  
  #Choosing the results with the higher accuracy value
  best.svm.results <- svm.results.polynomial
 
  br.predicted.multi[, i] <- 0
  br.predicted.multi[, i] <- best.svm.results[, 2]
}


br.true.multi <- data[-sampled.pos, ]
br.jaccard <- calculate.jaccard(br.predicted.multi, br.true.multi[, 104:117])



