library(fPortfolio)
library(quantmod)
library(timeSeries)
library(PerformanceAnalytics)
library(ggplot2)
library(tidyverse)

# DEFINE ANALYSIS PERIOD AND TICKERS TO ANALYZE
start_date <- as.Date("2020-01-01")
end_date <- as.Date("2021-12-31")
top_10_tickers_by_market_cap <- c("ISP.MI", "UCG.MI", "RACE.MI", "ENEL.MI",
                                  "G.MI", "ENI.MI", "LDO.MI", "STLAM.MI",
                                  "PST.MI", "STMMI.MI")

# DEFINE ANNUAL RISK-FREE RATE
risk_free_rate_annual <- 0.005 # 0.5% annual

# DOWNLOAD HISTORICAL ADJUSTED CLOSE DATA AND HANDLE ERRORS
adjusted_cols <- list()
downloaded_tickers <- c()
for (symbol in top_10_tickers_by_market_cap) {
  tryCatch({
    getSymbols(symbol, from = start_date, to = end_date, auto.assign = TRUE)
    if (exists(symbol) && !is.null(get(symbol))) {
      adjusted_cols[[symbol]] <- Ad(get(symbol))
      downloaded_tickers <- c(downloaded_tickers, symbol)
    } else {
      message("OBJECT NOT FOUND FOR ", symbol, " AFTER DOWNLOAD.")
    }
  }, error = function(e) {
    message("ERROR DURING DATA DOWNLOAD FOR ", symbol, ": ", e$message)
  })
}

