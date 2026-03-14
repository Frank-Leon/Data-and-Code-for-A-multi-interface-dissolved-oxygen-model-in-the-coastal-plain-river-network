## 设置工作路径
setwd("D:/.学校/研究生/组会/溶解氧论文")

library(tidyverse)
library(readxl)
library(scales)
library(ggsignif)
library(ggExtra)
library(grid)
library(cowplot)

# 注册Times New Roman字体
windowsFonts(TNR = windowsFont("Times New Roman"))

# 读取Excel数据并转换条件值 (S1->保持, S3->S2, S5->S3)
df <- read_excel("hs_flux.xlsx", sheet = "CS3") %>%
  mutate(condition = case_when(
    condition == "S1" ~ "S1",
    condition == "S3" ~ "S3",
    condition == "S5" ~ "S5",
    TRUE ~ condition
  )) %>%
  rename(type = condition)

# 计算线性回归模型
lm_model <- lm(flux ~ hs, data = df)

# 提取方程参数
intercept <- coef(lm_model)[1]
slope <- coef(lm_model)[2]
r_squared <- summary(lm_model)$r.squared

# 打印方程信息
cat(sprintf("线性回归方程: y = %.4fx + %.4f\n", slope, intercept))
cat(sprintf("R² = %.4f\n", r_squared))

# 修改图例标签 (添加样本数量统计)
type_counts <- as.data.frame(table(df$type))
names(type_counts) <- c("type", "count")
type_counts <- type_counts[order(factor(type_counts$type, levels = c("S1", "S3", "S5"))), ]
new_legend <- paste(type_counts$type, paste0("(n=", type_counts$count, ")"), sep = " ")

# 主散点图
p1 <- ggplot(df, aes(x = hs, y = flux, 
                     color = factor(type, levels = c("S1", "S3", "S5")))) +
  geom_point(size = 3, alpha = 0.6) +
  guides(color = guide_legend(override.aes = list(alpha = 1, size = 5))) +
  geom_smooth(method = "lm", color = "red", linetype = "dashed") +
  scale_color_manual(values = c("#1F77B4","#E6A0C4","#3F3F3F"),
                     labels = new_legend) +
  labs(x = "hs", y = "flux") +
  
  theme_classic(base_size = 30, base_family = "TNR") + 
  theme(
    text = element_text(family = "TNR"),
    panel.grid.major = element_line(linetype = "dashed"),
    axis.title = element_text(size = 24, family = "TNR"), 
    axis.text = element_text(color = "black", size = 20, family = "TNR"), 
    legend.title = element_blank(),
    legend.margin = margin(3, 15, 2, 5),
    legend.text = element_text(size = 16, family = "TNR"), 
    legend.key.spacing.y = unit(0.05, 'cm'),
    legend.position = c(0.1, 0.9), 
    legend.justification = c(0, 1),
    legend.background = element_rect(fill = 'white', colour = '#D6D6D6',
                                     linewidth = 1)
  )

# 添加边缘直方图
p2 <- ggMarginal(p1,
                 type = "histogram",  
                 groupColour = TRUE,   
                 groupFill = TRUE,    
                 alpha = 1,         
                 xparams = list(
                   bins = 30,
                   position = "identity",  
                   alpha = 0.6,            
                   colour = NA             
                 ),
                 yparams = list(
                   bins = 30,
                   position = "identity",
                   alpha = 0.6,
                   colour = NA
                 )
)

# 计算残差
fit <- lm(log(flux) ~ log(hs), data = df)
df$flux_fit <- exp(predict(fit))
df$residuals_log <- log(df$flux) - log(df$flux_fit)

# 创建残差箱线图
my_comparisons <- list(c("S1","S3"), c("S3","S5"), c("S1","S5"))

p3 <- ggplot(df, aes(x = factor(type, levels = c("S5", "S3", "S1")),
                     y = residuals_log,
                     fill = type)) +
  # 将 size 替换为 linewidth 避免新版 ggplot2 的警告
  stat_boxplot(geom = "errorbar", width = 0.2, linewidth = 0.6, color = "#3F3F3F") +
  geom_boxplot(outlier.size = 1, alpha = 0.6, linewidth = 0.4) +
  geom_signif(comparisons = my_comparisons,
              test = "wilcox.test",
              map_signif_level = c("***"=0.001, "**"=0.01, "*"=0.05),
              textsize = 6, 
              size = 0.5,   
              color = "#3F3F3F",
              step_increase = 0.08,
              vjust = 0.08,
              family = "TNR") + # 确保显著性星号/文本也使用 TNR
  scale_fill_manual(values = c("S1" = "#1F77B4", "S3" = "#E6A0C4", "S5" = "#3F3F3F")) +
  labs(x = NULL, y = NULL, title = "Residuals (log)") +
  scale_y_continuous(
    breaks = scales::pretty_breaks(n = 3),  
    labels = scales::number_format(accuracy = 0.01) ,
    # 2. 向上(视觉上的右侧)扩展 30% 的留白，防止顶部的显著性线条被边框挤压
    expand = expansion(mult = c(0.05, 0.1))
  ) +
  theme_bw(base_size = 16, base_family = "TNR") + 
  theme(
    text = element_text(family = "TNR"),
    panel.grid = element_blank(),
    panel.border = element_rect(color = "#B3B3B3", linewidth = 1.5),
    # 取消加粗
    plot.title = element_text(hjust = 0.5, size = 16, family = "TNR"), 
    axis.title.x = element_blank(),
    # 显式指定坐标轴文本(分类组名标签)字体
    axis.text.x = element_text(size = 14, angle = 0, vjust = 0.5, family = "TNR"),  
    axis.ticks.y = element_blank(),
    axis.text.y = element_blank(),
    legend.position = 'none',
    plot.margin = margin()
  ) +
  coord_flip()

# 组合图形并添加标题
final_plot <- ggdraw() +
  draw_plot(p2, x = 0, y = 0, width = 1, height = 1) +
  draw_plot(p3, x = 0.48, y = 0.14, width = 0.36, height = 0.3)

print(final_plot)

ggsave(filename = "hs_flux_plot_cs3.png",
       plot = final_plot,
       device = "png",
       width = 7,        
       height = 7,        
       dpi = 600,         
       bg = "white")      

message("Plot successfully exported to: ", normalizePath(output_file))