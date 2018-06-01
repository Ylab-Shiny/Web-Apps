##############################################################################################################################
### custum HTML output - server.R ############################################################################################
##############################################################################################################################

library(shiny)
library(ggplot2)

# 作業ディレクトリの設定
user <- Sys.getenv("USERPROFILE")
wd <- paste0(user, "\\Documents\\Web App\\ch3\\")
setwd(wd)
# データをロードする：文字列を文字列として保持する
PO <- read.csv("PO.csv", stringsAsFactors = F)

# 領域を保持する空白を埋め込む新しい変数を作成する
PO$Area <- NA

# サービスコードと一致する記事を見つけて正しい名前ラベル付けする
PO$Area[grep("RHARY", PO$HealthServices,
             ignore.case = T)] <- "Armadillo"
PO$Area[grep("RHAAR", PO$HealthServices,
             ignore.case = T)] <- "Baboon"
PO$Area[grep("RHANN-inpatient", PO$HealthServices,
             ignore.case = T)] <- "Camel"
PO$Area[grep("rha20-25101", PO$HealthServices,
             ignore.case = T)] <- "Deer"
PO$Area[grep("rha20-29202", PO$HealthServices,
             ignore.case = T)] <- "Elephant"

# 累積合計のために一緒に追加する投稿変数を作成する: 1を与える
PO$ToAdd <- 1

# Areaの欠損値はすべて表示されないので削除してください
PO <- PO[!is.na(PO$Area),]

# APIはデータを逆順に返します
PO <- PO[nrow(PO):1,]

# 累積合計列を生成する
PO$Sum <- ave(PO$ToAdd, PO$Area, FUN = cumsum)

# スプレッドシートのデータ列から日付列を生成する
PO$Date <- as.Date(substr(PO$dtSubmitted, 1, 10), format = "%Y-%m-%d")

#######################################################################
shinyServer(function(input, output) {
  output$plotDisplay <- renderPlot({
    # UIで選択された領域のみを選択します
    toPlot = PO[PO$Area == input$area,]
    ggplot(toPlot, aes(x = Date, y = Sum)) + geom_line()
  })
  
  output$outputLink <- renderText({
    # 多くの他のプログラミング言語と同様なRのswitchコマンド
    link <- switch (input$area,
      "Armadillo" =
        "http://www.patientopinion.org.uk/services/rhary",
      "Baboon" =
        "http://www.patientopinion.org.uk/services/rhaar",
      "Camel" =
        "http://www.patientopinion.org.uk/services/RHANN-inpatient",
      "Deer" = 
        "http://www.patientopinion.org.uk/services/rha20-25101",
      "Elephant" =
        "http://www.patientopinion.org.uk/services/rha20-29202"
    )
    # HTMLも一緒に貼り付け
    paste0('<form action="', link, '"target="_blank">
           <input type="submit" value="Go to main site">
           </form>')
  })
})