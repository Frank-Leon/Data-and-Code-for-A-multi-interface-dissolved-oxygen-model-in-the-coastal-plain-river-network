# 设置工作路径 ------------------------------------------------------------------
setwd("D:/.学校/研究生/组会/溶解氧论文")

# 加载所需包 -------------------------------------------------------------------
library(readxl)
library(ggplot2)
library(dplyr)
library(tidyr)

# 数据读入 --------------------------------------------------------------------
# 从Excel文件中读取Sheet S1
long_data <- read_xlsx("R_耗氧数据.xlsx", sheet = "S3", 
                       col_names = c("time", "C", "treat")) %>%
  
  # 确保所有列都是数值类型
  mutate(
    time = as.numeric(time),
    C = as.numeric(C)
  ) %>%
  
  # 移除无效行
  filter(!is.na(time), !is.na(C)) %>% 
  
  # 处理组标准化
  mutate(treat = factor(gsub("g", "", treat), levels = c("25", "50", "75", "100"))) %>% 
  filter(treat %in% c("25", "50", "75", "100"))

# 为每个处理组单独设置拟合参数 -------------------------------------------------
param_df <- data.frame(
  treat = factor(c("25", "50", "75", "100"), levels = c("25", "50", "75", "100")),
  # a = c(9.27, 4.94, 5.43, 1.93),     # 溶解氧衰减参数
  # k = c(0.00168, 0.00183, 0.00215, 0.01132) # 反应速率常数
  # a = c(8.2, 7.2, 7.07, 5.08),     # 溶解氧衰减参数
  # k = c(0.00047, 0.00058, 0.00127, 0.00503) # 反应速率常数
  a = c(8.5, 5.56, 2.87, 0.5),     # 溶解氧衰减参数
  k = c(0.00084, 0.00224, 0.01484, 0.02095) # 反应速率常数
)

# 将参数数据框添加到原始数据中
long_data <- left_join(long_data, param_df, by = "treat")

# 拟合曲线计算函数 (核心) -----------------------------------------------------
calculate_fit <- function(time, C0, a, k) {
  if(C0 == a) return(rep(NA, length(time)))
  
  A <- C0 / (C0 - a)
  exp_term <- exp(a * k * time)
  (a * A * exp_term) / (A * exp_term - 1)
}

# 为每个处理组计算拟合曲线 ----------------------------------------------------
fit_curves <- data.frame()

# 遍历每个处理组
for (tr in levels(long_data$treat)) {
  # 提取该组的数据和参数
  group_data <- filter(long_data, treat == tr)
  
  if(nrow(group_data) == 0) next
  
  # 获取该组的参数
  a_val <- group_data$a[1]
  k_val <- group_data$k[1]
  
  # 提取初始浓度（时间最接近0的值）
  initial_data <- group_data %>% 
    arrange(time) %>%
    slice(1)
  C0 <- initial_data$C
  
  # 生成基于该组时间范围的时间序列
  time_min <- min(group_data$time)
  time_max <- max(group_data$time)
  time_seq <- seq(time_min, time_max, length.out = 100)
  
  # 计算拟合值
  fitted_C <- calculate_fit(time_seq, C0, a_val, k_val)
  
  # 添加到拟合曲线数据框
  fit_curves <- rbind(fit_curves, 
                      data.frame(
                        time = time_seq,
                        C = fitted_C,
                        treat = tr,
                        a = a_val,
                        k = k_val,
                        stringsAsFactors = FALSE
                      ))
}

# 创建标签数据框用于绘图中的参数标注
label_data <- fit_curves %>%
  group_by(treat) %>%
  slice_tail(n = 1) %>%
  mutate(
    label = paste0(treat, "g: a=", round(a, 2), ", k=", round(k, 5))
  )

# 创建颜色和线型映射 --------------------------------------------------------
treat_colors <- c('25' = '#394d2d', 
                  '50' = '#2e4587', 
                  '75' = '#f8533d', 
                  '100' = '#69008c')

treat_linetypes <- c('25' = "solid", 
                     '50' = "dashed", 
                     '75' = "dotted", 
                     '100' = "dotdash")

