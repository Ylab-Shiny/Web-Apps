##############################################################################################################################
#### Google Analytics Dashboard--server.R ####################################################################################
##############################################################################################################################
# ライブラリ一覧
{
  library(shiny)
  library(dplyr)
  library(ggplot2)
  library(rgdal)
  library(RColorBrewer)
  library(googleVis)
  library(leaflet)
  library(DT)
  library(knitr)
  library(rmarkdown)
  library(readr)
  library(shinyBS)
}

options(shiny.launch.browser = T)

load("gadf.Rdata")
shinyServer(function(input, output, session){
  
  # (https://shiny.rstudio.com/articles/client-data.html)より
  cdata <- session$clientData
  
  # cdataの変数を文字として返す
  output$clientdataText <- renderText({
    cnames <- names(cdata)
    allvalues <- lapply(cnames, function(name){
      paste(name, cdata[[name]], sep = " = ")
    })
    paste(allvalues, collapse = "\n")
  }) ### clientDataTextの最終部分
  
  # 反応性のあるデータ
  passData <- reactive({
    
    firstData <- filter(gadf, date >= input$dateRange[1] &
                          date <= input$dateRange[2])
    
    if(!is.null(input$domainShow)) {
      
      firstData <- filter(firstData, networkDomain %in%
                            input$domainShow)
    }
    
    return(firstData)
  }) ### passDataの最終部分 ###
  
  # クエリ文字列を解析する
  observe({
    searchString <- parseQueryString(session$clientData$url_search)
    
    # クエリ文字列に従って入力を更新する
    if(length(searchString) > 0) { # その検索文字が存在すれば
      
      # オーディエンスを示す最初のクエリを処理する
      if(searchString[[1]] == "nhs") { # NHSユーザーのために以下を行う
        updateCheckboxGroupInput(session, "domainShow",
                                 choices = list(
                                   "NHS" = "nhs.uk",
                                   "other domain" = "Other"
                                 ),
                                 selected = c("nhs.uk"))
      }
      
      # 平滑線を引きたいのか？
      if(searchString[[2]] == "yes") {
        updateTabsetPanel(session, "theTabs", selected = "trend")
        updateCheckboxInput(session, inputId = "smooth", value = T)
      }
    }
  }) ### observeの最終部分 ###
  
  ## アイコン
  output$days <- renderInfoBox({
    infoBox(
      "日数", input$dateRange[2] - input$dateRange[1],
      icon = icon("calendar", lib = "font-awesome"),
      color = "blue",
      fill = ifelse(max(passData()$date) == max(gadf$date), T, F)
    )
  }) ### daysの最終部分
  
  output$users <- renderInfoBox({
    infoBox("利用者", sum(passData()$users),
            icon = icon("user"),
            color = "purple",
            fill = ifelse(passData()$users /
                            as.numeric(input$dateRange[2] - input$dateRange[1]) > 20,
                          T, F)
            )
  }) ### usersの最終部分
  
  output$percentNew <- renderInfoBox({
    infoBox(
      "新しい利用者",
      paste0(round(sum(passData()$newUsers) /
                     sum(passData()$users) * 100, 1), "%"),
      icon = icon("pie-chart"),
      color = "green",
      fill = ifelse(sum(passData()$newUsers) / sum(passData()$users) * 100 > 50,
                    T, F)
    )
  }) ### percentNewの最終部分
  
  ## リーフレット
  output$leaflet <- renderLeaflet({
    leaflet(gadf) %>% addCircles() %>% addTiles() %>% 
      setView(lng = 1.1333, lat = 52.95, zoom = 4)
  }) ### leafletの最終部分
  
  ## お知らせ
  output$notifications <- shinydashboard::renderMenu({
    users <- sum(gadf[gadf$date == max(gadf$date), "users"])
    newusers <- sum(gadf[gadf$date == max(gadf$date), "newUsers"]) / sum(gadf[gadf$date == max(gadf$date), "users"]) * 100
    newusers <- round(newusers, 0)
    notifData <- data.frame(
      "数値" = c(users, newusers),
      "文字" = c("人が本日の利用者",
               "%：新しいユーザーの割合"),
      "アイコン" = c("users", "user")
    )
    
    notifs <- apply(notifData, 1, function(row){
      shinydashboard::notificationItem(text = paste0(row[["数値"]],
                                                     row[["文字"]]),
                                       icon = icon(row[["アイコン"]])
                                       )
      })
    
    shinydashboard::dropdownMenu(type = "notifications", .list = notifs)
  }) ### notificationsの最終部分
  
  ## ゲージ
  output$gauge <- renderGvis({
    
    # サイズ変更を検出するプロットのサイズに依存する
    session$clientData$output_trend_width
    
    df <- data.frame(Label = "バウンス比 [%]",
                     Value = round(mean(passData()$bounceRate,
                                        trim = .1), 1)
                     )
    gvisGauge(df,
              options = list(min = 0, max =100,
                             greenFrom = 0,
                             greenTo = 50, yellowFrom = 50,
                             yellowTo = 70,
                             redFrom = 70, redTo = 100)
              )
  }) ### gaugeの最終部分
  
  # Report.Rmdファイルによる呼び出しのための関数にグラフを配置する
  trendGragh <- reactive({
    if(!is.null(input$theCountries)) {
      
      graghData <- dplyr::filter(passData(), country %in% input$theCountries)
      
      
    } else {
      
      graghData <- passData()
      
    }
    
    groupByDate <- group_by(graghData, YearMonth, networkDomain) %>% 
      summarise(meanSession = mean(sessionDuration, na.rm = T),
                users = sum(users),
                newUsers = sum(newUsers),
                sessions = sum(sessions)
      )
    
    groupByDate$Date <- as.Date(paste0(groupByDate$YearMonth, "01"),
                                format = "%Y%m%d")
    
    thePlot <- ggplot(groupByDate,
                      aes_string(x = "Date",
                                 y = input$outputRequired,
                                 group = "networkDomain",
                                 color = "networkDomain"
                      )) + geom_path()
    
    if(input$smooth) {
      thePlot <- thePlot + geom_smooth()
    }
    
    print(thePlot)
    
  }) ### trendGraghの最終部分 ###
  
  ## トレンド
  output$trend <- renderPlot({
    trendGragh()
    shinyBS::addPopover(session, id = "trend", title = "Source",
                        content = "Google Analysisのウェブサイトのすべてのデータは <a href =
                        'http://example.com'>http://example.com</a>",
                        trigger = 'click')
  }) ### trendの最終部分 ###
  
  ## 地図
  output$ggplotMap <- renderPlot({
    
    input$drawMap # actionButtonに依存する
    
    withProgress(message = 'お待ちください',
                 detail = '地図を描いています...', value = 0, {
                   
                   if(length(unique(as.character(passData()$country))) < 2) {
                     return()
                   }
                   
                   groupCountry <- isolate( # データ依存性を回避する
                     group_by(passData(), country)
                   )
                   
                   
                   groupByCountry <- summarise(groupCountry, 
                                               meanSession = mean(sessionDuration),
                                               users = log(sum(users)),
                                               sessions = log(sum(sessions))
                   )
                   
                   world <- readOGR(dsn = ".",
                                    layer = "world_country_admin_boundary_shapefile_with_fips_codes")
                   
                   incProgress(1/3)
                   
                   countries <- world@data
                   countries <- cbind(id = rownames(countries), countries)
                   countries <- merge(countries, groupByCountry,
                                      by.x = "CNTRY_NAME",
                                      by.y = "country", all.x = T)
                   map.df <- fortify(world)
                   
                   incProgress(1/3)
                   
                   map.df <- merge(map.df, countries, by = "id")
                   checkInputs <- "No"
                   
                   incProgress(1/3)
                   
                   ggplot(map.df, aes(x = long, y = lat, group = group)) +
                     geom_polygon(aes_string(fill = input$outputRequired)) +
                     geom_path(color = "grey50") +
                     scale_fill_gradientn(colors = rev(brewer.pal(9, "Spectral")),
                                          na.value = "white") +
                     coord_fixed() + labs(x = "", y = "")
                   
                 })
  }) ### ggplotMapの最終部分 ###
  
  ## ヒストグラム
  output$histogram <- renderPlot({
    
    groupByDate <- group_by(passData(), YearMonth, networkDomain) %>%
      summarise(meanSession = mean(sessionDuration), 
                users = sum(users),
                newUsers = sum(newUsers), sessions = sum(sessions))
    
    groupByDate$Date <- as.Date(paste0(groupByDate$YearMonth, "01"), format = "%Y%m%d")
    
    ggplot(groupByDate, 
           aes_string(x = input$outputRequired, group = "networkDomain")) +
      geom_histogram(binwidth = diff(range(groupByDate[[input$outputRequired]])) / 10)
    
  }) ### histogramの最終部分
  
  ## アニメーション
  output$animated <- renderPlot({
    groupByDate <- group_by(passData(), YearMonth, networkDomain) %>% 
      summarise(meanSession = mean(sessionDuration, na.rm = T),
                users = sum(users),
                newUsers = sum(newUsers), sessions = sum(sessions))
    groupByDate$Date <- as.Date(paste0(groupByDate$YearMonth, "01"),
                                format = "%Y%m%d")
    smoothData <- groupByDate[groupByDate$Date %in%
                                quantile(groupByDate$Date,
                                         input$animation / 100,
                                         type = 1) : quantile(groupByDate$Date,
                                                              (input$animation + 20) / 100,
                                                              type = 1),]
    
    ggplot(groupByDate, aes_string(x = "Date",
                                   y = input$outputRequired,
                                   group = "networkDomain",
                                   color = "networkDomain")) + geom_path() +
      geom_smooth(data = smoothData,
                  method = "lm", color = "black")
  }) ### animatedの最終部分 ###
  
  ## 国別のプルダウンメニュー
  output$reactCountries <- renderUI({
    countryList = unique(as.character(passData()$country))
    
    selectInput("theCountries", "国名を選択してください", countryList,
                multiple = T)
  }) ### reactCountriesの最終部分 ###
  
  ## データフレーム
  output$countryTable <- DT::renderDataTable({
    groupCountry <- group_by(passData(), country)
    groupByCountry <- summarise(groupCountry,
                                meanSession = mean(sessionDuration),
                                users = log(sum(users)),
                                sessions = log(sum(sessions))
    )
    DT::datatable(groupByCountry)
  }) ### countryTableの最終部分 ###
  
  ## レポートのダウンロード 
  output$downloadDoc <-
    downloadHandler(contentType = 'text/html',
      filename = "Report.html", 
      content = function(file) {
        knitr::knit2html("Report.Rmd")
        
        # レポートドキュメントを'file'にコピーする
        file.copy("Report.html", file, overwrite = T)
        }) ### downloadDocの最終部分
  
  ## 描画図のダウンロード 
  output$downloadData.trend <- downloadHandler(
    contentType = 'image/png',
    filename <- function() {
                                                 paste("TrendGragh", Sys.Date(), ".png", sep="")
                                               },
    
    content <- function(file) {
      png(file, width = 980, height = 400,
          units = "px", pointsize = 12,
          bg = "white", res = NA)
      
      trend.plot <- trendGragh()
      print(trend.plot)
      dev.off()
      }) ### downloadData.trendの最終部分 ###
  
  ## データセットのダウンロード 
  output$downloadData <- downloadHandler(
    filename = function() {
      "Dataset.csv"
    },
    
    content <- function(file) {
      readr::write_excel_csv(passData(), file)
    }
  ) ### downloadDataの最終部分 ###
  
})