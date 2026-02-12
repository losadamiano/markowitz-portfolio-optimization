library(fPortfolio)
library(quantmod)
library(timeSeries)
library(PerformanceAnalytics)
library(ggplot2)
library(tidyverse)

# DEFINE ANALYSIS PERIOD AND TARGET TICKERS
start_date <- as.Date("2015-01-01")
end_date <- as.Date("2024-12-31")
top_10_tickers_by_market_cap <- c("ISP.MI", "UCG.MI", "RACE.MI", "ENEL.MI",
                                  "G.MI", "ENI.MI", "LDO.MI", "STLAM.MI",
                                  "PST.MI", "STMMI.MI")

# DOWNLOAD HISTORICAL ADJUSTED CLOSE DATA AND HANDLE ERRORS
adjusted_cols <- list()
for (symbol in top_10_tickers_by_market_cap) {
  tryCatch({
    getSymbols(symbol, from = start_date, to = end_date, auto.assign = TRUE)
    adjusted_cols[[symbol]] <- Ad(get(symbol))
  }, error = function(e) {
    message("ERROR DOWNLOADING DATA FOR ", symbol, ": ", e$message)
  })
}

# MERGE ASSET DATA INTO A SINGLE DATASET
if (length(adjusted_cols) == 0) stop("NO DATA AVAILABLE FOR ANALYSIS")

merged_adjusted_data <- do.call(merge, adjusted_cols)
colnames(merged_adjusted_data) <- names(adjusted_cols)

# CONVERT TO TIME SERIES AND CALCULATE PERCENTAGE DAILY RETURNS
ftseData <- as.timeSeries(merged_adjusted_data)
ftseData_no_na <- na.omit(ftseData)
ftseData.ret <- returns(ftseData_no_na) * 100

# EXPLORATORY DATA ANALYSIS: DESCRIPTIVE STATISTICS
cat("STATISTICAL SUMMARY OF RETURNS:\n")
print(summary(ftseData.ret))
cat("\nMEAN RETURNS:\n")
print(apply(ftseData.ret, 2, mean))
cat("\nSTANDARD DEVIATION (VOLATILITY):\n")
print(apply(ftseData.ret, 2, sd))

# PREPARE DATA FOR GGPLOT VISUALIZATION
ftseData.ret_df <- as.data.frame(ftseData.ret)
ftseData.ret_df$Date <- index(ftseData.ret)
ftseData_long <- pivot_longer(ftseData.ret_df, cols = -Date, names_to = "Asset", values_to = "Return")

min_y_global <- min(ftseData_long$Return)
max_y_global <- max(ftseData_long$Return)

# PLOT RETURNS TIME SERIES
returns_plot <- ggplot(ftseData_long, aes(x = Date, y = Return, color = Asset)) +
  geom_line() +
  facet_wrap(~ Asset, ncol = 2, scales = "free_x") +
  labs(title = "TIME SERIES OF DAILY RETURNS",
       y = "RETURN (%)", x = "TIME") +
  scale_y_continuous(limits = c(min_y_global, max_y_global)) +
  theme_minimal() +
  theme(legend.position = "none", strip.text = element_text(hjust = 0))

print(returns_plot)
# Observation: Significant variability in volatility is observed across the portfolio assets.
# Stocks like ENEL, Generali (G.MI), and Poste Italiane show relatively lower volatility, 
# suggesting higher stability. In contrast, ISP, Leonardo, Stellantis, STMMI, and Unicredit exhibit higher volatility.

# PREPARE DATA AND PLOT HISTORICAL ADJUSTED CLOSE PRICES
df_prices <- as.data.frame(merged_adjusted_data)
df_prices$Date <- index(merged_adjusted_data)
df_prices_long <- pivot_longer(df_prices, cols = -Date, names_to = "Ticker", values_to = "Price")

ggplot(df_prices_long, aes(x = Date, y = Price, color = Ticker)) +
  geom_line() +
  facet_wrap(~ Ticker, scales = "free_y", ncol = 2) +
  labs(title = "HISTORICAL ADJUSTED CLOSE PRICES",
       x = "DATE", y = "ADJUSTED CLOSE PRICE") +
  theme_minimal() +
  theme(legend.position = "none", strip.text = element_text(hjust = 0))
