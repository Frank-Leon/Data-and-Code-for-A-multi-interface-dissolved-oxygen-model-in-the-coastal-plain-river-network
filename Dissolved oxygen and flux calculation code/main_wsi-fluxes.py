import pandas as pd
import atmospheric_reoxygenation as ar
import sediment_consumption as sc
from figure_fluxes import plot_connected_scatterplot, plot_five_connected_scatterplot


# 计算所有工况的2号点的SWI界面通量
sw_fluxes = []
# 从水动力结果.xlsx文件调取所有工况的1号点水力要素序列
for i in range(1, 7):
    # 一共六个工况
    df = pd.read_excel("水动力结果导出.xlsx", sheet_name=f'工况{i}')
    # 1点位溶解氧变化计算
    depths = df.iloc[1:62, 3].tolist()  # 获取第4列的数据
    vels = df.iloc[1:62, 4].tolist()
    do_values = ar.cal_do_values(depths, vels)
    # 沉积物水界面通量计算
    sw_flux = sc.cal_sediment_water_flux(depths, vels, do_values, k=0.01033, c_ods=0.122, css=0.5)
    # plot_connected_scatterplot(sw_flux)
    sw_fluxes.append(sw_flux)


plot_five_connected_scatterplot(sw_fluxes[:5], labels=None)

# 将工况1-5的1号点通量计算结果写入Excel表格、
data = {
    "S1": sw_fluxes[0],
    "S2": sw_fluxes[1],
    "S3": sw_fluxes[2],
    "S4": sw_fluxes[3],
    "S5": sw_fluxes[4],
}

df = pd.DataFrame(data)
df.to_excel('output_fluxes.xlsx', sheet_name='1号点')  # index=False避免写入索引列