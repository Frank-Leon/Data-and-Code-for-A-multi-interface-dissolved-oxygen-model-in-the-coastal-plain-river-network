import pandas as pd

# def write_sheet(writer, outcomes_1, outcomes_2, outcomes_3, sheet_name,):
#     """将同一工况三个点位的结果写入同一sheet中"""
#     df1 = pd.DataFrame(outcomes_1)
#     df2 = pd.DataFrame(outcomes_2)
#     df3 = pd.DataFrame(outcomes_3)
#
#     # 在每个 DataFrame 之间插入空列
#     df2.insert(0, '', '')  # 在 df2 前插入空列
#     df3.insert(0, '', '')  # 在 df3 前插入空列
#
#     # 水平拼接三个 DataFrame
#     final_df = pd.concat([df1, df2, df3], axis=1)
#
#     # 写入 Excel 文件（不包含标题行）
#     final_df.to_excel(writer, sheet_name=sheet_name, startrow=1)
#
#     # 获取工作表对象
#     worksheet = writer.sheets[sheet_name]
#
#     # 添加标题行
#     worksheet.cell(row=1, column=2, value="1号点")
#     worksheet.cell(row=1, column=8, value="2号点")
#     worksheet.cell(row=1, column=14, value="3号点")


def write_sheet(writer, outcomes, node_indexs, sheet_name):
    """
    把多个断面结果横着拼到一个 sheet，断面间留 1 列空列，并手动写表头。
    sections    : list[DataFrame]          与 node_indexs 一一对应
    node_indexs : list[int]                断面编号，仅用于生成表头文字
    sheet_name  : str
    """
    # 1. 统一转成 DataFrame（如果本来就是可忽略）
    dfs = [pd.DataFrame(df) for df in outcomes]

    # 2. 每个断面前面插 1 列空列（除了第一个）
    for df in dfs[1:]:
        df.insert(0, '', '')

    # 3. 横向拼接
    final_df = pd.concat(dfs, axis=1)

    # 4. 写数据（从第 2 行开始，不带默认表头）
    final_df.to_excel(writer, sheet_name=sheet_name, startrow=1, header=False, index=False)

    # 5. 写表头
    worksheet = writer.sheets[sheet_name]
    col = 2                                 # 从 B 列开始
    for idx in node_indexs:
        worksheet.cell(row=1, column=col, value=f"{idx}号点")
        col += len(dfs[node_indexs.index(idx)].columns)   # 跳到下一个断面起始列