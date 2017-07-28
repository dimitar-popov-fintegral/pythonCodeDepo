#' @function treeCV
treeCV <- function(cut, nObs, target, alpha, env, cutVector){
  # sub-divide data
  data <- env$dt
  split <- cut:(cut+nObs)
  train <- data[split,]
  test <- data[-(split),]
  
  # train using recursive bonary splitting 
  treeFit <- tree(formula(paste0(target, '~.')), data = train)
  
  # get row identification variable for later 
  y <- match(cutVector, cut)
  y <- sum(y*1:length(y), na.rm = TRUE)

  # prune tree using cost-complexity pruning technique
  alphaErrorPairs <- sapply(alpha, treePruneAndPred, tree = treeFit, train = train, test = test, target = target, alphaVec = alpha, cutValue = y, simplify = FALSE)

  return(alphaErrorPairs)
}

#' @function treePruneAndPred
treePruneAndPred <- function(a, tree, train, test, target, alphaVec, cutValue){
  # prune for given alpha
  # if-statement for use when single split tree of type 'singlenode' is encountered and throws error for prune.tree
  if(length(class(tree))<2){
    prunedTreeFit <- prune.tree(tree = tree, k = a)
  } else {
    prunedTreeFit <- tree
  }

  # predict and calc error (MSPE) as a function of alpha param 
  prunedTreePred <- predict(prunedTreeFit, newdata = test)
  treeFitMSPE <- mean((dplyr::select(test, target) - prunedTreePred)^2)
  
  # write to bucket in compEnv for later retrieval
  x <- match(alphaVec, a)
  rowIdentifier <- sum(x*1:length(x), na.rm = TRUE)
  set(compEnv$bucket,  
      i = as.integer((10 * (rowIdentifier - 1) + cutValue)), 
      j = names(compEnv$bucket), 
      list(MSPE=c(treeFitMSPE), alpha=c(a), crossFold = c(cutValue)))
  
  return(data.frame(list(MSPE=c(treeFitMSPE), alpha=c(a))))
}