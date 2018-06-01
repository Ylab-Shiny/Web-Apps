############################################################################################################################
######### jQueryを用いた例 - server.R ######################################################################################
############################################################################################################################

library(shiny)

addResourcePath("shinyjs", system.file("srcjs", package = "shinyjs"))

shinyServer(function(input, output) {
  output$dataset <- renderTable({
    theData = switch (input$dataset,
      "iris" = iris,
      "USPersonalExpenditure" = USPersonalExpenditure,
      "CO2" = CO2
    )
    head(theData)
  })
  
  output$datatext <- renderText({
    paste0("これはデータセット", input$dataset, "です")
  })
  
  output$hiddentext <- renderText({
    paste0("データセットの行数は", nrow(switch (input$dataset,
      "iris" = iris,
      "USPersonalExpenditure" = USPersonalExpenditure,
      "CO2" = CO2
    )), "行です")
  })
})