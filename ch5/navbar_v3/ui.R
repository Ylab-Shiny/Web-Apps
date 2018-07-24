library(shiny)

shinyUI(
  shiny::navbarPage("Google Analytics",
                    
                    tabPanel("入力",
                             dateRangeInput(inputId = "dateRange",
                                            label = "日付範囲",
                                            start = "2013-05-01"),
                             checkboxGroupInput(
                               inputId = "domainShow",
                               label = "NHSとother domainどちらを表示しますか？",
                               choices = list(
                                 "NHSユーザー" = "nhs.uk",
                                 "その他" = "Other"
                               ),
                               selected = c("nhs.uk", "Other")
                             ),
                             radioButtons(inputId = "outputRequired",
                                          label = "要求する出力結果",
                                          choices = list(
                                            "平均セッション数" = "meanSession",
                                            "利用者" = "users",
                                            "総セッション数" = "sessions"
                                          ))
                             ),
                    navbarMenu("グラフ",
                               tabPanel("トレンド", plotOutput("trend")),
                               tabPanel("ヒストグラム", plotOutput("histogram"))
                    ),
                    tabPanel("地図", plotOutput("ggplotMap"))
                    )
)