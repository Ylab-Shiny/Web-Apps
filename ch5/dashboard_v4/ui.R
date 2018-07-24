##############################################################################################################################
#### Google Analytics Dashboard--ui.R ########################################################################################
##############################################################################################################################
# ライブラリ一覧
{
  library(shiny)
  library(shinydashboard)
  library(shinyBS)
  library(leaflet)
  library(shinythemes)
}

### 構成要素 ###
# header #
header <- dashboardHeader(title = "Google Analytics",
                          dropdownMenuOutput("notifications"))

# sidebar #
sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("ダッシュボード", tabName = "dashboard", icon = icon("dashboard")),
    menuItem("地図", tabName = "map", icon = icon("globe"),
             badgeLabel = "ロード遅め", badgeColor = "red"),
    menuItem("データセット", tabName = "table", icon = icon("table"))
  ),
  
  dateRangeInput(inputId = "dateRange", label = "日付範囲",
                 start = "2013-05-01"), # 日付の選択
  
  checkboxGroupInput(inputId = "domainShow", # ネットワークドメインの選択
                     label = "NHSとother domainどちらを表示しますか?（デフォルトはどちらも表示）",
                     choices = list("NHS" = "nhs.uk", "other domain" = "Other"),
                     selected = c("nhs.uk", "Other")
  ),
  radioButtons(inputId = "outputRequired",
               label = "要求する出力結果",
               choices = list("平均セッション" = "meanSession",
                              "ユーザー数" = "users",
                              "セッション数" = "sessions")),
  
  uiOutput("reactCountries"),
  
  checkboxInput("smooth", label = "平滑線を表示しますか？",
                value = FALSE),
  
  sliderInput("animation", "トレンドの経過",
              min = 0, max = 80, value = 0, step = 5,
              animate = animationOptions(interval = 1000, loop = T)),
  
  actionButton("showData", "クライアントデータの表示", icon = icon("desktop")),
  
  actionButton("drawMap", "地図の更新"),
  
  shinyBS::bsTooltip(id = "domainShow",
                     title = "両ソースの選択を解除すると、デフォルトですべてのデータになります",
                     placement = "top")
  
) ### sidebarの最終部分

# body #
body <- dashboardBody(
  bsModal(id = "clientData", title = "利用者情報",
          trigger = "showData",
          verbatimTextOutput("clientdataText")
          ),
  
  tabItems(
    tabItem(tabName = "dashboard",
            fluidRow(
              shinydashboard::infoBoxOutput(width = 3, "days"),
              infoBoxOutput(width = 3, "users"),
              infoBoxOutput(width = 3, "percentNew"),
              infoBox(width = 3, "shinyのバージョン", "1.1.0", icon = icon("desktop"))
            ),
            
            fluidRow(
              box(width = 5, plotOutput("trend"), downloadButton("downloadData.trend", "描画図の保存")),
              box(width = 2, htmlOutput("gauge")),
              box(width = 5, plotOutput("histogram")),
              box(width = 12, plotOutput("animated"))
            )
    ),
    
    tabItem(tabName = "map",
            box(width = 12, plotOutput("ggplotMap")),
            box(width = 12, leafletOutput("leaflet"))
            ),
    
    tabItem(tabName = "table",
            box(width = 12, DT::dataTableOutput("countryTable"), 
                downloadButton("downloadData", "データセットのダウンロード"),
                
                ## カスタムレポートのダウンロード ##
                downloadButton("downloadDoc", "レポートのダウンロード")))
  )
) ### bodyの最終部分

## 組み立て ##
dashboardPage(header, sidebar, body)