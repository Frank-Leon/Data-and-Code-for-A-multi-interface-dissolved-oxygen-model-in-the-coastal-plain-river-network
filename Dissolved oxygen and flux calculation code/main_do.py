import pandas as pd
import atmospheric_reoxygenation as ar
import sediment_consumption as sc
from export_to_excel import write_sheet

K_value = [0.00425, 0.00150, 0.00972]
C_ods = [0.07278, 0.04233, 0.11442]
CSS = [1.20000, 0.85000, 0.50000]
column_num = [3, 8, 13]

source_file = "水动力结果导出.xlsx"
target_file = "溶解氧及通量结果导出(含hs).xlsx"

# 导出指定工况的三个点位的溶解氧数据
with pd.ExcelWriter(target_file, mode="w") as writer:

    # 外层循环：遍历 1 到 6，代表工况1到工况6
    for scenario in range(1, 7):
        current_sheet_name = f"工况{scenario}"
        print(f"正在处理: {current_sheet_name} ...")

        # 每次进入新工况时，重置 outcomes 列表
        outcomes = []

        # 每个工况只读取一次当前 sheet 的数据
        try:
            df = pd.read_excel(source_file, sheet_name=current_sheet_name)
        except ValueError:
            print(f"警告：找不到 '{current_sheet_name}'，请检查源文件。")
            continue

        for i in range(len(column_num)):
            # 从水动力结果.xlsx文件调取工况的1号点水力要素序列
            depths = df.iloc[1:62, column_num[i]].tolist()  # 获取第4列的数据
            vels = df.iloc[1:62, column_num[i]+1].tolist()

            # 1点位溶解氧变化及通量计算
            re_do = ar.get_re_do_values(depths, vels)
            sc_do = sc.get_soc_do_values(vels, k=K_value[i], c_ods=C_ods[i], css=CSS[i])
            do_values = ar.cal_do_values(depths, vels, k=K_value[i], c_ods=C_ods[i], css=CSS[i])
            aw_fluxes = ar.cal_atmosphere_water_flux(depths, vels, do_values)
            sw_fluxes = sc.cal_sediment_water_flux(depths, vels, do_values, k=K_value[i], c_ods=C_ods[i], css=CSS[i])
            hs = sc.cal_hs(depths, vels, css=CSS[i])

            do_outcome = {
                "大气复氧项": re_do,
                "底泥耗氧项": sc_do,
                "最终DO浓度": do_values,
                "AWI通量": aw_fluxes,
                "hs": hs,
                "SWI通量": sw_fluxes,
             }
            outcomes.append(do_outcome)
        write_sheet(writer, outcomes, node_indexs = [1, 2, 3], sheet_name = current_sheet_name)

print("所有工况数据导出完毕！")

