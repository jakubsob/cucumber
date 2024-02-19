library(shiny)
library(datasets)

mpg_data <- mtcars
mpg_data$am <- factor(mpg_data$am, labels = c("Automatic", "Manual"))


ui <- fluidPage(
  titlePanel("Miles Per Gallon"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "variable",
        "Variable:",
        c(
          "Cylinders" = "cyl",
          "Transmission" = "am",
          "Gears" = "gear"
        )
      ),
      checkboxInput("outliers", "Show outliers", TRUE)
    ),
    mainPanel(
      h3(textOutput("caption")),
      plotOutput("mpgPlot")
    )
  )
)

server <- function(input, output) {
  formula_text <- reactive({
    paste("mpg ~", input$variable)
  })

  output$caption <- renderText({
    formula_text()
  })

  output$mpgPlot <- renderPlot({
    boxplot(
      as.formula(formula_text()),
      data = mpg_data,
      outline = input$outliers,
      col = "#75AADB",
      pch = 19
    )
  })
}

shinyApp(ui, server)
