#' @date 20170725
#' @description : Short code to practice ensemble tree methods i.e. bagging, boosting, etc.

library('dplyr')
library('tibble')
library('tree')
library('randomForest')
library('MASS')

## Clean-up env
rm(list=ls())

## Reproducible results + source helper functions
set.seed(101)
setwd('C:/Users/Fintegral/Downloads/statLearning/chapter8_treeMethods')
source('./functions_ensembleMethodsForPrediction.R')

## Boston housing data-set
cleanDt <- as_tibble(Boston)
dt <- as_tibble(Boston)

## Explore and manipulate
# residential zoning appears mostly condensed to lower proportions
par(mfrow = c(1,2))
hist(dt$zn)
hist(dt$indus)

# look at low-density res towns and check their avg. prop of industrial zones
lowResidental <-  dplyr::select(filter(dt, zn<20), indus)
avgLowRes <- mean(lowResidental$indus)
par(mfrow = c(1,1))
p <- ggplot(data = dt, aes(zn, indus))
p + geom_point()

# we have town-level data, the crim variable is per capita, attempt to adjust for town size
# by multiplying p.c. crime rate by zn we upscale the effect of a high crime rate in high-density areas
pCrim <- ggplot(dt, aes(crim, zn))
pCrim + geom_point()
pCrim1 <- ggplot(dt, aes(crim, medv))
pCrim1 + geom_point()
dt <- mutate(dt, scaledToZnCrim = crim * (zn/100))
pCrim2 <- ggplot(dt, aes(scaledToZnCrim, medv))
pCrim2 + geom_point()

#' we have aggregate house level data 
#' try to get a sense of large, older properties, where density is high
dt <- mutate(dt, propLargeAndOld = rm * (age/100)) 
pRm <- ggplot(dt, aes(propLargeAndOld, medv))
pRm + geom_point()

#' explore the concept of lstat
#' appears that the variable is positively correl. with crime-rate hence producing negative effects on medv
dt %>% filter(crim<20) %>% ggplot(., aes(crim, lstat)) + geom_point()
dt %>% ggplot(., aes(medv, lstat)) + geom_point()
dt %>% ggplot(., aes(medv, crim)) + geom_point()
dt %>% ggplot(., aes((medv), scaledToZnCrim)) + geom_point()

## Attempt to fit simple tree to Boston data
dtTrain <- sample(1:nrow(dt), 300)
treeFit <- tree(medv~., data = dt, subset = dtTrain)
treeFitPred <- predict(object = treeFit, newdata = dt[dtTrain,])
treeFitRes <- treeFit$y - treeFitPred
treeFitMSTE <- mean(treeFitRes^2)
treeFitOOS <- predict(treeFit, newdata = dt[-(dtTrain), ])
treeFitMSPE <- mean((treeFitOOS-dt[-(dtTrain),]$medv)^2)

## Cross validate tree using cost-complexity pruning
folds <- 10
total <- nrow(dt)
obs <- as.integer(total/folds)
targetVariable <- 'medv'
listDt <- rep(list(NA), folds)
compEnv <- new.env()
compEnv$dt <- dt
setNumRandomizeRows <- 1
subset <- seq(1,total, obs)
subset <- replace(subset, length(subset), tail(subset,1) + (total%%obs-1))
alphaVector <- as.integer(seq(1,1000, by = 50))
compEnv$bucket <- data.table(MSPE=rep(0.0, (length(alphaVector) * (length(subset) - 1)) + 1), 
                     alpha=rep(0.0, (length(alphaVector) * (length(subset) - 1)) + 1), 
                     crossFold=rep(0.0, (length(alphaVector) * (length(subset) - 1)) + 1))

# randomize the way which CV partitions are made, perform CV for picking best pruning parameter  
for(rand in 1:setNumRandomizeRows){
  # randomize order of obs
  orderObs <- sample(1:nrow(dt), nrow(dt))
  compEnv$dt <- dt[orderObs, ]
  
  # perform CV pruning 
  cvErrors <- sapply(subset, treeCV, nObs = obs, target = targetVariable, alpha = alphaVector, cutVector = subset, env = compEnv)
}
s
## Attempt to fit a random forest to data -> data fits better using the RF method with significantly lower MSPE
rfFit <- randomForest(medv~., data = dt, subset = dtTrain)
rfFitRes <- rfFit$y - rfFit$predicted
rfFitMSTE <- mean(rfFitRes^2)
rfFitOOS <- predict(rfFit, newdata = dt[-(dtTrain),])
rfFitMSPE <- mean((rfFitOOS-dt[-(dtTrain),]$medv)^2)
