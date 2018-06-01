##############################################################################################################################
######### Running Javascript on the page - ui.R ##############################################################################
##############################################################################################################################

library(shiny) # 両方のファイル(ui, server)の上部でShinyをロード
shinyUI(fluidPage(
  h4(HTML("Think of a number:</br>Does Shiny or </br>JavaScript
          rule?")),
  sidebarLayout(
    sidebarPanel(
      # サイドバーの設定
      sliderInput("pickNumber", "Pick a number",
                  min = 1, max = 10, value = 5),
      tags$div(id = "output") # ドロップダウンを保持するtags$XX
    ),
    
    mainPanel(
      includeHTML("dropdownDepend.js"), # JSファイルを含む
      textOutput("randomNumber"),
      hr(),
      textOutput("theMessage")
    )
  )
))
