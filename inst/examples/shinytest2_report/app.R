library(shiny)

ui <- fluidPage(
  titlePanel("Loan calculator"),
  sidebarLayout(
    sidebarPanel(
      numericInput("amount", "Amount", value = 1000, min = 0),
      numericInput("months", "Months", value = 10, min = 0)
    ),
    mainPanel(
      h3(textOutput("payment"))
    )
  )
)

server <- function(input, output) {
  output$payment <- renderText({
    message("Calculating the payment of ", input$amount, " over ", input$months, " months")
    # A bug: 0 months should ask for at least 1 month instead of failing
    if (input$months == 0) stop("Can't split a loan into 0 months")
    paste("Monthly payment:", input$amount / input$months)
  })
}

shinyApp(ui, server)
