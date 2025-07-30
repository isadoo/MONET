# Script to create LAVA package logo
# Run this script to generate the package logo

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Load necessary packages
if (!requireNamespace("hexSticker", quietly = TRUE)) {
  install.packages("hexSticker")
}
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}
if (!requireNamespace("showtext", quietly = TRUE)) {
  install.packages("showtext")
}

library(hexSticker)
library(ggplot2)
library(showtext)

# Add a Google font
font_add_google("Roboto Condensed", "roboto")
showtext_auto()

# Create a simple plot for the sticker
set.seed(123)
x <- seq(-1, 1, length.out = 100)
y1 <- exp(x)
y2 <- exp(x * 1.5)
ratio <- log(y2/y1)

plot_data <- data.frame(
  x = x,
  y1 = y1,
  y2 = y2,
  ratio = ratio
)

p <- ggplot(plot_data, aes(x = x)) +
  geom_line(aes(y = ratio), color = "#FF5500", size = 1.2) +
  theme_void() +
  theme(panel.background = element_rect(fill = "transparent", color = NA))

# Create the hexagon sticker
sticker(
  p,
  package = "LAVA",
  p_color = "#FFFFFF",
  p_size = 20,
  p_y = 1.5,
  s_x = 1,
  s_y = 0.9,
  s_width = 1.7,
  s_height = 1,
  h_fill = "#0054AD",
  h_color = "#002B59",
  filename = "man/figures/logo.png",
  dpi = 600
)

# Print confirmation
cat("Logo created and saved to man/figures/logo.png\n")