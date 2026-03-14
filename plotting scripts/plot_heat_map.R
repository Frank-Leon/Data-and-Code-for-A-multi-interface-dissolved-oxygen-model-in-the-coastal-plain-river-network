## 设置工作路径
setwd("E:/_things/1组会/金汇港/R")

# 加载必要的包
library(readxl)
library(ggplot2)
library(tidyr)
library(scales)
library(dplyr)


# 从Excel文件读取数据
df <- read_excel("swi_fluxes - 副本.xlsx", sheet = "SWI") %>%
  # 重命名列以确保一致性
  rename(time = `time`, condition = `condition`, flux = `flux`)

# 创建条件因子顺序（按照CS1-S1到CS1-S5，然后CS2-S1到CS2-S5，最后CS3-S1到CS3-S5的顺序）
condition_levels <- c(
  "CS1-S1", "CS1-S2", "CS1-S3", "CS1-S4", "CS1-S5",
  "CS2-S1", "CS2-S2", "CS2-S3", "CS2-S4", "CS2-S5",
  "CS3-S1", "CS3-S2", "CS3-S3", "CS3-S4", "CS3-S5"
)

# 转换列为正确的数据类型和顺序
df <- df %>%
  mutate(
    condition = factor(condition, levels = condition_levels),
    time = factor(time, levels = seq(0, 220, by = 20))
  )

# 定义自定义非线性转换函数
custom_trans <- function() {
  trans_new(
    name = "custom",
    # 转换函数：对低值区域压缩，高值区域扩展
    transform = function(x) {
      ifelse(x < 1, 
             x * 0.4,       # 压缩0-1区间的数据（占30%的色带范围）
             0.4 + (x-1)/max(x) * 0.6)  # 扩展1以上的数据（占70%的色带范围）
    },
    # 逆转换函数
    inverse = function(y) {
      ifelse(y < 0.3, 
             y / 0.3, 
             1 + (y-0.3)/0.7 * max(df$flux))
    }
  )
}

# 创建热力图
p <- ggplot(df, aes(x = condition, y = time, fill = flux)) +
  geom_tile(color = "black", linewidth = 0.3) +  # 添加白色边框
  scale_fill_gradientn(
    colors = c("#7294D4","#3B9AB2","#E6A0C4" ),  # 指定的三种颜色
    # trans = custom_trans(),  # 应用自定义非线性转换
    values = scales::rescale(c(min(df$flux), 1.6, max(df$flux))),
    # limits = c(floor(min(df$flux)), ceiling(max(df$flux))),  # 设置色带范围
    breaks = c(0, 0.5, 1, 5, 10, 12),  # 在关键点设置刻度
    labels = function(x) {
      ifelse(x < 1, 
             sprintf("%.1f", x),  # 低值区域显示1位小数
             as.character(round(x)))  # 高值区域显示整数
    },
    # 可选：设置图例刻度
    guide = guide_colourbar(
      barwidth = unit(0.5, "cm"),   # 水平色带长度
      barheight = unit(10, "cm") ,# 水平色带高度
      title.position = "top"
    )
  ) +
  labs(
    title = "Flux Values by Time and Condition",
    x = "Experimental Condition",
    y = "Time (min)",
    fill = "Flux"
  ) +
  theme_minimal(base_size = 20) +
  theme(
    # --- 核心修改部分 ---
    text = element_text(family = "serif"), # 设置全局字体为Times New Roman风格
    axis.text.x = element_text(color="black" ,angle = 45, hjust = 1, vjust = 1),  # 倾斜X轴标签
    axis.text.y = element_text(color="black"),
    # panel.grid = element_blank(),  # 移除网格线
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),  # 标题居中加粗
    legend.position = "right",  # 图例放在右侧
    # panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.5)  # 添加边框
  ) +
  coord_fixed()  # 保持格子为正方形

ggsave(
  filename = "heatmap-0314.png", # 文件名
  plot = p,                 # 图形对象（默认最后一个）
  width = 10,               # 宽度（单位由units决定）
  height = 6,               # 高度
  units = "in",             # 单位：英寸、厘米(cm)、毫米(mm)
  dpi = 600,                # 分辨率（点/英寸）
  bg = "white"              # 背景颜色
)

# 显示图形
print(p)