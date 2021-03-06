###############################################################################################################################
### Google Analytics - server.R ###############################################################################################
###############################################################################################################################
library(dplyr)
library(ggplot2)
library(rgdal)
library(RColorBrewer)
library(shiny)

shinyServer(function(input, output) {
  load("gadf.Rdata")
  
  # 反応性のあるデータ
  passData <- reactive({
    
    firstData <- filter(gadf, date >= input$dateRange[1] &
                          date <= input$dateRange[2])
    
    if(!is.null(input$domainShow)) {
      firstData <- filter(firstData, networkDomain %in%
                            input$domainShow)
    }
    
    return(firstData)
  })
  
  output$textDisplay <- renderText({
    paste(
      length(seq.Date(input$dateRange[1], input$dateRange[2], by = "days")),
      " 日間集計されています。 この間に", sum(passData()$users),
      " ユーザーの利用がありました。"
    )
  })
  
  output$trend <- renderPlot({
    groupByDate = group_by(passData(), YearMonth, networkDomain) %>% 
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
                                 )
                      ) +
      geom_line()
    
    if(input$smooth) {
      thePlot <- thePlot + geom_smooth()
    }
    print(thePlot)
    
    output$ggplotMap <- renderPlot({
      groupCountry <- group_by(passData(), country)
      groupByCountry <- summarise(groupCountry, 
                                  meanSession = mean(sessionDuration),
                                  users = log(sum(users)),
                                  sessions = log(sum(sessions))
                                  )
      
      world <- readOGR(dsn = ".",
                       layer = "world_country_admin_boundary_shapefile_with_fips_codes")
      countries <- world@data
      countries <- cbind(id = rownames(countries), countries)
      countries <- merge(countries, groupByCountry,
                         by.x = "CNTRY_NAME",
                         by.y = "country", all.x = T)
      map.df <- fortify(world)
      map.df <- merge(map.df, countries, by = "id")
      
      ggplot(map.df, aes(x = long, y = lat, group = group)) +
        geom_polygon(aes_string(fill = input$outputRequired)) +
        geom_path(color = "grey50") +
        scale_fill_gradientn(colors = rev(brewer.pal(9, "Spectral")),
                             na.value = "white") +
        coord_fixed() + labs(x = "", y = "")
    })
  })
})