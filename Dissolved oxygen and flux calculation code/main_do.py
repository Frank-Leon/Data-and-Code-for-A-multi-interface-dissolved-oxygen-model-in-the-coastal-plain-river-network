import pandas as pd
import atmospheric_reoxygenation as ar
import sediment_consumption as sc
from export_to_excel import write_sheet

K_value = [0.00425, 0.00150, 0.00972]
C_ods = [0.07278, 0.04233, 0.11442]
CSS = [1.20000, 0.85000, 0.50000]
# column_num = list(range(3, 55, 5)) # 指定每个点位水深所在列
column_num = [3, 8, 13]
outcomes = []

# 导出指定工况的三个点位的溶解氧数据
with pd.ExcelWriter("溶解氧及通量结果导出20260514(含hs).xlsx", mode="w") as writer:
    "第一次mode=w，后面mode=a"
    for i in range(len(column_num)):
        # 从水动力结果.xlsx文件调取工况的1号点水力要素序列
        df = pd.read_excel("水动力结果导出.xlsx", sheet_name='工况1')
        depths = df.iloc[2:64, column_num[i]].tolist()  # 获取第4列的数据
        vels = df.iloc[2:64, column_num[i]+1].tolist()

        # 1点位溶解氧变化及通量计算
        re_do_1 = ar.get_re_do_values(depths, vels)
        sc_do_1 = sc.get_soc_do_values(vels, k=K_value[i], c_ods=C_ods[i], css=CSS[i])
        do_values_1 = ar.cal_do_values(depths, vels, k=K_value[i], c_ods=C_ods[i], css=CSS[i])
        aw_fluxes_1 = ar.cal_atmosphere_water_flux(depths, vels, do_values_1)
        sw_fluxes_1 = sc.cal_sediment_water_flux(depths, vels, do_values_1, k=K_value[i], c_ods=C_ods[i], css=CSS[i])
        hs_1 = sc.cal_hs(depths, vels, css=CSS[i])
        do_outcome_1 = {
            "大气复氧项": re_do_1,
            "底泥耗氧项": sc_do_1,
            "最终DO浓度": do_values_1,
            "AWI通量": aw_fluxes_1,
            "hs": hs_1,
            "SWI通量": sw_fluxes_1,
         }
        outcomes.append(do_outcome_1)
    write_sheet(writer, outcomes, node_indexs = [1, 2, 3], sheet_name = "工况1")
