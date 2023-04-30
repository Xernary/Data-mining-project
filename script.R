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
    temp <- paste('∩', paste('Class' , as.character(j), sep = ''), sep = '')
    if(c == 1) temp <- paste('Class' , as.character(j), sep = '')
    col.name <- paste(col.name, temp, sep = '')
    c <- c+1
    
    print(j)
  }

  # add new column made up of label set of the instance
  pt3.data[i, col.name] <- 1
  
}

# remove old label columns
pt3.data <- pt3.data[, -104:-117]


# PT4



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



# Label Power Set

# to do



# Classification CART

# CART on PT1 

pt1.data.2 <- pt1_data[, -104:-117]

for(i in 1:nrow(pt1.data.2 )){
  
  #get all the values of the labels of the current row
  row.labels <- as.numeric(pt1.data[i, 104:117]) - 1
  
  #get only the label that is set as 1 of the current row
  row.correct.label <- as.numeric(which(row.labels==1))
  
  #add the new class label column
  pt1.data.2 [i, "Class"] <- as.character(row.correct.label)  #pt1_data[i,(pt1_data[1, ]) == 1] #paste("Class", pt1_data[i, ], sep="")
}




#Separiamo i dati in due partizioni: training (75%) e test set (25%) con tuple scelte a caso
perc.splitting <- 0.75
#Calcoliamo il numero di tuple nel training set
nobs.training <- round(perc.splitting*nrow(pt1.data.2))
#Campioniamo in maniera random le tuple
sampled.pos <- sample(1:nrow(pt1.data.2),nobs.training)
#Effettuiamo il partizionamento
pt1.training <- pt1.data.2[sampled.pos,]
pt1.testing <- pt1.data.2[-sampled.pos,]
#Nascondiamo la classe di appartenenza nel test set
true.classes <- pt1.testing[,104]
pt1.testing <- pt1.testing[,-104]


#1) CART

#Carico le libreria necessaria
library(rpart)
#Carichiamo anche rpart.plot per la visualizzazione
library(rpart.plot)

#Vogliamo classificare la tipologia di tumore (campo "Class" in funzione degli altri attributi)
#cp = “value” is the assigned a numeric value that will determine how deep you want your tree to grow.
#The smaller the value (closer to 0), the larger the tree. The default value is 0.01, which will render a very pruned tree.
pt1.cart <- rpart(Class ~ ., data = pt1.training,  cp = 0.001) 

#Stampo l'albero decisionale ottenuto in forma testuale
pt1.cart
#Per avere maggiori informazioni pi? accurate si pu? usare il metodo "printcp"
#che mostra anche il cost-complexity pruning (CP)
#nsplit ? il numero di split necessari per arrivare ad un nodo dell'albero
#relerror ? l'errore relativo
#xerror e xstd sono media e deviazione standard del cross-validation error
#(rpart effettua al suo interno una cross-validation)
printcp(pt1.cart)

rpart.plot(pt1.cart)



rpart.plot(pt1.cart, type = 0, extra = 104)

pt1.cart$cptable

plotcp(pt1.cart)

rpart.rules(pt1.cart,cover = T)

#PRUNING 

#Selezioniamo il CP col numero minimo k di split che garantisce un errore relativo accettabile,
#Scegliamo il minimo k tale che relerror+xstd < xerror
#Nel nostro caso k=1 (ovvero size of tree=2).
best.cp <- pt1.cart$cptable[6,"CP"]
#Effettuiamo il pruning dell'albero con CP associato
pt1.cart.pruned <- prune(pt1.cart, cp=best.cp)
#Visualizziamo l'albero ottenuto
rpart.plot(pt1.cart.pruned, type = 0, extra = 104)

rpart.rules(pt1.cart.pruned,cover = T)


# ACCURACY 

#Predico le classi sul test set
#Restituisci una tabella con le probabilit? di appartenere ad ognuna delle classi
predict(pt1.cart.pruned, pt1.testing)
#Restituisci la classe pi? probabile. Usiamo il metodo generale di predizione
cart.predict <- predict(pt1.cart,pt1.testing,type="class")
cart.predict.pruned <- predict(pt1.cart.pruned,pt1.testing,type="class")
#Confrontiamo classe predetta con classe reale
cart.results <- data.frame(real=true.classes,predicted=cart.predict)
cart.pruned.results <- data.frame(real=true.classes,predicted=cart.predict.pruned)
#Calcoliamo l'accuratezza
cart.accuracy <- sum(cart.results$real==cart.results$predicted)/nrow(cart.results)
cart.pruned.accuracy <- sum(cart.pruned.results$real==cart.pruned.results$predicted)/nrow(cart.pruned.results)