# Observation: Performance profiles vary significantly. Ferrari (RACE) and ENEL show steady growth, 
# while Unicredit and STMMI are characterized by higher fluctuations. 
# Leonardo and Stellantis have shown strong recent momentum.

# CORRELATION AND CLUSTER ANALYSIS
assetsCorImagePlot(ftseData.ret)
plot(assetsSelect(ftseData.ret))
assetsCorEigenPlot(ftseData.ret)
# Analysis: The correlation matrix and dendrogram highlight a strong positive correlation 
# between major financial institutions (ISP and UCG), suggesting low diversification within the banking sector. 
# Ferrari appears to act as a potential diversifier. 
# Energy and Industrial sectors show moderate correlations, while Leonardo displays distinct return behavior.

# CONSTRUCT EFFICIENT FRONTIER - LONG ONLY CONSTRAINTS
ftseSpec_long <- portfolioSpec()
setEstimator(ftseSpec_long) <- "shrinkEstimator"
setNFrontierPoints(ftseSpec_long) <- 25
longFrontier <- portfolioFrontier(ftseData.ret, ftseSpec_long)
tailoredFrontierPlot(longFrontier, risk = "Cov", main = "MV PORTFOLIO - LONG ONLY")
print(longFrontier)
# Observation: The curve illustrates the risk-return trade-off. Increased risk yields higher expected returns, 
# though the slope diminishes at higher risk levels. The Global Minimum Variance Portfolio (red dot) 
# is primarily composed of low-volatility stocks like ENEL and PST.

# VISUALIZE WEIGHTS AND RISK CONTRIBUTIONS - LONG ONLY
num_assets <- ncol(ftseData.ret)
col_palette <- seqPalette(num_assets, "YlOrRd")
weightsPlot(longFrontier, col = col_palette)
weightedReturnsPlot(longFrontier)
# Observation: Low-target return portfolios are dominated by ENEL and Poste Italiane. 
# As target returns increase, allocation shifts toward higher-yield/higher-risk assets like Ferrari and STMMI.
covRiskBudgetsPlot(longFrontier)
# Risk contribution analysis: Portfolio risk is largely driven by assets with higher weights (ENEL, PST) 
# at low-risk levels, shifting towards RACE and STMMI as the target return increases.

# MONTE CARLO SIMULATION - LONG ONLY FRONTIER
par(mfrow = c(1, 1))
set.seed(1953)
frontierPlot(longFrontier, pch = 19, cex = 0.7, main = "MONTE CARLO SIMULATION - LONG ONLY")
monteCarloPoints(longFrontier, mcSteps = 10000, pch = 19, cex = 0.5)
twoAssetsLines(longFrontier, col = "orange", lwd = 1)
lines(frontierPoints(longFrontier), col = "red", lwd = 2)

# CONSTRUCT EFFICIENT FRONTIER - SHORT SELLING ALLOWED
shortSpec <- portfolioSpec()
setNFrontierPoints(shortSpec) <- 25
setSolver(shortSpec) <- "solveRshortExact"
shortFrontier <- portfolioFrontier(ftseData.ret, shortSpec, constraints = "Short")
tailoredFrontierPlot(shortFrontier, risk = "Cov", main = "MV PORTFOLIO - SHORT SELLING")
print(shortFrontier)
# Observation: Short selling expands the investment opportunity set, shifting the frontier 
# upward and to the left. This allows for higher returns at lower risk levels compared to long-only constraints.

# VISUALIZE WEIGHTS AND RISK CONTRIBUTIONS - SHORT SELLING
weightsPlot(shortFrontier, col = col_palette)
weightedReturnsPlot(shortFrontier)
# Note: Negative Y-axis values indicate short positions in specific assets.
covRiskBudgetsPlot(shortFrontier)
# Observation: Short positions allow certain assets to contribute negatively to total portfolio risk, 
# acting as hedges and potentially improving the overall risk-adjusted profile.

# MONTE CARLO SIMULATION - SHORT SELLING FRONTIER
par(mfrow = c(1, 1))
set.seed(1953)
frontierPlot(shortFrontier, pch = 19, cex = 0.7, main = "MONTE CARLO SIMULATION - SHORT")
monteCarloPoints(shortFrontier, mcSteps = 10000, pch = 19, cex = 0.5)
twoAssetsLines(shortFrontier, col = "orange", lwd = 1)
lines(frontierPoints(shortFrontier), col = "red", lwd = 2)

