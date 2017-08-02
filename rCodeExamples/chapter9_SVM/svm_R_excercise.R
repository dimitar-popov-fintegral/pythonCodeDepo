#' @date 20170802
#' @description Complete a short monte carlo excercise with SVM based techniques, CH9 R-excercise EoSL
#' @author D POPOV

## imports 
library('e1071')
library('MASS')
library('data.table')

## prepare problem
# set seed 
set.seed(1010110)

monte_carlo_SVM <- function(x){
  x
  # set num. of points to eval 'n'
  n1 = 50
  n2 = n1
  
  # class yi = 0 
  x1i <- mvrnorm(n1, mu = rep(0,10), Sigma = diag(10))
  y1i <- rep(0, n1)
  
  # class yi = 1 
  x2i <- mvrnorm(n2, mu = c(rep(1,5), rep(0,5)), Sigma = diag(10))
  y2i <- rep(1, n2)
  
  # stitch data together and randomize order of obs
  xMat <- data.frame(rbind(x1i, x2i))
  yMat <- data.frame(Target = as.factor(t(cbind(t(y1i), t(y2i)))))
  dat <- data.frame(cbind(xMat, yMat))
  dat <- data[sample(seq(1,100), 100, replace = FALSE),]
  
  # test data
  
  xTest  <- data.frame(rbind(mvrnorm(as.integer(5e3), mu = rep(0, 10), Sigma = diag(10)),
                             mvrnorm(as.integer(5e3), mu = c(rep(1,5), rep(0,5)), Sigma = diag(10))))
  yTest <- data.frame(Target=as.factor(t(cbind(t(rep(0,as.integer(5e3))), 
                                     t(rep(1,as.integer(5e3)))))))
  datTest <- data.frame(cbind(xTest, yTest))
  
  # train SVM on labelled data
  svmFit <- svm(formula = Target ~., data = dat)
  
  # obtain predictions 
  xPred <- predict(svmFit, datTest)
  
  # return test error rate 
  return(sum(xPred != datTest$Target) / nrow(datTest))
}


