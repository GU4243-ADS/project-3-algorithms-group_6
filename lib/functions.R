#### Model and Memory-based Algorithm Functions ####

# Data transform function (by Cindy Rush)
MS_data_transform <- function(MS) {
  
  ## Calculate UI matrix for Microsoft data
  ##
  ## input: data   - Microsoft data in original form
  ##
  ## output: UI matrix
  
  
  # Find sorted lists of users and vroots
  users  <- sort(unique(MS$V2[MS$V1 == "C"]))
  vroots <- sort(unique(MS$V2[MS$V1 == "V"]))
  
  nu <- length(users)
  nv <- length(vroots)
  
  # Initiate the UI matrix
  UI            <- matrix(0, nrow = nu, ncol = nv)
  row.names(UI) <- users
  colnames(UI)  <- vroots
  
  user_locs <- which(MS$V1 == "C")
  
  # Cycle through the users and place 1's for the visited vroots.
  for (i in 1:nu) {
    name     <- MS$V2[user_locs[i]]
    this_row <- which(row.names(UI) == name)
    
    # Find the vroots
    if (i == nu) {
      v_names <- MS$V2[(user_locs[i] + 1):nrow(MS)]
    } else {
      v_names <- MS$V2[(user_locs[i] + 1):(user_locs[i+1] - 1)]
    }  
    
    # Place the 1's
    UI[this_row, colnames(UI) %in% v_names] <- 1
  }
  return(UI)
}



movie_data_transform <- function(movie) {
  
  ## Calculate UI matrix for eachmovie data
  ##
  ## input: data   - movie data in original form
  ##
  ## output: UI matrix

  
  # Find sorted lists of users and vroots
  users  <- sort(unique(movie$User))
  movies <- sort(unique(movie$Movie))
  
  # Initiate the UI matrix
  UI            <- matrix(NA, nrow = length(users), ncol = length(movies))
  row.names(UI) <- users
  colnames(UI)  <- movies
  
  # We cycle through the users, finding the user's movies and ratings
  for (i in 1:length(users)) {
    user    <- users[i]
    movies  <- movie$Movie[movie$User == user]
    ratings <- movie$Score[movie$User == user]
    
    ord     <- order(movies)
    movies  <- movies[ord]
    ratings <- ratings[ord]
    
    # Note that this relies on the fact that things are ordered
    UI[i, colnames(UI) %in% movies] <- ratings
  }
  return(UI)
}  



## Memory-based Model Calculations 
calc_weight <- function(data, method = "pearson") {
  
  ## Calculate similarity weight matrix
  ##
  ## input: data   - movie data or MS data in user-item matrix form
  ##        method - 'pearson'
  ##
  ## output: similarity weight matrix
  
  
  # Iniate the similarity weight matrix
  data       <- as.matrix(data)
  weight_mat <- matrix(NA, nrow = nrow(data), ncol = nrow(data))
  
  weight_func <- function(rowA, rowB) {
    
    # weight_func takes as input two rows (thought of as rows of the data matrix) and 
    # calculates the similarity between the two rows according to 'method'
    
    joint_values <- !is.na(rowA) & !is.na(rowB)
    if (sum(joint_values) == 0) {
      return(0)
    } 
    else {
      if (method == 'pearson') {
        return(cor(rowA[joint_values], rowB[joint_values], method = 'pearson'))
      }
      else if (method == 'spearman') {
        return(cor(rowA[joint_values], rowB[joint_values], method = 'spearman'))
      }
      else if (method == 'cosine'){
        if(!require("lsa")){
          install.packages("lsa")
        }
        return(cosine(rowA[joint_values],rowB[joint_values]))
      }
      else if (method == 'entropy'){
        if(!require("infotheo")){
          install.packages("infotheo")
        }
        return(1-condentropy(rowA[joint_values], rowB[joint_values]))
      }
      else if (method =='msd'){
        return(1-mean((rowA[joint_values] - rowB[joint_values])^2))
      }
    }
  }
  
  # Loops over the rows and calculate sall similarities using weight_func
  for(i in 1:nrow(data)) {
    weight_mat[i, ] <- apply(data, 1, weight_func, data[i, ])
    print(i)
  }
  return(round(weight_mat, 4))
}


