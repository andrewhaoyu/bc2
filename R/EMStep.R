#x.all contains all the potential covariates including the interested variables and other covariates
#x.all DON'T have intercept yet
#z.standard contains the potential tumor characteristic to subtypes combination

#' Title
#'
#' @param delta0 delta0
#' @param y y
#' @param x.all x.all
#' @param z.standard z.standard
#' @param z.all z.all
#' @param missingTumorIndicator missingtumorIndicator
#'
#' @return
#' @export
#'
#' @examples
EMStep <- function(delta0,y,x.all,z.standard,z.all,missingTumorIndicator){

  tol <- as.numeric(1e-04)
  tolMaxstep <- as.numeric(1e-03)
  #delta_old <- rep(0,length(delta0))
  delta_old <- delta0
  ##EM algorithm
  ##first E step
  print(paste0("Begin EM algorithm"))
  print(paste0("EM round: 1"))
  prob.fit.result <- ProbFitting(delta_old,y,x.all,
                                 z.standard,z.all,missingTumorIndicator)
  y_em <- prob.fit.result[[1]]
  missing.vec <- as.numeric(as.vector(prob.fit.result[[2]]))
  missing.mat <- prob.fit.result[[3]]
  missing.mat.vec <- as.numeric(as.vector(missing.mat))
  missing.number <- as.integer(length(missing.vec))
  idx.drop = prob.fit.result[[4]]
  #remove all the subtypes below the cutoff threshold
  if(length(idx.drop)!=0){
    x.all <- x.all[-idx.drop,,drop=F]
    y_em <- y_em[-idx.drop,,drop=F]
  }
  for(k in 1:length(missing.vec)){
    missing.vec[k] <- missing.vec[k]-sum(missing.vec[k]>=idx.drop)
  }



  # sof <- "try4.so"
  # dyn.load(sof)

  N <- as.integer(nrow(x.all))
  #x <- cbind(1,x)
  #p <- ncol(x)
  M <- as.integer(nrow(z.standard))

  NCOV   <- as.integer(ncol(x.all))
  NM     <- N*M
  nparm  <- as.integer(length(delta0))
  deltai <- as.numeric(delta0)

  NITER  <- as.integer(500)
  Y <- as.numeric(as.vector(y_em))
  X <- as.numeric(as.vector(x.all))
  ZallVec = as.numeric(as.vector(z.all))
  Znr = as.integer(nrow(z.all))
  Znc = as.integer(ncol(z.all))
  debug     <- as.integer(1)
  ret_rc    <- as.integer(1)
  ret_delta <- as.numeric(rep(-9999, nparm))
  ret_info <- as.numeric(rep(-9999,nparm^2))
  ret_p <- as.numeric(rep(0,NM))
  ret_lxx <- as.numeric(rep(0,NM))
  loglikelihood <- as.numeric(-1);


  temp <- .C("EMStep",deltai, nparm, Y=Y, X, ZallVec,Znr,Znc, N, M, NCOV, NITER, tol,tolMaxstep,
             debug, ret_rc=ret_rc, ret_delta=ret_delta,ret_info=ret_info,ret_p=ret_p,missing.vec,
             missing.mat.vec,missing.number,loglikelihood = loglikelihood)
  print(paste0("EM Algorithm Converged"))
  info <- matrix(unlist(temp$ret_info),nparm,nparm)
  result <- list(temp$ret_delta,info,
                 temp$ret_p)
  y_em <- matrix(unlist(temp$Y),N,M)

  # infor_mis_c <- infor_mis(y_em,x.all,z.all)
  #infor_obs <- result[[2]]-infor_mis_c
  delta=result[[1]]
  infor_obs=result[[2]]
  p=result[[3]]
  loglikelihood = temp$loglikelihood
  AIC = 2*nparm - 2*loglikelihood
  #loglikelihood.aic <- LogLikelihoodwithAIC(y_em,p,nparm)
  #loglikelihood <- loglikelihood.aic[[1]]
  #AIC <- loglikelihood.aic[[2]]


  return(list(delta=delta,
              infor_obs=infor_obs,
              p=p,y_em=y_em,
              M=M,
              NumberofTumor=ncol(z.standard),
              loglikelihood = loglikelihood,
              AIC = AIC
  ))
}

