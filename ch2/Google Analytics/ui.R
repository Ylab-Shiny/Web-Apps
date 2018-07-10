###############################################################################################################################
### Google Analytics - ui.R ###################################################################################################
###############################################################################################################################
library(shiny)
shinyUI(fluidPage( # 柔軟なユーザーインターフェースのセットアップ
  # アプリのタイトル
  titlePanel("Google Analytics"),
  sidebarLayout( # 簡単な設定、左のコントロール、右の出力
    sidebarPanel( # サイドバーのレイアウト
      dateRangeInput(inputId = "dateRange", label = "日付範囲",
                     start = "2013-05-01"), # 日付の選択
      
      checkboxGroupInput(inputId = "domainShow", # ネットワークドメインの選択
                         label = "NHSとother domainどちらを表示しますか?（デフォルトはどちらも表示）",
                         choices = list("NHS" = "nhs.uk", "other domain" = "Other"),
                         selected = c("nhs.uk", "Other")
                         ),
      hr(),
      
      radioButtons(inputId = "outputRequired",
                   label = "要求する出力結果",
                   choices = list("平均セッション" = "meanSession",
                                  "ユーザー数" = "users",
                                  "セッション数" = "sessions")),
      
      checkboxInput("smooth", label = "平滑線を表示しますか？", # 平滑線を加える
                    value = F)
      
      ), # サイドバーパネルの最終部分
    mainPanel( # メインパネル部分
      tabsetPanel( # タブ出力のセットアップ
        tabPanel("集計", textOutput("textDisplay"))
        ),
      tabPanel("トレンドグラフ", plotOutput("trend")),
      tabPanel("地図", plotOutput("ggplotMap")
               )
      )
    )
  ))