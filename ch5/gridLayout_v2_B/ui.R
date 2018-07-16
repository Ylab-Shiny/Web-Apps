###############################################################################################################################
### Google Analytics - ui.R ###################################################################################################
###############################################################################################################################
library(shiny)

shinyUI(fluidPage( # 柔軟なユーザーインターフェースのセットアップ
  # アプリのタイトル
  title = "Google Analytics",
  
  h2("Google Analytics",
     style = "font-family: 'Impact';
     color: purple; font-size: 32px;"),
  
  fluidRow(
    column(4,
           wellPanel(
             dateRangeInput(inputId = "dateRange", 
                            label = "日付範囲",
                            start = "2013-05-01") # 日付の選択
           )
           ),
    
    column(4, div(
      shiny::checkboxGroupInput(inputId = "domainShow",
                                label = HTML("NHSとother domainどちらを表示しますか?<br>（デフォルトはどちらも表示）"),
                                choices = list("NHS" = "nhs.uk", "other domain" = "Other"),
                                selected = c("nhs.uk", "Other")
                                ),
      style = "text-align: center;"
    )
    ),
    
    column(4,
           fluidRow(
             column(6,
               shiny::radioButtons(inputId = "outputRequired",
                                   label = "要求する出力結果",
                                   choices = list("平均セッション" = "meanSession",
                                                  "ユーザー数" = "users",
                                                  "セッション数" = "sessions")
                                   )
               ),
             
             column(6,
                    checkboxInput("smooth", label = "平滑線を表示しますか？", # 平滑化
                                  value = F)
                    )
             )
           )
    ), ### fluidRow()の最終部分
  
  hr(),
  fluidRow(
    column(4, div(
      shiny::htmlOutput("textDisplay"),
      style = "text-align: centor;"
    )),
    column(8, plotOutput('trend'))
  )
))