## Memory-based model prediction matrix
pred_matrix <- function(data, simweights) {
  
  ## Calculate prediction matrix
  ##
  ## input: data   - movie data or MS data in user-item matrix form
  ##        simweights - a matrix of similarity weights
  ##
  ## output: prediction matrix
  
  # Initiate the prediction matrix.
  pred_mat <- data
  
  # Change MS entries from 0 to NA
  pred_mat[pred_mat == 0] <- NA
  
  row_avgs <- apply(data, 1, mean, na.rm = TRUE)
  
  for(i in 1:nrow(data)) {
    
    # Find columns we need to predict for user i and sim weights for user i
    cols_to_predict <- which(is.na(pred_mat[i, ]))
    num_cols        <- length(cols_to_predict)
    neighb_weights  <- simweights[i, ]
    
    # Transform the UI matrix into a deviation matrix since we want to calculate
    # weighted averages of the deviations
    dev_mat     <- data - matrix(rep(row_avgs, ncol(data)), ncol = ncol(data))
    weight_mat  <- matrix(rep(neighb_weights, ncol(data)), ncol = ncol(data))
    
    weight_sub <- weight_mat[, cols_to_predict]
    dev_sub    <- dev_mat[ ,cols_to_predict]
    
    pred_mat[i, cols_to_predict] <- row_avgs[i] +  apply(dev_sub * weight_sub, 2, sum, na.rm = TRUE)/sum(neighb_weights, na.rm = TRUE)
    print(i)
  }
  
  return(pred_mat)
}


# z score (rating normalization)
pred_z_score_matrix <- function(data, simweights) {
  
  ## Calculate prediction matrix
  ##
  ## input: data   - movie data or MS data in user-item matrix form
  ##        simweights - a matrix of similarity weights
  ##
  ## output: prediction matrix
  
  # Initiate the prediction matrix.
  pred_mat <- data
  
  # Change MS entries from 0 to NA
  pred_mat[pred_mat == 0] <- NA
  
  row_avgs <- apply(data, 1, mean, na.rm = TRUE)
  
  row_devs <- apply(data, 1, sd, na.rm = TRUE)
  
  for(i in 1:nrow(data)) {
    
    # Find columns we need to predict for user i and sim weights for user i
    cols_to_predict <- which(is.na(pred_mat[i, ]))
    num_cols        <- length(cols_to_predict)
    neighb_weights  <- simweights[i, ]
    
    # Transform the UI matrix into a deviation matrix since we want to calculate
    # weighted averages of the deviations
    
    dev_mat     <- (data - matrix(rep(row_avgs, ncol(data)), ncol = ncol(data)))/(matrix(rep(row_devs, ncol(data)), ncol = ncol(data)))
    weight_mat  <- matrix(rep(neighb_weights, ncol(data)), ncol = ncol(data))
    
    weight_sub <- weight_mat[, cols_to_predict]
    dev_sub    <- dev_mat[ ,cols_to_predict]
    
    pred_mat[i, cols_to_predict] <- row_avgs[i] +  row_devs[i] * apply(dev_sub * weight_sub, 2, sum, na.rm = TRUE)/sum(neighb_weights, na.rm = TRUE)
    print(i)
  }
  
  return(pred_mat)
}

## MAE
mae <- function(test,prediction){
  mae <- mean(abs(test-prediction), na.rm = T)
  return(mae)
}

## Rank Score
rank_score <- function(test,pred){
  d <- 0
  rank_pred <- ncol(pred)+1-t(apply(pred,1,function(x){return(rank(x,ties.method = 'first'))}))
  rank_test <- ncol(test)+1-t(apply(test,1,function(x){return(rank(x,ties.method = 'first'))}))
  top <- test-d ; top[top<0]<-0
  alpha<-apply(pred>0.5,1,sum)
  alpha_matrix<-matrix(rep(alpha, ncol(rank_pred)), ncol = ncol(rank_pred))
  
  alpha_test<-apply(test>0.5,1,sum)
  alpha_test_matrix<-matrix(rep(alpha_test, ncol(rank_test)), ncol = ncol(rank_test))
  
  R_a<-apply(top/(2^((rank_pred-1)/(alpha_matrix-1))) ,1,sum)
  R_max<-apply(top/(2^((rank_test-1)/(alpha_test_matrix-1))) ,1,sum)
  
  R <- 100*sum(R_a,na.rm=TRUE)/sum(R_max,na.rm=TRUE)
  return(R)
}


## Model-based Predictions Functions
em_pred <- function(train_data, gamma, mu, cl, rng){
  nitems <- dim(train_data)[2]
  nusers <- dim(train_data)[1]
  # NAs to 0's
  train_data[is.na(train_data)] <- 0
  # assign user cluster based on highest prob of being in cluster
  # initialize prediction matrix
  preds <- as.data.frame(matrix(0, nrow = nusers, ncol = nitems))
# looping through range of score and clusters to get prediction matrix 
  for (u in 1:nusers){
    for (k in 1:rng){
      for(i in 1:cl){
        natrain <- train_data
        natrain[natrain ==0] <- NA
        prod <- log(sum((gamma[which(!is.na(natrain[u,])),k,i])))
        pred <- k * mu[i] * gamma[,k,i] * prod / (mu[i]*prod)
        preds[u,] <- pred
        if (u%%20 == 0){
          print(u)
        }
      }
    }
  }
  save(preds, file = "../data/cluster_prediction.RData")
  return(preds)
  
}

