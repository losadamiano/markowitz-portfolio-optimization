# FTSE MIB Quantitative Portfolio Optimization
This project provides a rigorous quantitative framework for portfolio optimization using a selection of the top 10 stocks by market capitalization on the **FTSE MIB** index. 

The analysis is conducted in **R**, leveraging the `fPortfolio` and `quantmod` libraries to implement the **Markowitz Mean-Variance framework**.

## Project Overview
The study covers the period from **January 2015 to December 2024**, analyzing the risk-return profile of the selected key Italian equities.

### Key Features:
- **Exploratory Data Analysis (EDA):** Time-series visualization of adjusted prices and daily returns.
- **Correlation Analysis:** Cluster dendrograms and Eigenvalue plots to identify diversification opportunities (e.g., Ferrari as a portfolio diversifier).
- **Efficient Frontier Construction:** - **Long-Only Constraints:** Identifying the Minimum Variance Portfolio (MVP).
  - **Short-Selling Enabled:** Demonstrating how relaxing constraints expands the opportunity set and improves the Sharpe Ratio.
- **Risk Budgeting:** Analysis of the contribution of individual assets to total portfolio volatility.
- **Monte Carlo Simulations:** 10,000 iterations to validate the stability of the efficient frontier.

## Methodology
- **Estimator:** Shrinkage Estimator used for the covariance matrix to improve stability.
- **Optimization:** Quadratic programming solver for the Mean-Variance objective function.

## How to Run
1. Clone the repository.
2. Ensure the following R packages are installed: `fPortfolio`, `quantmod`, `tidyverse`, `PerformanceAnalytics`.
3. Run `main_analysis.R`.

## Results
The analysis highlights a high correlation within the Italian banking sector (Intesa Sanpaolo, Unicredit), suggesting the need for cross-sector diversification (Utilities and Automotive) to optimize the risk-adjusted returns.
