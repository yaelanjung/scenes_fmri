
## merge individual participants file into
## one csv file
## Yaelan J.
## last update Feb 25 2019

library(dplyr)
library(readr)
library(data.table)
library(tidyverse)

setwd('/Users/yaelanj/Documents/projects/scenesTS/mturk/mturk_data_2021/v4')
dt = read.csv("final64_rating_all.csv", stringsAsFactors = FALSE)

## temperature judgment
dt.temp <- dt %>% 
        filter(blockcode == 'HC') %>%
        filter(trialcode == 'likert_hc') %>%
        select(-X, -computer.platform, -time, -build, -stimulusitem1, -stimulusitem2, -latency) %>%
        separate(stimulusitem3, "/",
           into = c("dir", "full_imgname")) %>%
        mutate(image_name = gsub('.{4}$', '', full_imgname)) %>%
        mutate(category = gsub)
        select(-dir, -full_imgname)

# agg for subject mean and sd
dt.temp$response <- as.numeric(dt.temp$response)

# calculate subject mean and std
agg.dt.temp <- dt.temp %>%
        group_by(subject) %>%
        summarise(mean = mean(response), std = sd(response), n = n())  

# create colume for standardized response value
# by substracting the mean and divide it by the std
dt.temp_mer <- merge(dt.temp, agg.dt.temp, by = 'subject')
dt.temp_mer <- dt.temp_mer %>%
              mutate(std_response = (response - mean)/std)

# average standardized score (across participants) for each image
agg.temp.img <- dt.temp_mer %>%
              group_by(image_name) %>%
              summarize(temp_score = mean(std_response))

# create category column
agg.temp.img <- agg.temp.img %>%
      mutate(category = str_sub(image_name, end = -5)) 

# create temperature colum by median split per each category
# by ranking images by temp score within the category

agg.temp.ranked <- agg.temp.img %>%
                arrange(category, temp_score) %>%
                group_by(category) %>%
                mutate(rank = row_number()) %>%
                mutate(num_per_cat = max(rank)/2) %>%
                mutate(temperature = case_when(
                       rank > num_per_cat ~ 'warm',
                       rank <= num_per_cat ~ 'cold')) %>%
                select(-rank, -num_per_cat)

# anova
agg.temp.ranked$category <- factor(agg.temp.ranked$category)
res.aov <- aov(temp_score ~ category, data = agg.temp.ranked)
summary(res.aov)

# plotting
library(ggpubr)
ggline(agg.temp.ranked, x = "category", y = "temp_score",
       add = c("mean_se", "jitter"),
       order = c("beach", "city", "forest", "station"),
       ylab = "temperature rating", xlab = "category")

# do boxplot



# house keeping 
rm(dt.temp, dt.temp.img, agg.dt.temp)


##### sound level #####
dt.snd <- dt %>% 
  filter(blockcode == 'NQ') %>%
  filter(trialcode == 'likert_nq') %>%
  select(-X, -computer.platform, -time, -build, -stimulusitem1, -stimulusitem2, -latency) %>%
  separate(stimulusitem3, "/",
           into = c("dir", "full_imgname")) %>%
  mutate(image_name = gsub('.{4}$', '', full_imgname)) %>%
  select(-dir, -full_imgname)

# agg for subject mean and sd
dt.snd$response <- as.numeric(dt.snd$response)
agg.dt.snd <- dt.snd %>%
  group_by(subject) %>%
  summarise(mean = mean(response), std = sd(response), n = n())  

# create colume for standardized response value
# by substracting the mean and divide it by the std
dt.snd_mer <- merge(dt.snd, agg.dt.snd, by = 'subject')
dt.snd_mer <- dt.snd_mer %>%
  mutate(std_response = (response - mean)/std)

# average standardized score (across participants) for each image
agg.snd.img <- dt.snd_mer %>%
  group_by(image_name) %>%
  summarize(snd_score = mean(std_response))

# create category column
agg.snd.img <- agg.snd.img %>%
  mutate(category = str_sub(image_name, end = -5)) # delete image number

# create temperature colum by median split per each category
# by ranking images by temp score within the category

agg.snd.ranked <- agg.snd.img %>%
  arrange(category, snd_score) %>%
  group_by(category) %>%
  mutate(rank = row_number()) %>%
  mutate(num_per_cat = max(rank)/2) %>%
  mutate(soundlevel = case_when(
    rank > num_per_cat ~ 'noisy',
    rank <= num_per_cat ~ 'quiet')) %>%
  select(-rank, -num_per_cat)

# anova
agg.snd.ranked$category <- factor(agg.snd.ranked$category)
res.aov <- aov(snd_score ~ category, data = agg.snd.ranked)
summary(res.aov)
