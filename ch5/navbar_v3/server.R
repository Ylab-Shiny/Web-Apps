
library(dplyr)
library(ggplot2)
library(rgdal)
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
  
  output$inputs <- renderUI({
    
    list(dateRangeInput(inputId = "dateRange", label = "Date range", 
                   start = "2013-05-01"),
    
    checkboxGroupInput(inputId = "domainShow", # select network domain
                       label = HTML("Show NHS and other domain<br>
                                (defaults to all)?"),
                       choices = list("NHS users" = "nhs.uk",
                                      "Other" = "Other"),
                       selected = c("nhs.uk", "Other")),
    
    radioButtons(inputId = "outputRequired", label = "Output required", 
                 choices = list("Average session" = "meanSession", 
                                "Users" = "users", "Sessions" = "sessions")))
  })
  
  output$trend <- renderPlot({
    
    groupByDate <- group_by(passData(), YearMonth, networkDomain) %>%
      summarise(meanSession = mean(sessionDuration), 
                users = sum(users),
                newUsers = sum(newUsers), sessions = sum(sessions))
    
    groupByDate$Date <- as.Date(paste0(groupByDate$YearMonth, "01"), format = "%Y%m%d")
    
    thePlot <- ggplot(groupByDate, 
                      aes_string(x = "Date", y = input$outputRequired, 
                                 group = "networkDomain", colour = "networkDomain")) +
      geom_line()
    
    print(thePlot)
    
  })
  
  output$histogram <- renderPlot({
    
    groupByDate <- group_by(passData(), YearMonth, networkDomain) %>%
      summarise(meanSession = mean(sessionDuration), 
                users = sum(users),
                newUsers = sum(newUsers), sessions = sum(sessions))
    
    groupByDate$Date <- as.Date(paste0(groupByDate$YearMonth, "01"), format = "%Y%m%d")
    
    ggplot(groupByDate, 
           aes_string(x = input$outputRequired, group = "networkDomain")) +
      geom_histogram(binwidth = diff(range(groupByDate[[input$outputRequired]])) / 10)
    
  })
  
  # produce map
  
  output$ggplotMap <- renderPlot ({
    
    groupCountry <- group_by(passData(), country)
    
    groupByCountry <- summarise(groupCountry, meanSession = mean(sessionDuration), 
                                users = log(sum(users)), sessions = log(sum(sessions)))
    
    world <- readOGR(dsn=".", layer="world_country_admin_boundary_shapefile_with_fips_codes")
    
    countries <- world@data
    
    countries <- cbind(id = rownames(countries), countries)
    
    countries <- merge(countries, groupByCountry, by.x = "CNTRY_NAME", by.y = "country", all.x = TRUE)
    
    map.df <- fortify(world)
    
    map.df <- merge(map.df, countries, by = "id")
    
    ggplot(map.df, aes(x = long, y = lat, group = group)) +
      geom_polygon(aes_string(fill = input$outputRequired)) +
      geom_path(colour = "grey50") +
      scale_fill_gradientn(colours = rev(brewer.pal(9, "Spectral")),
                           na.value = "white") +
      coord_fixed() + labs(x = "", y = "")
    
  })
  
})