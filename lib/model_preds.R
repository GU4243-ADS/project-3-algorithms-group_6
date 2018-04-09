## Predictions for EM Algorithms

library(matrixStats)
# pi is hard cluster assignment 
# mu is weighting of clusters; don't need that for prediction (capturing it with gamma and soft assgn. )
em_pred <- function(train_data, gamma, sft_assn, cl, rng){
  nitems <- dim(train_data)[2]
  nusers <- dim(train_data)[1]
  # assign user cluster based on highest prob of being in cluster
  cluster <- (sft_assn == rowMaxs(sft_assn)) # or use rowMaxs of soft assgn. 
  # NAs to 0's
  train_data[is.na(train_data)] <- 0
  # initialize prediction matrix
  preds <- as.data.frame(matrix(0, nrow = nusers))
  #colnames(preds) <- colnames(train_data)
  #rownames(preds) <- rownames(train_data)
  print(dim(preds))
  print(dim(cluster))

  
  ## has to be mXn and nXp: gamma has to have cluster assn. and ranking 
  # for MS, need to 
  for (k in rng) {
    preds <- preds + k*cluster %*% gamma[cl,,k] # needs to be clusters and ranks, which are probabilities. not movies
    
    # multiplied by the probability that its in that cluster and it has that rank. 
    
  }
  return(preds)
  save(preds, file = "../data/cluster_prediction.Rdata")
}
 
  
  



