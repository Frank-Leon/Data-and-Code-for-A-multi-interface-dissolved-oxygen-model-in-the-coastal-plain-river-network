import pandas as pd
import atmospheric_reoxygenation as ar

# 计算所有工况的1号点的AW界面通量
aw_fluxes = []
# 从水动力结果.xlsx文件调取所有工况的1号点水力要素序列
for i in range(1, 7):
    # 一共六个工况
    df = pd.read_excel("水动力结果导出.xlsx", sheet_name=f'工况{i}')
    # 1点位溶解氧变化计算
    depths = df.iloc[1:62, 3].tolist()  # 获取第4列的数据
    vels = df.iloc[1:62, 4].tolist()
    do_values = ar.cal_do_values(depths, vels)
    # 沉积物水界面通量计算
    aw_flux = ar.cal_atmosphere_water_flux(depths, vels, do_values)
    # plot_connected_scatterplot(sw_flux)
    aw_fluxes.append(aw_flux)


# plot_five_connected_scatterplot(aw_fluxes[:5], labels=None)

# 将工况1-5的1号点通量计算结果写入Excel表格、
data = {
    "S1": aw_fluxes[0],
    "S2": aw_fluxes[1],
    "S3": aw_fluxes[2],
    "S4": aw_fluxes[3],
    "S5": aw_fluxes[4],
}

df = pd.DataFrame(data)
df.to_excel('output_aw_fluxes.xlsx', sheet_name='1号点')  # index=False避免写入索引列