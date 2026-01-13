
library(ggplot2)


trait_data <- read.csv("inst/extdata/vignette_trait_df_pop.csv")

p <- ggplot(trait_data, aes(x = individual, y = trait, color = factor(population))) +
  geom_point(alpha = 0.7, size = 2) +
  labs(
    title = "Trait Values by Individual",
    x = "Individual",
    y = "Trait Value",
    color = "Population"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_blank(), 
    axis.ticks.x = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank()
  ) +
  scale_color_viridis_d(option = "turbo")  


print(p)


ggsave("trait_by_population.png", plot = p, width = 12, height = 6, dpi = 300)


p2 <- ggplot(trait_data, aes(x = individual, y = trait, color = factor(population))) +
  geom_point(alpha = 0.7, size = 1.5) +
  facet_wrap(~ population, scales = "free_x", ncol = 6) +
  labs(
    title = "Trait Values by Individual (Faceted by Population)",
    x = "Individual",
    y = "Trait Value",
    color = "Population"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    strip.background = element_rect(fill = "lightgray"),
    strip.text = element_text(face = "bold")
  ) +
  scale_color_viridis_d(option = "turbo")

print(p2)


ggsave("trait_by_population_faceted.png", plot = p2, width = 14, height = 8, dpi = 300)


cat("\nSummary statistics by population:\n")
summary_stats <- aggregate(trait ~ population, data = trait_data, 
                           FUN = function(x) c(mean = mean(x), 
                                                sd = sd(x), 
                                                min = min(x), 
                                                max = max(x)))
print(summary_stats)
