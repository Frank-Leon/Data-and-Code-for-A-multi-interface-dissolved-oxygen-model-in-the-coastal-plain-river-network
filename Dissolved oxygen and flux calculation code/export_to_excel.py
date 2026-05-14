import pandas as pd

def write_sheet(writer, outcomes, node_indexs, sheet_name):
    """
    把多个断面结果横着拼到一个 sheet，断面间留 1 列空列，并手动写表头。
    """
    # 1. 统一转成 DataFrame
    dfs = [pd.DataFrame(df) for df in outcomes]

    # 检查数据长度是否匹配
    if len(dfs) != len(node_indexs):
        print(f"警告：数据量({len(dfs)})与编号数量({len(node_indexs)})不一致！")

    # 2. 每个断面前面插 1 列空列（除了第一个，用于视觉分隔）
    # 注意：这里会改变 dfs 列表里的 dataframe 结构
    processed_dfs = []
    for i, df in enumerate(dfs):
        temp_df = df.copy()
        if i > 0:
            temp_df.insert(0, f'sep_{i}', '')  # 插入空列
        processed_dfs.append(temp_df)

    # 3. 横向拼接
    final_df = pd.concat(processed_dfs, axis=1)

    # 4. 写数据（从第 2 行开始，不带默认列名）
    # index=False 不打印索引，header=False 不打印字典的 Key 作为表头
    final_df.to_excel(writer, sheet_name=sheet_name, startrow=1, header=True, index=True)

    # 5. 写大表头（点位名称）
    worksheet = writer.sheets[sheet_name]

    # 获取 Excel 处理库的 openpyxl 对象进行操作
    current_col = 2  # 从第 2 列开始写（对应 Excel 的 B 列）

    for i, idx in enumerate(node_indexs):
        # 在第一行写入 "X号点"
        worksheet.cell(row=1, column=current_col, value=f"{idx}号点位")

        # 计算下一个点位的起始位置：
        # 当前列 + 当前 DataFrame 的总列数
        current_col += len(processed_dfs[i].columns)
