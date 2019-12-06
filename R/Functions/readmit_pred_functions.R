# Reduce Init_Disp
reduce_dispo_func <- function(dispo){
  dispo <- as.character(dispo)
  if_else(
    dispo %ni% c('AHR','ATE','ATW','ATL','AMA','ATH')
    , 'Other'
    , dispo
  )
}

reduce_hsvc_func <- function(hsvc){
  hsvc <- as.character(hsvc)
  if_else(
    hsvc %ni% c('MED','SDU','PSY','SIC','SUR')
    , 'Other'
    , hsvc
  )
}

reduce_agebucket_func <- function(abucket){
  abucket <- as.character(abucket)
  if_else(
    abucket %ni% c(as.character(seq(1:7)))
    , 'Other'
    , abucket
  )
}

reduce_spclty_func <- function(spclty){
  spclty <- as.character(spclty)
  if_else(
    spclty %ni% c('HOSIM','FAMIP','IMDIM','GSGSG','PSYPS','SURSG')
    , 'Other'
    , spclty
  )
}

reduce_lihn_func <- function(lihn){
  lihn <- as.character(lihn)
  if_else(
    lihn %ni% c(
      'Medical',
      'Surgical',
      'CHF',
      'COPD',
      'Cellulitis',
      'Pneumonia',
      'Major Depression/Bipolar Affective Disorders',
      'MI',
      'GI Hemorrhage',
      'PTCA',
      'CVA',
      'Alcohol Abuse',
      'Schizophrenia',
      'Laparoscopic Cholecystectomy'
    )
    , 'Other'
    , lihn
  )
}

# F1 confusion matrix score
conf_mat_f1_func <- function(model){
  f1 = 2* (
    (
      calculateROCMeasures(model)$measures$ppv * 
        calculateROCMeasures(model)$measures$tpr
    )
    / 
      (
        calculateROCMeasures(model)$measures$ppv + 
          calculateROCMeasures(model)$measures$tpr
      )
  )
  return(f1)
}

# ROC and Threshold V Performance
perf_plots_func <- function(Model){
  
  # Model name
  mod1 <- deparse(substitute(Model))
  
  # Model 1 ROC Plot
  mod1.roc.plt <- plotROCCurves(
    generateThreshVsPerfData(
      Model
      , measures = list(fpr, tpr)
    )
  ) +
    labs(
      title = paste0(
        "AUC of "
        , mod1
        , " = "
        , round(
          mlr::performance(Model, mlr::auc)
          , 4
        ) * 100
        , "%"
      )
      , subtitle = paste0(
        "F1 Score = "
        , round(conf_mat_f1_func(Model), 4)
      )
    ) +
    theme_bw()
  
  # Model 1 Threshold Vs Performance Plot
  mod1.ThresVsPerf.plt <- plotThreshVsPerf(
    generateThreshVsPerfData(
      Model
      , measures = list(fpr, tpr, mmce)
    )
  ) +
    theme_bw()
  
  return(
    gridExtra::grid.arrange(
      ncol = 1
      , nrow = 2
      , mod1.roc.plt
      , mod1.ThresVsPerf.plt
    )
  )
}