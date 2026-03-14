## 设置工作路径
setwd("D:/.学校/研究生/组会/溶解氧论文")
library(ggplot2)

# S1
data <- data.frame(
  mass = c(25, 50, 75, 100),  # 替换为实际数据
  tod = c(1.41751, 4.90252, 5.31078, 7.34631)
)

# 如果未安装sciRcolor，用其他颜色替代
# 例如：point_colors <- "blue", line_colors <- "red"
# 定义颜色变量（可根据需要修改）
point_border <- "black"    # 散点边框颜色
point_fill <- "#1337ba"    # 散点填充颜色
line_color <- "red"    # 趋势线颜色

p <- ggplot(data, aes(x=mass, y=tod)) + 
  geom_smooth(method="lm", color=line_color, fill="#edc0c0", size=1.5, level = 0.9) +
  geom_point(shape=21, color=point_border, fill=point_fill, size=5) +  # 分别设置边框和填充色
  scale_x_continuous(
    breaks = c(25, 50, 75, 100),  # 设置x轴刻度
    limits = c(20, 100),  # 设置x轴范围从0开始
    expand = expansion(mult = c(0, 0.05))  # 调整扩展量
  ) +
  scale_y_continuous(breaks=seq(0,12.5,2), limits=c(0,12.5), 
                     expand=expansion(mult=c(0,0.05))) +
  labs(
    x = "mass of suspended sediments (g)",  
    y = "total oxygen demand (mg)"   
  ) +
  theme_classic(base_size = 32) +
  theme(
    # panel.border = element_rect(color = "black", fill = NA),
    # axis.line = element_line(size = 0.5)
    axis.text = element_text(color = "black"),
    text = element_text(family = "Times New Roman")
  )

print(p)

# 保存图形（可选）
ggsave("scatter-smooth1-0314.png", p, width = 8, height = 6, dpi = 600)
