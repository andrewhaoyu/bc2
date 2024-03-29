###Finish implementing ScoreTestSupport C function into the try5.c code

#' Title
#'
#' @param y
#' @param baselineonly
#' @param additive
#' @param pairwise.interaction
#' @param saturated
#' @param missingTumorIndicator
#' @param cutoff
#'
#' @return
#' @export
#'
#' @examples
EMScoreTestSupport <- function(y,
                             baselineonly,
                             additive,
                             pairwise.interaction,
                             saturated,
                             missingTumorIndicator,
                             cutoff=10){
  y <- as.matrix(y)
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
                                                       freq.subtypes,
                                                       cutoff)
  z.design.additive <- GenerateZDesignAdditive(tumor.character.cat,
                                                    tumor.number,
                                                    tumor.names,
                                                    freq.subtypes,
                                               cutoff)
  z.design.pairwise.interaction <- GenerateZDesignPairwiseInteraction(tumor.character.cat,
                                                                      tumor.number,
                                                                      tumor.names,
                                                                      freq.subtypes,
                                                                      cutoff)
  z.design.saturated <- GenerateZDesignSaturated(tumor.character.cat,
                                                 tumor.number,
                                                 tumor.names,
                                                 freq.subtypes,
                                                 cutoff)
  z.all <- ZDesigntoZall(baselineonly,
                         additive,
                         pairwise.interaction,
                         saturated,
                         z.design.baselineonly,
                         z.design.additive,
                         z.design.pairwise.interaction,
                         z.design.saturated)
  delta0 <-StartValueFunction(freq.subtypes,y.case.control,z.all)
  #x.all has no intercept yet
  #we will add the intercept in C code
  x.all <- GenerateXAll(y,baselineonly,additive,pairwise.interaction,saturated)
  ###z standard matrix means the additive model z design matrix without baseline effect
  ###z standard matrix is used to match the missing tumor characteristics to the complete subtypes

  z.standard <- z.design.additive[,-1]

  Score.Support = EMStepScoreTestSupport(delta0,y,x.all,z.standard,z.all,missingTumorIndicator)


  # score_support_result <- score_support(pxx,x.all,baselineonly,z.all,z.standard,y_em)
  #score_test_mis <- score_test_mis(y_em,baselineonly,score_support_result)
  #return(list(score_c=score_test_mis$score_c,infor_c = score_test_mis$infor_c))
  result <- Score.Support
  result[[7]] <- z.design.baselineonly
  result[[8]] <- z.design.additive
  result[[9]] <- z.design.pairwise.interaction
  result[[10]] <- z.design.saturated
  result[[11]] <- z.standard
  return(result)

}
