# Header #############################################################
#
# Author: Lisa Nicvert
# Email:  lisa.nicvert@fondationbiodiversite.fr
#
# Date: 2025-05-05
#
# Script Description: test formulas for Cramér's V


# Libraries ---------------------------------------------------------------
library(effectsize)
library(rcompanion)

set.seed(42)

# Create dummy data -------------------------------------------------------
s1 <- 1000
s2 <- 500

p1 <- c(0.2, 0.8) # c(0.1, 0.1, 0.5, 0.3)
p2 <- c(0.8, 0.2) # c(0.5, 0.1, 0.1, 0.3)
n <- length(p1)

x <- rbinom(n = n, size = s1, prob = p1)
names(x) <- c("pasture", "urban") #, "forest", "wetland")
y <- rbinom(n = n, size = s2, prob = p2)
names(y) <- names(x)

tab <- matrix(c(x, y), nrow = 2, byrow = TRUE)
rownames(tab) <- c("obs", "france")
colnames(tab) <- names(x)

# lambda1 <- 100
# lambda2 <- 100
# x <- rpois(n = n, lambda1) # sample(x = 100:1000, size = n)
# y <- rpois(n = n, lambda2) # sample(x = 100:1000, size = n)


# Homogeneity Chi2 --------------------------------------------------------
(chisq_h <- chisq.test(tab))

# No adjustment for small samples
N <- sum(tab)

r <- 2
c <- n
df <- min(r - 1, c - 1)
(v_h <- sqrt(chisq_h$statistic/(N*df)))

# With effectsize
v_h_func <- cramers_v(x = tab, adjust = FALSE)
(v_h_func$Cramers_v)

# Test with Rcompanion
(v_h_rc <- cramerV(tab)) # Same result as uncorrected

# Adjustment for small samples (not equal)
r_corr <- r - ((1/(N-1))*(r-1)^2)
c_corr <- c - ((1/(N-1))*(c-1)^2)
df_corr <- min(r_corr - 1, c_corr - 1)
(v_h_corr <- sqrt(chisq_h$statistic/(N*df_corr)))

v_h_func <- cramers_v(x = tab)
(v_h_func$Cramers_v_adjusted)

# Conformity Chi2 tab# Conformity Chi2 ----------------------------------------------------
(chisq_c <- chisq.test(x, p = p2))
Nx <- sum(x)

# Fei correction
(fei <- sqrt(chisq_c$statistic/abs(Nx*(1/min(chisq_c$expected/Nx)-1))))

f <- fei(x = x, p = p2)
f$Fei

# Chi-squared with modified ddl
r <- 2
c <- n
df <- c - 1
(v_c <- sqrt(chisq_c$statistic/(Nx*df)))

(v_c_func <- cramerVFit(x = x, p = p2))


