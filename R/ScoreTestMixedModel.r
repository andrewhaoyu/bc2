#####ScoreTest


#' ScoreTest
#'
#' @param y
#' @param x
#' @param second.stage.structure
#' @param score.test.support
#' @param missingTumorIndicator
#'
#' @return
#' @export
#'
#' @examples
ScoreTest <- function(y,x,second.stage.structure = "additive",score.test.support=NULL,missingTumorIndicator=NULL){
  if(is.vector(x)==1){
    x = matrix(x,ncol=1)
    interested.variable.number = 1
  }else{
    interested.variable.number = ncol(x)
  }




  tumor.number <- ncol(y)-1
  y.case.control <- y[,1]
  y.tumor <- y[,2:(tumor.number+1)]
  y.pheno.complete <- GenerateCompleteYPheno(y,missingTumorIndicator)
  freq.subtypes <- GenerateFreqTable(y.pheno.complete)
  if(CheckControlTumor(y.case.control,y.tumor)==1){
    return(print("ERROR:The tumor characteristics for control subtypes should put as NA"))
  }
  tumor.names <- colnames(y.tumor)
  if(is.null(tumor.names)){
    tumor.names <- paste0(c(1:tumor.number))
  }
  tumor.character.cat = GenerateTumorCharacterCat(y.pheno.complete)
  z.design.baselineonly <- GenerateZDesignBaselineonly(tumor.character.cat,
                                                       tumor.number,
                                                       tumor.names,
                                                       freq.subtypes)
  z.design.additive <- GenerateZDesignAdditive(tumor.character.cat,
                                               tumor.number,
                                               tumor.names,
                                               freq.subtypes)
  z.design.pairwise.interaction <-
    GenerateZDesignPairwiseInteraction(tumor.character.cat,
                                       tumor.number,
                                       tumor.names,
                                       freq.subtypes)
  z.design.saturated <- GenerateZDesignSaturated(tumor.character.cat,
                                                 tumor.number,
                                                 tumor.names,
                                                 freq.subtypes)
  if(second.stage.structure == "baselineonly"){
    z.intere <- z.design.baselineonly
  }else if(second.stage.structure == "additive"){
    z.intere <- z.design.additive
    #z.intere <- z.design.additive[,-1]
  }else if(second.stage.structure=="pairwise.interaction"){
    z.intere <- z.design.pairwise.interaction
  }else if(second.stage.structure=="saturated"){
    z.intere <- z.design.saturated
  }




  z.standard <- z.design.additive[,-1]
  debug     <- as.integer(1)
  inv_info_vec=as.numeric(score.test.support$inv_info_vec)
  YminusP=as.numeric(score.test.support$YminusP)
  W_obs=as.numeric(score.test.support$W_obs)
  x.all = as.numeric(score.test.support$x.all)

  zc = score.test.support$zc
  z.intere <- as.matrix(z.intere)
  z.intere.vec <- as.numeric(as.vector(z.intere))
  nparm.intere <- as.integer(ncol(z.intere))
  efficient.info <- matrix(0,nparm.intere,nparm.intere)
  efficient.info.vec <- as.numeric(as.vector(efficient.info))
  info.complete.vec <- info.lost.vec <- efficient.info.vec
  score <- as.numeric(rep(0,nparm.intere))
  zc.nr <- as.integer(nrow(zc))
  zc.nc <- as.integer(ncol(zc))
  M <- z.intere.nr <- as.integer(nrow(z.intere))
  z.intere.nc <- as.integer(ncol(z.intere))
  tx_intereWXZ_vec <- as.numeric(rep(0,M*zc.nc))
  Quad_tx_intere_WXZ_invinfo_vec <- as.numeric(rep(0,M*M))
  N <- as.integer(nrow(x))
  score.result <- matrix(0,interested.variable.number,length(score))
  efficient.info.result <- matrix(0,interested.variable.number*nparm.intere,nparm.intere)
  index <- 1

  for(i in 1:interested.variable.number){
    x.intere <- as.numeric(x[,i])

    temp <- .C("ScoreTestMixedModel",
               x.intere,
               z.intere.vec,
               inv_info_vec,
               YminusP,
               W_obs,
               score = score,
               efficient.info.vec=efficient.info.vec,
               zc.nr,
               zc.nc,
               z.intere.nr,
               z.intere.nc,
               nparm.intere,
               M,
               N,
               debug,
               info.complete.vec = info.complete.vec,
               info.lost.vec=info.lost.vec,
               tx_intereWXZ_vec= tx_intereWXZ_vec,
               Quad_tx_intere_WXZ_invinfo_vec= Quad_tx_intere_WXZ_invinfo_vec,
               x.all
    )
    score.result[i,] <- temp$score
    efficient.info <- matrix(temp$efficient.info.vec,nparm.intere,nparm.intere)
    info.complete <- matrix(temp$info.complete.vec,nparm.intere,nparm.intere)
    info.lost <- matrix(temp$info.lost.vec,nparm.intere,nparm.intere)
    tx_intereWXZ  = matrix(temp$tx_intereWXZ_vec,M,zc.nc)
    Quad_tx_intere_WXZ_invinfo_vec <- temp$Quad_tx_intere_WXZ_invinfo_vec
    efficient.info.result[(index):(index+nparm.intere-1),] <- efficient.info

    index <- index + nparm.intere



  }




  # score_support_result <- score_support(pxx,x.all,baselineonly,z.all,z.standard,y_em)
  #score_test_mis <- score_test_mis(y_em,baselineonly,score_support_result)
  #return(list(score_c=score_test_mis$score_c,infor_c = score_test_mis$infor_c))
  return(list(score.result=score.result,efficient.info.result=efficient.info.result, info.complete=info.complete,info.lost = info.lost,tx_intereWXZ=tx_intereWXZ,Quad_tx_intere_WXZ_invinfo_vec=Quad_tx_intere_WXZ_invinfo_vec))
}







