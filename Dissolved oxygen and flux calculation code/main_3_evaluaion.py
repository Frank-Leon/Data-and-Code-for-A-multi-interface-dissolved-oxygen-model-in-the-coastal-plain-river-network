import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# 配置中文字体，防止图表中的中文显示为乱码
plt.rcParams['font.sans-serif'] = ['SimHei', 'WenQuanYi Micro Hei', 'Microsoft YaHei']
plt.rcParams['axes.unicode_minus'] = False

# 明确两个本地 Excel 文件名
obs_file = '1-溶解氧实测数据.xlsx'  # 实测数据
sim_file = '最终DO浓度提取结果.xlsx'  # 你刚才提取出的模拟数据

print(f"正在读取文件，请稍候...")
try:
    # header=1 表示将Excel里的第2行作为列名（跳过第1行的标题 CSX-SX）
    obs_data_dict = pd.read_excel(obs_file, sheet_name=None, header=1)
    sim_data_dict = pd.read_excel(sim_file, sheet_name=None, header=1)
except FileNotFoundError as e:
    print(
        f"\n【严重错误】找不到 Excel 文件，请确认这两个文件是否和代码在同一个文件夹下！\n具体报错：{e}")
    exit()

results = []

# 遍历实测数据中的所有 Sheet
for sheet_name, obs_df in obs_data_dict.items():
    print(f"正在处理匹配: {sheet_name} ...", end="")

    # 检查模拟结果中是否有对应的同名 Sheet
    if sheet_name not in sim_data_dict:
        print("未在模拟结果中找到对应工况，跳过。")
        continue

    sim_df = sim_data_dict[sheet_name]

    # 提取第2列(索引为1)的溶解氧数值，并去除可能的空值
    try:
        obs_do = obs_df.iloc[:, 1].dropna().values
        sim_do = sim_df['溶解氧'].dropna().values
    except KeyError:
        print(" 数据列格式不匹配，跳过。")
        continue

    # 对齐数据长度 (防止实测和模拟时间点数量不一致)
    min_len = min(len(obs_do), len(sim_do))
    if min_len == 0:
        print(" 数据为空，跳过。")
        continue

    o = obs_do[:min_len]
    s = sim_do[:min_len]

    # --- 计算四大指标 ---
    rmse = np.sqrt(np.mean((s - o) ** 2))  # 均方根误差
    mean_o = np.mean(o)
    nse = 1 - (np.sum((s - o) ** 2) / np.sum((o - mean_o) ** 2))  # 纳什系数
    r = np.corrcoef(o, s)[0, 1]  # 相关系数
    re = np.mean(np.abs((s - o) / o)) * 100  # 平均相对误差(%)

    results.append({
        '工况点位': sheet_name,
        'RMSE': rmse,
        'NSE': nse,
        'R': r,
        'RE(%)': re
    })
    print(" 计算完成。")

# 转换为 DataFrame
res_df = pd.DataFrame(results)

# 增加数据保护拦截，防止空表报错
if res_df.empty:
    print("\n【处理失败】未成功匹配到任何有效数据，请检查两个Excel文件的Sheet名称是否一致！")
    exit()

# 计算平均值
avgs = res_df.mean(numeric_only=True)

# ====== 绘制四联图 ======
print("\n数据处理成功，正在生成图表...")
fig, axes = plt.subplots(4, 1, figsize=(10, 12), sharex=True)
metrics = ['RMSE', 'NSE', 'R', 'RE(%)']
colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728']
x = np.arange(len(res_df['工况点位']))

for i, metric in enumerate(metrics):
    axes[i].bar(x, res_df[metric], color=colors[i], alpha=0.7, width=0.5)
    axes[i].set_ylabel(metric, fontsize=12)
    axes[i].grid(axis='y', linestyle='--', alpha=0.7)

    # 标出平均值参考线
    avg_val = avgs[metric]
    axes[i].axhline(y=avg_val, color='gray', linestyle='-.', label=f'平均值: {avg_val:.3f}')
    axes[i].legend(loc='upper right')

axes[-1].set_xticks(x)
axes[-1].set_xticklabels(res_df['工况点位'], rotation=45, ha='right', fontsize=11)
axes[-1].set_xlabel('实测工况与点位', fontsize=12)

plt.suptitle('溶解氧模拟结果与实测数据拟合优度评价', fontsize=16)
plt.tight_layout()
plt.subplots_adjust(top=0.94)

# 保存图片和表格
plt.savefig('拟合评价结果.png', dpi=300)
res_df.loc['平均值'] = avgs
res_df.at['平均值', '工况点位'] = '平均值'
res_df.to_excel('最终拟合评价指标结果.xlsx', index=False)

print("\n 所有分析已完成！请在当前目录下查看 '拟合评价结果.png' 和 '最终拟合评价指标结果.xlsx'。")