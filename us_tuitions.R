

library(tidyverse)
library(maps)

tuition = readxl::read_xlsx("C:/Users/mehta/Downloads/us_avg_tuition.xlsx")

tuition = tuition %>% 
  mutate(
    mean = rowMeans(select(., is.numeric)),
    State = tolower(State)
  ) %>%
  right_join(map_data("state"), by = c(State = "region"))


tuition %>%
  ggplot(aes(long, lat, fill = mean, group = group, color = "#000000")) +
  geom_polygon() +
  coord_map() +
  theme_void() +
  scale_color_identity(F) + 
  scale_fill_gradient2(low = "#00FFFF",high = "#008B8B") + 
  labs(fill = "Average Cost", title = "Spread of Average Tuition Costs in United States") 
  

  
  
  
  
  