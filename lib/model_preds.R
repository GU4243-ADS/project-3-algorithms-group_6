## Predictions for EM Algorithms

library(matrixStats)
# pi is hard cluster assignment 
# mu is weighting of clusters; don't need that for prediction (capturing it with gamma and soft assgn. )
em_pred <- function(train_data, gamma, sft_assn, cl, rng){
  nitems <- dim(train_data)[2]
  nusers <- dim(train_data)[1]
  # NAs to 0's
  train_data[is.na(train_data)] <- 0
  # assign user cluster based on highest prob of being in cluster
  cluster <- apply(sft_assn, 1, which.max) # or use rowMaxs of soft assgn. 
  print(cluster)
  
  
  # initialize prediction matrix
  preds <- as.data.frame(matrix(0, nrow = nusers, ncol = nitems))
  #colnames(preds) <- colnames(train_data)
  #rownames(preds) <- rownames(train_data)
  print(dim(preds))
  print(str(sft_assn))
  str(gamma[1,,1])
  
  ## has to be mXn and nXp: gamma has to have cluster assn. and ranking 
  # for MS, need to 
  for (k in rng){
    for(i in 1:cl){
    preds <- preds + k*cluster %*% t(gamma[k,,cl]) # needs to be clusters and ranks, which are probabilities. not movies
    
    # multiplied by the probability that its in that cluster and it has that rank. 
    }
  }
  save(preds, file = "../data/cluster_prediction.RData")
  return(preds)
  
}
 
  
  