if (length(adjusted_cols) == 0) {
  warning("NO DATA AVAILABLE FOR ANALYSIS IN THE COVID PERIOD")
} else {
  merged_adjusted_data <- do.call(merge, adjusted_cols)
  colnames(merged_adjusted_data) <- downloaded_tickers
  merged_adjusted_data <- na.omit(merged_adjusted_data) # Remove NA after merge for consistency
  
  if (nrow(merged_adjusted_data) < 2) {
    warning("INSUFFICIENT DATA AFTER NA REMOVAL FOR THE COVID PERIOD")
  } else {
    ftseData <- as.timeSeries(merged_adjusted_data)
    ftseData.ret <- returns(ftseData) * 100 # Daily returns in percentage
    
    if (ncol(ftseData.ret) < 2) {
      warning("NOT ENOUGH ASSETS (MINIMUM 2) FOR PORTFOLIO ANALYSIS IN THE COVID PERIOD")
    } else {
      
      # ANALYZE RETURNS WITH DESCRIPTIVE STATISTICS
      cat("\nSTATISTICAL SUMMARY OF RETURNS (During COVID):\n")
      print(summary(ftseData.ret))
      cat("\nMEAN RETURNS (During COVID):\n")
      print(apply(ftseData.ret, 2, mean))
      cat("\nSTANDARD DEVIATION OF RETURNS (During COVID):\n")
      print(apply(ftseData.ret, 2, sd))
      
      # PREPARE DATA FOR RETURNS VISUALIZATION WITH GGPLOT
      ftseData.ret_df <- as.data.frame(ftseData.ret)
      ftseData.ret_df$Date <- index(ftseData.ret)
      ftseData_long <- pivot_longer(ftseData.ret_df, cols = -Date, names_to = "Asset", values_to = "Return")
      
      min_y_global <- min(ftseData_long$Return)
      max_y_global <- max(ftseData_long$Return)
      
      # PLOT RETURNS TIME SERIES
      returns_plot <- ggplot(ftseData_long, aes(x = Date, y = Return, color = Asset)) +
        geom_line() +
        facet_wrap(~ Asset, ncol = 2, scales = "free_x") +
        labs(y = "RETURN (%)", x = "TIME") +
        scale_y_continuous(limits = c(min_y_global, max_y_global)) +
        theme_minimal() +
        theme(legend.position = "none", strip.text = element_text(hjust = 0))
      
      print(returns_plot)
      ggsave("thesis/returns_during_covid.png", plot = returns_plot, width = 10, height = 6, dpi = 300) # SAVE
      
      # PREPARE DATA AND CREATE HISTORICAL ADJUSTED CLOSE PRICES PLOT
      df_prices <- as.data.frame(merged_adjusted_data)
      df_prices$Date <- index(merged_adjusted_data)
      df_prices_long <- pivot_longer(df_prices, cols = -Date, names_to = "Ticker", values_to = "Price")
      
      prices_plot <- ggplot(df_prices_long, aes(x = Date, y = Price, color = Ticker)) +
        geom_line() +
        facet_wrap(~ Ticker, scales = "free_y", ncol = 2) +
        labs(x = "DATE", y = "ADJUSTED CLOSE PRICE") +
        theme_minimal() +
        theme(legend.position = "none", strip.text = element_text(hjust = 0))
      
      print(prices_plot)
      ggsave("thesis/prices_during_covid.png", plot = prices_plot, width = 10, height = 6, dpi = 300) # SAVE
      
      # ANALYZE CORRELATIONS BETWEEN ASSET RETURNS
      cat("\nCORRELATION ANALYSIS (During COVID):\n")
      png("thesis/correlations_image_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      assetsCorImagePlot(ftseData.ret)
      dev.off() 
      
      png("thesis/correlations_select_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      plot(assetsSelect(ftseData.ret))
      dev.off() 
      
      png("thesis/correlations_eigen_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      assetsCorEigenPlot(ftseData.ret)
      dev.off() 
      
      # CONSTRUCT EFFICIENT FRONTIER WITH LONG ONLY CONSTRAINTS
      ftseSpec_long <- portfolioSpec()
      setEstimator(ftseSpec_long) <- "shrinkEstimator"
      setNFrontierPoints(ftseSpec_long) <- 25
      longFrontier <- portfolioFrontier(ftseData.ret, ftseSpec_long)
      
      png("thesis/frontier_long_only_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      tailoredFrontierPlot(longFrontier, risk = "Cov")
      dev.off() 
      print(longFrontier)
      
      # VISUALIZE WEIGHTS AND RISK CONTRIBUTIONS (LONG-ONLY)
      num_assets <- ncol(ftseData.ret)
      col_palette <- seqPalette(num_assets, "YlOrRd")
      
      png("thesis/weights_long_only_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      weightsPlot(longFrontier, col = col_palette)
      dev.off() 
      
      png("thesis/returns_contributions_long_only_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      weightedReturnsPlot(longFrontier)
      dev.off() 
      
      png("thesis/risk_contributions_long_only_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      covRiskBudgetsPlot(longFrontier)
      dev.off() 
      
      # EXECUTE MONTE CARLO SIMULATION FOR LONG ONLY FRONTIER
      par(mfrow = c(1, 1))
      set.seed(1953)
      png("thesis/monte_carlo_simulation_long_only_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      frontierPlot(longFrontier, pch = 19, cex = 0.7)
      monteCarloPoints(longFrontier, mcSteps = 10000, pch = 19, cex = 0.5)
      twoAssetsLines(longFrontier, col = "orange", lwd = 1)
      lines(frontierPoints(longFrontier), col = "red", lwd = 2)
      dev.off() 
      
      # CALCULATION AND ANALYSIS OF SHARPE RATIO (LONG ONLY)
      risk_free_rate_daily <- risk_free_rate_annual / 252
      
      frontier_points_long <- as.data.frame(frontierPoints(longFrontier))
      sharpe_ratios_long <- ((frontier_points_long$targetReturn / 100 * 252) - risk_free_rate_annual) / (frontier_points_long$targetRisk / 100 * sqrt(252))
      max_sharpe_long_idx <- which.max(sharpe_ratios_long)
      max_sharpe_portfolio_long <- frontier_points_long[max_sharpe_long_idx, ]
      max_sharpe_value_long <- sharpe_ratios_long[max_sharpe_long_idx]
      
      cat("\n------------------------------------------------\n")
      cat("SHARPE RATIO ANALYSIS - LONG ONLY FRONTIER (During COVID)\n")
      cat("------------------------------------------------\n")
      cat("Maximum Sharpe Ratio Portfolio (Long Only):\n")
      cat(paste("  Annual Expected Return: ", round(max_sharpe_portfolio_long$targetReturn / 100 * 252 * 100, 2), "%", "\n", sep=""))
      cat(paste("  Annual Standard Deviation: ", round(max_sharpe_portfolio_long$targetRisk / 100 * sqrt(252) * 100, 2), "%", "\n", sep=""))
      cat(paste("  Sharpe Ratio (Annualized): ", round(max_sharpe_value_long, 4), "\n"))
      
      png("thesis/sharpe_ratio_long_only_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      plot(frontier_points_long$targetRisk, frontier_points_long$targetReturn,
           xlab = "Standard Deviation (%)", ylab = "Expected Return (%)",
           type = "p", pch = 16, col = "blue")
      points(max_sharpe_portfolio_long$targetRisk, max_sharpe_portfolio_long$targetReturn,
             col = "red", pch = 19, cex = 1.5)
      text(max_sharpe_portfolio_long$targetRisk, max_sharpe_portfolio_long$targetReturn,
           labels = paste("Max Sharpe\n(", round(max_sharpe_value_long, 2), ")", sep = ""),
           pos = 4, col = "red", cex = 0.8)
      lines(frontierPoints(longFrontier), col = "red", lwd = 2)
      grid()
      dev.off() 
      
      # CONSTRUCT EFFICIENT FRONTIER WITH SHORT SELLING ALLOWED
      shortSpec <- portfolioSpec()
      setNFrontierPoints(shortSpec) <- 25
      setSolver(shortSpec) <- "solveRshortExact"
      shortFrontier <- portfolioFrontier(ftseData.ret, shortSpec, constraints = "Short")
      
      png("thesis/frontier_short_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      tailoredFrontierPlot(shortFrontier, risk = "Cov")
      dev.off() 
      print(shortFrontier)
      
      # VISUALIZE WEIGHTS AND RISK CONTRIBUTIONS (SHORT PORTFOLIO)
      png("thesis/weights_short_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      weightsPlot(shortFrontier, col = col_palette)
      dev.off() 
      
      png("thesis/returns_contributions_short_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      weightedReturnsPlot(shortFrontier)
      dev.off() 
      
      png("thesis/risk_contributions_short_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      covRiskBudgetsPlot(shortFrontier)
      dev.off() 
      
      # EXECUTE MONTE CARLO SIMULATION FOR SHORT FRONTIER
      par(mfrow = c(1, 1))
      set.seed(1953)
      png("thesis/monte_carlo_simulation_short_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      frontierPlot(shortFrontier, pch = 19, cex = 0.7)
      monteCarloPoints(shortFrontier, mcSteps = 10000, pch = 19, cex = 0.5)
      twoAssetsLines(shortFrontier, col = "orange", lwd = 1)
      lines(frontierPoints(shortFrontier), col = "red", lwd = 2)
      dev.off() 
      
      # CALCULATION AND ANALYSIS OF SHARPE RATIO (SHORT FRONTIER)
      frontier_points_short <- as.data.frame(frontierPoints(shortFrontier))
      sharpe_ratios_short <- ((frontier_points_short$targetReturn / 100 * 252) - risk_free_rate_annual) / (frontier_points_short$targetRisk / 100 * sqrt(252))
      max_sharpe_short_idx <- which.max(sharpe_ratios_short)
      max_sharpe_portfolio_short <- frontier_points_short[max_sharpe_short_idx, ]
      max_sharpe_value_short <- sharpe_ratios_short[max_sharpe_short_idx]
      
      cat("\n------------------------------------------------\n")
      cat("SHARPE RATIO ANALYSIS - SHORT FRONTIER (During COVID)\n")
      cat("------------------------------------------------\n")
      cat("Maximum Sharpe Ratio Portfolio (Short):\n")
      cat(paste("  Annual Expected Return: ", round(max_sharpe_portfolio_short$targetReturn / 100 * 252 * 100, 2), "%", "\n", sep=""))
      cat(paste("  Annual Standard Deviation: ", round(max_sharpe_portfolio_short$targetRisk / 100 * sqrt(252) * 100, 2), "%", "\n", sep=""))
      cat(paste("  Sharpe Ratio (Annualized): ", round(max_sharpe_value_short, 4), "\n"))
      
      png("thesis/sharpe_ratio_short_during_covid.png", width = 800, height = 600, res = 100) # SAVE
      plot(frontier_points_short$targetRisk, frontier_points_short$targetReturn,
           xlab = "Standard Deviation (%)", ylab = "Expected Return (%)",
           type = "p", pch = 16, col = "darkgreen")
      points(max_sharpe_portfolio_short$targetRisk, max_sharpe_portfolio_short$targetReturn,
             col = "red", pch = 19, cex = 1.5)
      text(max_sharpe_portfolio_short$targetRisk, max_sharpe_portfolio_short$targetReturn,
           labels = paste("Max Sharpe\n(", round(max_sharpe_value_short, 2), ")", sep = ""),
           pos = 4, col = "red", cex = 0.8)
      lines(frontierPoints(shortFrontier), col = "red", lwd = 2)
      grid()
      dev.off() 
    }
  }
}
cat("\n\n####################################################\n")
cat("### END OF ANALYSIS FOR PERIOD: COVID ###\n")
cat("####################################################\n\n")