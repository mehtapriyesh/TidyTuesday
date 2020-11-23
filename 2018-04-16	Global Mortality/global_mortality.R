
#Web Application on: https://priyeshmehta.shinyapps.io/globalmortality/


library(tidyverse)
library(tidytuesdayR)
library(ggthemes)
library(tidytext)
library(scales)
library(extrafont)
library(glue)
library(showtext)
library(maps)
library(plotly)
library(gridExtra)
library(ggpubr)

#font_import() In case using system fonts for first time

font_add("Georgia","georgia.ttf")
font_add("Calibri", "calibri.ttf")
font_add_google("Bitter")

font_families()

font_families() #Used to check if our fonts are available

tt <- tt_load("2018-04-16")
global_mortality = tt$global_mortality

theme_set(theme_fivethirtyeight() + 
    theme(
      axis.text = element_text(family = "Calibri", size = 10),
      axis.title = element_text(family = "Georgia", size = 14), 
      strip.text.x = element_text(size = 12, face = "bold", family = "serif"), 
      plot.title = element_text(family = "Georgia", face = "bold", hjust = 0.5, size = 20)))

place = "India"
reason = c("Cardiovascular Diseases","Diabetes","Suicide", "Neonatal Deaths", "Tuberculosis")
time = 2001

mortality_processed = global_mortality %>%
  pivot_longer(names_to = "Cause", cols = contains("%"), values_to = "Percent") %>%
  mutate(
    Percent = Percent/100,
    Cause = str_trim(str_to_title(sub(" [(]%[)]","", Cause)))
  ) 


mortality_processed %>% 
  filter(year %in% seq(1991,2016,5), country == place) %>% 
  group_by(year) %>% 
  slice_max(Percent, n = 10) %>% 
  mutate(
    Cause = reorder_within(Cause, Percent, year)
  ) %>% 
  ggplot(aes(Cause, Percent, fill = Cause)) +
  geom_col() +
  coord_flip() +
  scale_x_reordered() +
  scale_y_continuous(labels = percent_format())  + 
  labs(title = glue("Top 10 Causes of Death in {place} since 1991"), y = "\n Percent Contribution to Total Number of Deaths in a Year", x = "") +
  theme(legend.position = "", plot.margin =  unit(c(1,1,1,1), "cm"), panel.spacing = unit(1.5, "lines")) + 
  facet_wrap(~year, ncol = 2, scales = "free_y")

line_plot = mortality_processed %>% 
  filter(Cause %in% reason, country == place) %>% 
  ggplot(aes(year, Percent, col = Cause,
             text = paste(
             "Year:", year,
             "\nCause: ", Cause,
             "\nPercent:", round(Percent,4)*100, "%"))) +
  geom_line(aes(lty = Cause, group = 1), lwd = 1.2) +
  scale_y_continuous(labels = percent_format()) +
  theme(legend.direction = "vertical", legend.box = "horizontal", 
        legend.position = "right") +
  labs(title = glue("Trend of Selected Factors of Death in {place}"), x = "\n Year", 
       y = "Percent Share \n")

ggplotly(line_plot, tooltip = c("text"))
  
country_cause = mortality_processed %>% 
  filter(Cause == reason[1], year == time) 


country_cause_map = country_cause%>% 
  inner_join(maps::iso3166, by = c(country_code = "a3")) %>% 
  inner_join(map_data("world"), by = c(mapname = "region")) %>% 
  ggplot(aes(long, lat, group = group,
    text = paste(round(Percent*100,2) , "% of Deaths in", country, "were from", reason[5]))) +
  geom_polygon(aes(fill = Percent)) +
  #borders("world") +
  coord_cartesian(ylim = c(-50, 90)) +
  scale_fill_gradientn(colours = c("#98FB98", "#FF4500" ,"#191970"), labels = percent_format()) +
  theme(legend.direction = "vertical", legend.box = "horizontal", 
        legend.position = "left", plot.margin =  unit(c(1,0,1.5,0.5), "cm"),
        panel.background = element_rect(colour = "#CAEAFF",
                                        fill = "#CAEAFF")) +
  labs(x = "", y = "")

pal = colorRampPalette(colors = c("#191970","#B0C4DE"))

country_cause_bar = country_cause %>% 
  slice_max(Percent, n = 15) %>% 
  mutate(country = fct_reorder(country, Percent)) %>% 
  ggplot(aes(country, Percent, fill = country), alpha = 0.8) +
  geom_col() +
  scale_y_continuous(labels = percent_format()) +
  theme(legend.position = "", plot.margin =  unit(c(1,1,1.5,1.5), "cm")) +
  labs(x = "", y = "") + 
  coord_flip() +
  scale_fill_manual(values = rev(pal(15))) 

grid.arrange(country_cause_map, country_cause_bar, ncol = 2, widths = c(2, 1),
  top = text_grob(label = glue("% of Deaths contributed by {reason[5]} in each country all across the World in {time}."), hjust = 0.5, family = "Georgia", size = 20, face = "bold" ))

