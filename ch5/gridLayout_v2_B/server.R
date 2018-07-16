
library(dplyr)
library(ggplot2)
library(RColorBrewer)
library(shiny)

shinyServer(function(input, output) {
  
  load("gadf.Rdata")
  
  # reactive data
  
  passData <- reactive({
    
    firstData <- filter(gadf, date >= input$dateRange[1] & date <= input$dateRange[2])
    
    if(!is.null(input$domainShow)){
      
      firstData <- filter(firstData, networkDomain %in% input$domainShow)
      
    }
    
    return(firstData)
    
  })
  
  # text summary
  
  output$textDisplay <- renderText({
    paste(
      length(seq.Date(input$dateRange[1], input$dateRange[2], by = "days")),
      " 日間集計したものです。 <br> この期間中、", sum(passData()$users),
      "人の利用がありました。"
    )
  })
  
  output$trend <- renderPlot({
    
    groupByDate <- group_by(passData(), YearMonth, networkDomain) %>%
      summarise(meanSession = mean(sessionDuration, na.rm = TRUE), 
                users = sum(users),
                newUsers = sum(newUsers), sessions = sum(sessions))
    
    groupByDate$Date <- as.Date(paste0(groupByDate$YearMonth, "01"), format = "%Y%m%d")
    
    thePlot <- ggplot(groupByDate, 
                     aes_string(x = "Date", y = input$outputRequired, 
                                group = "networkDomain", colour = "networkDomain")) +
      geom_line()
    
    if(input$smooth){
      
      thePlot <- thePlot + geom_smooth()
    }
    
    print(thePlot)
    
  })
  
})