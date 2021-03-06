#To do: Scale y-axis p-curve
#       Include Likelihood H1/H0

library(shiny)
library(shinythemes)
ui <- fluidPage(theme=shinytheme("flatly"),
  titlePanel("P-value distribution and power curves for an independent two-tailed t-test"),
  sidebarLayout(
    sidebarPanel(numericInput("N", "Participants per group:", 50, min = 1, max = 1000),
                 sliderInput("d", "Cohen's d effect size:", min = 0, max = 2, value = 0.5, step= 0.01),
                 sliderInput("p_upper", "alpha, or p-value (upper limit):", min = 0, max = 1, value = 0.05, step= 0.005),
                 uiOutput("p_low"),
                 h4(textOutput("pow")),br(),
                 h4(textOutput("pow2")),br(),
                 h4("The three other plots indicate power for a range of alpha levels (top right), sample sizes per group (bottom left), and effect sizes (bottom right). The bottom right figure illustrates the point that when the true effect size of a study is unknown, the power of a study is best thought of as a curve, not as a single value."),br()
    ),
    mainPanel(
      splitLayout(style = "border: 1px solid silver:", cellWidths = c(500,500),cellHeights = c(800,800), 
               plotOutput("pdf"),
               plotOutput("cdf")
      ),
      splitLayout(style = "border: 1px solid silver:", cellWidths = c(500,500), 
               plotOutput("power_plot"),
               plotOutput("power_plot_d")
      ),
      h4("Get the code at ", a("GitHub", href="https://github.com/Lakens/p-curves"))
    )
  )
)
server <- function(input, output) {
  output$pdf <- renderPlot({
    N<-input$N
    d<-input$d
    p<-0.05
    p_upper<-input$p_upper+0.00000000000001
    p_lower<-input$p_lower+0.00000000000001
#    if(p_lower==0){p_lower<-0.0000000000001}
    ymax<-25 #Maximum value y-scale (only for p-curve)
    
    #Calculations
    se<-sqrt(2/N) #standard error
    ncp<-(d*sqrt(N/2)) #Calculate non-centrality parameter d
    
    #p-value function
    pdf2_t <- function(p) 0.5 * dt(qt(p/2,2*N-2,0),2*N-2,ncp)/dt(qt(p/2,2*N-2,0),2*N-2,0) + dt(qt(1-p/2,2*N-2,0),2*N-2,ncp)/dt(qt(1-p/2,2*N-2,0),2*N-2,0)
    par(bg = "aliceblue")
    plot(-10,xlab="P-value", ylab="Density", axes=FALSE,
         main=paste("P-value distribution for d =",d,"and N =",N), xlim=c(0,1),  ylim=c(0, ymax))
    abline(v = seq(0,1,0.1), h = seq(0,ymax,5), col = "lightgray", lty = 1)
    axis(side=1, at=seq(0,1, 0.1), labels=seq(0,1,0.1))
    axis(side=2)
    cord.x <- c(p_lower,seq(p_lower,p_upper,0.001),p_upper) 
    cord.y <- c(0,pdf2_t(seq(p_lower, p_upper, 0.001)),0)
    polygon(cord.x,cord.y,col=rgb(1, 0, 0,0.5))
    curve(pdf2_t, 0, 1, n=1000, col="black", lwd=2, add=TRUE)
})
  output$cdf <- renderPlot({
    N<-input$N
    d<-input$d
    p_upper<-input$p_upper
    p_lower<-input$p_lower
    ymax<-25 #Maximum value y-scale (only for p-curve)
    
    #Calculations
    se<-sqrt(2/N) #standard error
    ncp<-(input$d*sqrt(N/2)) #Calculate non-centrality parameter d
    
    cdf2_t<-function(p) 1 + pt(qt(p/2,2*N-2,0),2*N-2,ncp) - pt(qt(1-p/2,2*N-2,0),2*N-2,ncp)
  
    par(bg = "aliceblue")
    plot(-10,xlab="Alpha", ylab="Probability", axes=FALSE,
         main=paste("Power for independent t-test with d =",d,"and N =",N), xlim=c(0,1),  ylim=c(0, 1))
    abline(v = seq(0,1,0.1), h = seq(0,1,0.1), col = "lightgray", lty = 1)
    axis(side=1, at=seq(0,1, 0.1), labels=seq(0,1,0.1))
    axis(side=2)
#    cord.x <- c(p_lower,seq(p_lower,p_upper,0.001),p_upper) 
#    cord.y <- c(0,cdf2_t(seq(p_lower, p_upper, 0.001)),0)
#    polygon(cord.x,cord.y,col=rgb(1, 0, 0,0.5))
    curve(cdf2_t, 0, 1, n=1000, col="black", lwd=2, add=TRUE)
    points(x=p_upper, y=(1 + pt(qt(input$p_upper/2,2*N-2,0),2*N-2,ncp) - pt(qt(1-input$p_upper/2,2*N-2,0),2*N-2,ncp)), cex=2, pch=19, col=rgb(1, 0, 0,0.5))
  })
  output$power_plot <- renderPlot({
    N<-input$N
    d<-input$d
    p_upper<-input$p_upper
    ncp<-(input$d*sqrt(N/2)) #Calculate non-centrality parameter d
    plot_power <- (function(d, N, p_upper){
      ncp <- d*(N*N/(N+N))^0.5 #formula to calculate t from d from Dunlap, Cortina, Vaslow, & Burke, 1996, Appendix B
      t <- qt(1-(p_upper/2),df=(N*2)-2)
      1-(pt(t,df=N*2-2,ncp=ncp)-pt(-t,df=N*2-2,ncp=ncp))
    }
    )
    par(bg = "aliceblue")
    plot(-10,xlab="sample size (per condition)", ylab="Power", axes=FALSE,
         main=paste("Power for independent t-test with d =",d), xlim=c(0,N*2),  ylim=c(0, 1))
    abline(v = seq(0,N*2, (2*N)/10), h = seq(0,1,0.1), col = "lightgray", lty = 1)
    axis(side=1, at=seq(0,2*N, (2*N)/10), labels=seq(0,2*N,(2*N)/10))
    axis(side=2, at=seq(0,1, 0.2), labels=seq(0,1,0.2))
    curve(plot_power(d=d, N=x, p_upper=p_upper), 3, 2*N, type="l", lty=1, lwd=2, ylim=c(0,1), xlim=c(0,N), add=TRUE)
    points(x=N, y=(1 + pt(qt(input$p_upper/2,2*N-2,0),2*N-2,ncp) - pt(qt(1-input$p_upper/2,2*N-2,0),2*N-2,ncp)), cex=2, pch=19, col=rgb(1, 0, 0,0.5))
  })  
  output$power_plot_d <- renderPlot({
    N<-input$N
    d<-input$d
    p_upper<-input$p_upper
    ncp<-(input$d*sqrt(N/2)) #Calculate non-centrality parameter d
    plot_power_d <- (function(d, N, p_upper)
    {
      ncp <- d*(N*N/(N+N))^0.5 #formula to calculate t from d from Dunlap, Cortina, Vaslow, & Burke, 1996, Appendix B
      t <- qt(1-(p_upper/2),df=(N*2)-2)
      1-(pt(t,df=N*2-2,ncp=ncp)-pt(-t,df=N*2-2,ncp=ncp))
    }
    )
    par(bg = "aliceblue")
    plot(-10,xlab="Cohen's d", ylab="Power", axes=FALSE,
         main=paste("Power for independent t-test with N =",N,"per group"), xlim=c(0,2),  ylim=c(0, 1))
    abline(v = seq(0,2, 0.2), h = seq(0,1,0.1), col = "lightgray", lty = 1)
    axis(side=1, at=seq(0,2, 0.2), labels=seq(0,2,0.2))
    axis(side=2, at=seq(0,1, 0.2), labels=seq(0,1,0.2))
    curve(plot_power_d(d=x, N=N, p_upper=p_upper), 0, 2, type="l", lty=1, lwd=2, ylim=c(0,1), xlim=c(0,2), add=TRUE)
    points(x=d, y=(1 + pt(qt(input$p_upper/2,2*N-2,0),2*N-2,ncp) - pt(qt(1-input$p_upper/2,2*N-2,0),2*N-2,ncp)), cex=2, pch=19, col=rgb(1, 0, 0,0.5))
  }) 
  # make dynamic slider 
  output$p_low <- renderUI({
    sliderInput("p_lower", "p-value (lower limit):", min = 0, max = input$p_upper, value = 0, step= 0.005)
  })
  output$pow <- renderText({
    N<-input$N
    d<-input$d
    paste("On the right, you can see the p-value distribution for a two-sided independent t-test with",N,"participants in each group, and a true effect size of d =",d)
  })
  output$pow2 <- renderText({
    N<-input$N
    d<-input$d
    p_upper<-input$p_upper
    p_lower<-input$p_lower
    ncp<-(input$d*sqrt(N/2)) #Calculate non-centrality parameter d
    p_u<-1 + pt(qt(p_upper/2,2*N-2,0),2*N-2,ncp) - pt(qt(1-p_upper/2,2*N-2,0),2*N-2,ncp) #two-tailed
    p_l<-1 + pt(qt(p_lower/2,2*N-2,0),2*N-2,ncp) - pt(qt(1-p_lower/2,2*N-2,0),2*N-2,ncp) #two-tailed
    paste("The statistical power based on an alpha of",p_upper,"and assuming the true effect size is d =",d,"is",100*round((1 + pt(qt(input$p_upper/2,2*N-2,0),2*N-2,ncp) - pt(qt(1-input$p_upper/2,2*N-2,0),2*N-2,ncp)),digits=4),"%. In the long run, you can expect ",100*round(p_u-p_l, 4),"% of p-values to fall in the selected area between p = ",p_lower,"and p = ",p_upper,".")
  })
}
shinyApp(ui = ui, server = server)