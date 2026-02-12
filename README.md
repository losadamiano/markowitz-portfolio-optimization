# Portfolio Optimization: A Markowitz Approach on FTSE MIB 🇮🇹

This repository contains the **R implementation** of the **Modern Portfolio Theory (MPT)**, formulated by Harry Markowitz in 1952, applied to a case study of the **FTSE MIB** index. 

The project analyzes portfolio efficiency across three distinct economic periods to evaluate how market dynamics and investment constraints (**Long-Only vs. Short Selling**) affect optimal asset allocation.

---

## Project Overview

The core of this research is the search for an optimal balance between expected return and risk through **diversification**. By analyzing the covariance between assets, the scripts identify the **Efficient Frontier**—the set of portfolios offering the maximum return for a given level of risk.



## Analyzed Periods

The analysis is divided into three R scripts, each covering a specific market phase:

1. **`Pre_COVID_Analysis.R`**: Baseline market conditions prior to the 2020 pandemic.
2. **`COVID_Period_Analysis.R`**: Impact of the global pandemic on volatility and asset correlations.
3. **`Post_War_Inflation_Analysis.R`**: Recent dynamics influenced by geopolitical conflicts and rising inflation.

---

## Key Features

* **Portfolio Types**: Implementation of **Global Minimum Variance Portfolios (MVP)** and **Tangency Portfolios** (maximizing the Sharpe Ratio).
* **Constraint Analysis**: Comparison between **Long-Only** portfolios (no short selling) and **Unlimited Short Selling** scenarios.
* **Risk Management**: Evaluation of risk contributions and **covariance risk budgets**.
* **Visualizations**: Generation of Efficient Frontiers, risk contribution charts, and cumulative return plots.

---

## Results & Conclusions

The empirical analysis conducted highlights several critical findings:

* **Impact of Constraints**: The **Long-Only frontier** is consistently more restrictive and "internal" compared to the unlimited short-selling frontier, as constraints limit diversification opportunities.
* **Dynamic Parameters**: The study confirms that the MPT is a vital framework for rational capital allocation, but its effectiveness depends on recognizing the **dynamism of market parameters** (covariance matrices) across different periods.
* **Diversification**: Results reiterate that strategic asset combination can mitigate overall risk without necessarily compromising expected returns, provided assets are not perfectly correlated.
* **Robustness**: While the theory has limitations (such as the assumption of normal returns), it remains an indispensable tool for identifying **robust portfolios** in evolving financial environments.

---

## Requirements

To run these scripts, you need **R** and the following packages:
* `fPortfolio` (Rmetrics)
* `quantmod`
* `ggplot2`
* `tidyverse`
* `timeSeries`

## How to Use

1.  **Clone the repository**.
2.  **Create a subfolder** named `/thesis` in the root directory to allow the scripts to save graphical outputs automatically.
3.  **Set the main directory** as your working directory in RStudio.
4.  **Run the scripts** in chronological order to observe the evolution of the FTSE MIB efficiency.

---
**Author:** Damiano Losa  
**Field:** Quantitative Finance / Portfolio Management
