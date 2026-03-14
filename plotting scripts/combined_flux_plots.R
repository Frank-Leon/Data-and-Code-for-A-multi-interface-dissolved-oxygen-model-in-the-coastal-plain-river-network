## 设置工作路径
setwd("D:/.学校/研究生/组会/溶解氧论文")

library(tidyverse)
library(dplyr)
library(openxlsx)
library(tidyr)
library(purrr)
library(gridExtra)

# 读取数据
data <- read.xlsx("aw_sw_flux_2-stage1.xlsx", sheet = "CS1-1")

# 定义统计函数
sem <- function(x) { sd(x, na.rm = TRUE) / sqrt(length(na.omit(x))) }
summary_min <- function(x) { mean(x, na.rm = TRUE) - sem(x) }
summary_max <- function(x) { mean(x, na.rm = TRUE) + sem(x) }

# 准备数据
plot_data <- data %>% 
  filter(condition %in% c("S1", "S2", "S3", "S4", "S5", "S6")) %>%
  mutate(
    group = factor(interface, 
                   levels = c("AWI", "SWI"),
                   labels = c("AWI", "SWI")),
    condition = factor(condition, levels = paste0("S", 1:6)),
    # 创建组合变量，用于x轴定位
    x_pos = as.numeric(condition),
    # 在每个条件内微调AWI和SWI的位置
    x_pos = ifelse(group == "AWI", x_pos - 0.2, x_pos + 0.2)
  )

# 计算每组统计值
stat_data <- plot_data %>%
  group_by(condition, group) %>%
  summarise(
    mean_val = mean(flux, na.rm = TRUE),
    sem_val = sem(flux),
    x_pos = first(x_pos),  # 获取x位置
    .groups = 'drop'
  )

# 计算每个条件下AWI与SWI通量均值之比
ratio_data <- plot_data %>%
  group_by(condition, group) %>%
  summarise(mean_val = mean(flux, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = group, values_from = mean_val) %>%
  mutate(
    ratio_value = AWI / SWI,
    x_pos = as.numeric(condition)  # 比值标注位于每个条件中间
  )

# 动态计算左侧Y轴最大值（通量）
max_flux <- max(stat_data$mean_val + stat_data$sem_val, na.rm = TRUE)
left_y_max <- ceiling(max_flux / 5) * 5
if (left_y_max < 5) left_y_max <- 5

# 计算左侧Y轴刻度间隔
if (left_y_max <= 5) {
  left_breaks <- seq(0, left_y_max, by = 1)
} else if (left_y_max <= 10) {
  left_breaks <- seq(0, left_y_max, by = 2)
} else if (left_y_max <= 20) {
  left_breaks <- seq(0, left_y_max, by = 5)
} else {
  left_breaks <- seq(0, left_y_max, by = 10)
}

# 固定右侧Y轴最大值为5
right_y_max <- 5

# 计算右侧Y轴刻度间隔
# 设置0.5为间隔
right_breaks <- seq(0, right_y_max, by = 1)

# 计算右侧Y轴的缩放比例
ratio_scale <- left_y_max / right_y_max

p <- ggplot() +  # 移除初始的aes映射
  # 先绘制柱状图 - 使用 stat_data 作为数据源
  geom_col(
    data = stat_data,
    aes(x = x_pos, y = mean_val, color = group),
    fill = "white",
    linewidth = 1,
    width = 0.3
  ) +
  # 再绘制误差线顶部的横线
  geom_errorbar(
    data = stat_data,
    aes(x = x_pos, ymin = mean_val, ymax = mean_val + sem_val, color = group),
    width = 0.2,  # 顶部横线宽度
    size = 1
  ) +
  # 散点 - 空心圆点（仍然使用 plot_data）
  geom_jitter(
    data = plot_data,
    aes(x = x_pos, y = flux, color = group),
    size = 2,
    width = 0.05,
    height = 0,
    fill = NA,
    shape = 1,
    stroke = 0.8
  ) +
  # 添加AWI/SWI比值折线图
  geom_line(
    data = ratio_data,
    aes(x = x_pos, y = ratio_value * ratio_scale),
    color = "#FF0000",
    linewidth = 1,
    linetype = "dashed"
  ) +
  geom_point(
    data = ratio_data,
    aes(x = x_pos, y = ratio_value * ratio_scale),
    color = "#FF0000",
    fill = "#FF0000",
    size = 3,
    shape = 22
  ) +
  # X轴和Y轴设置
  scale_x_continuous(
    breaks = 1:6,
    labels = paste0("S", 1:6)
  ) +
  scale_y_continuous(
    expand = c(0, 0), 
    breaks = left_breaks,  # 使用动态计算的刻度
    limits = c(0, left_y_max),
    sec.axis = sec_axis(
      ~ . / ratio_scale, 
      # name = "AWI/SWI Ratio",
      name = NULL,  # <--- 修改这里：将 "AWI/SWI Ratio" 替换为 NULL
      breaks = right_breaks  # 使用动态计算的刻度
    )
  ) +
  # 颜色设置
  scale_color_manual(values = c("AWI" = "#3573e5", "SWI" = "#f26fb2")) +
  # 标签和主题
  labs(
    title = "Flux Comparison Across Conditions",
    x = "Condition",
    y = "Flux"
  ) +
  theme_classic(base_family = "Times New Roman") +
  theme(
    text = element_text(family = "Times New Roman"),
    legend.position = "top",
    legend.title = element_blank(),
    # plot.title = element_text(hjust = 1, size = 16, face = "bold"),
    # axis.title = element_text(color = "black", face = "bold", size = 15),
    # axis.title.y.right = element_text(color = "black"),
    # axis.text = element_text(color = "black", face = "bold", size = 15),
    # axis.text.y.right = element_text(color = "black"),
    axis.title = element_blank(), # 添加此行：彻底隐藏所有横纵坐标名称
    
    # --- 2. 调整坐标轴数字（刻度标签）的字体 ---
    # 里修改 size(大小), face("plain"正常, "bold"加粗), family(字体)
    axis.text = element_text(family = "Times New Roman", color = "black", face = "plain", size = 30),
    axis.text.y.right = element_text(family = "Times New Roman", color = "black", face = "plain", size = 30),
    
    axis.line = element_line(color = "black", linewidth = 1),
    axis.ticks = element_line(color = "black", linewidth = 1),
    axis.ticks.length = unit(0.07, "in"),
    axis.title.x = element_text(margin = margin(t = 15)),
    axis.title.y = element_text(margin = margin(r = 15)),
  )

# 显示图表
print(p)

# 导出为高分辨率PNG
ggsave(
  filename = "combined_flux_plots_single_axis_1-0314.png",
  plot = p,
  width = 12,
  height = 7,
  dpi = 600,
  bg = "white"
)

