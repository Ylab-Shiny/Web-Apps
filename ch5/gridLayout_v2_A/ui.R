###############################################################################################################################
### Google Analytics - ui.R ###################################################################################################
###############################################################################################################################
library(shiny)

shinyUI(fluidPage( # 柔軟なユーザーインターフェースのセットアップ
  # アプリのタイトル
  titlePanel("Google Analytics"),
  
  fluidRow(
    column(6,
           dateRangeInput(inputId = "dateRange", 
                          label = "日付範囲",
                          start = "2013-05-01") # 日付の選択
           ),
    
    column(3,
           checkboxGroupInput(inputId = "domainShow", # ネットワークドメインの選択
                              label = "NHSとother domainどちらを表示しますか?（デフォルトはどちらも表示）",
                              choices = list("NHS" = "nhs.uk", "other domain" = "Other"),
                              selected = c("nhs.uk", "Other")
           )),
    
    column(3,
           radioButtons(inputId = "outputRequired",
                        label = "要求する出力結果",
                        choices = list("平均セッション" = "meanSession",
                                       "ユーザー数" = "users",
                                       "セッション数" = "sessions")
                        ),
           
           checkboxInput("smooth", label = "平滑線を表示しますか？", # 平滑化
                         value = F)
           
           )
    ),
  
  textOutput("textDisplay"),
  plotOutput("trend")
  
))