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
      
      uiOutput("reactCountries"),
      
      conditionalPanel(
        condition = "input.theTabs == 'trend'",
        checkboxInput("smooth", label = "平滑線を表示しますか？", # 平滑化
                      value = F)),
      
      conditionalPanel(
        condition = "input.theTabs == 'animated'",
        sliderInput("animation", "トレンドの経過",
                    min = 0, max = 80, value = 0, step = 5,
                    animate = animationOptions(interval = 1000, loop = T))
        ),
      
      hr(),
      
      actionButton("drawMap", "地図の更新")
      
    ), ### サイドバーパネルの最終部分 ###
    
    mainPanel( # メインパネル部分
      tabsetPanel(id = "theTabs", # タブパネルに名前を付与
                  tabPanel("集計", textOutput("textDisplay"), value = "summary"),
                  tabPanel("トレンド", plotOutput("trend"), 
                           downloadButton("downloadData.trend", "描画図の保存"),
                           value = "trend"),
                  tabPanel("アニメーション", plotOutput("animated"), value = "animated"),
                  tabPanel("地図", plotOutput("ggplotMap"), value = "map"),
                  tabPanel("データフレーム", DT::dataTableOutput("countryTable"), value = "table")
      )
    )
  )
))