# 绘图 -----------------------------------------------------------------------
ggplot() +
  # 1. 绘制原始数据点（添加形状）
  geom_point(
    data = long_data,
    aes(x = time, y = C, fill = treat),
    shape = 21, size = 3, alpha = 0.8,  
    color = case_when(  # 根据treat设置对应的边框颜色
      long_data$treat == "25" ~ "#1a2b15",
      long_data$treat == "50" ~ "#1a2b5c",
      long_data$treat == "75" ~ "#c53a2e",
      long_data$treat == "100" ~ "#4a0068",
      TRUE ~ "black"
    )
  ) +
  # 2. 绘制拟合曲线（使用线型区分）
  geom_line(
    data = fit_curves,
    aes(x = time, y = C, color = treat, linetype = treat),
    linewidth = 1.2
  ) +
  # # 3. 添加参数标签
  # geom_text(
  #   data = label_data,
  #   aes(x = time + 10, y = C, 
  #       label = label,
  #       color = treat),
  #   size = 4,
  #   hjust = 0,
  #   show.legend = FALSE
  # ) +
  # # 4. 添加理论公式标注（位置优化）
  # annotate("text",
  #          x = max(long_data$time, na.rm = TRUE) * 0.05,
  #          y = max(long_data$C, na.rm = TRUE) * 0.95,
  #          label = expression(frac(C["DO,t"], C["DO,t"]-a)==frac(C["DO,0"], C["DO,0"]-a)~e^{a%.%k%.%t}),
  #          parse = TRUE,
  #          hjust = 0, size = 4.5, color = "#333333") +
  # 5. 设置颜色和线型
  scale_color_manual(
    name = "mass of sediment",
    values = treat_colors,
    labels = c("25g", "50g", "75g", "100g")
  ) +
  scale_fill_manual(
    name = "mass of sediment",
    values = c('#afc978','#a9dcf2','#edc0c0','#ddaaf7'),
    labels = c("25g", "50g", "75g", "100g")
  ) +
  scale_linetype_manual(
    name = "mass of sediment",
    values = treat_linetypes,
    labels = c("25g", "50g", "75g", "100g")
  ) +
  # 6. 坐标轴设置
  scale_x_continuous(
    name = "time (min)",
    breaks = seq(0, max(long_data$time, na.rm = TRUE), by = 30),
    expand = expansion(mult = c(0.05, 0.05))
  ) +
  scale_y_continuous(
    name = expression(C["DO,t"]~(mg/L)),
    breaks = seq(0, max(long_data$C, na.rm = TRUE) + 0.5, by = 1),
    expand = expansion(mult = c(0.05, 0.05))
  ) +


  # 9. 主题设置（增强可读性）
  theme_bw(base_size = 20) +
  theme(
    # 修改图例位置到图形内部右上角
    legend.position = c(0.95, 0.95),
    legend.justification = c(1, 1),
    legend.background = element_rect(fill = "white", color = "black", size = 0.3),
    legend.key = element_rect(fill = "white"),
    legend.title = element_text(size = 14),
    legend.text = element_text(size = 12),
    plot.title = element_text(hjust = 0.5, size = 18),
    plot.subtitle = element_text(hjust = 0.5, size = 14, color = "black"),
    # axis.title = element_text(face = "bold"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    plot.margin = margin(15, 15, 15, 15),
    # 移除面板边框
    panel.border = element_blank(),
    # panel.border = element_rect(color = "black", fill = NA),
    # axis.text = element_text(color = "black")
    # 移除顶部和右侧的轴线
    axis.line.x = element_line(color = "black", size = 0.5),
    axis.line.y = element_line(color = "black", size = 0.5),
    axis.line.x.top = element_blank(),
    axis.line.y.right = element_blank(),
    axis.text = element_text(color = "black"),
    # 设置所有文本元素的字体
    text = element_text(family = "Times New Roman")
  )
# 合并图例（颜色、填充和线型使用相同的图例）
guides(
  color = guide_legend(override.aes = list(
    shape = c(21, 21, 21, 21),  # 设置图例中点的形状
    fill = c('#afc978','#a9dcf2','#edc0c0','#ddaaf7'),  # 设置图例中点的填充色
    color = c("#1a2b15", "#1a2b5c", "#c53a2e", "#4a0068"),  # 设置图例中点边框颜色
    linetype = treat_linetypes  # 设置图例中线型
  )),
  fill = "none",  # 隐藏填充图例
  linetype = "none"  # 隐藏线型图例
)
# 保存高质量图片
ggsave("溶解氧动力学曲线3.png", width = 8, height = 6, dpi = 600)
