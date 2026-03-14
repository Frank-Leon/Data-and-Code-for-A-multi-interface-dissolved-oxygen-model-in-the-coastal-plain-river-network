"""大气复氧项"""
import math
import sediment_consumption as sc
Cs = 9.135      # 20℃下的饱和DO值


def cal_re_do(vel, depth, c0, time_step):
    """计算一个时间步后的复氧值并返回"""
    k2 = 63.2 * (vel ** 1.79)/(depth ** 0.84)
    # k2单位换算为min-1, time_step单位为min
    k2_unit = k2 / (24*60)
    c1 = Cs - (Cs - c0) * math.exp(-k2_unit * time_step)
    return c1


depths = [3.28, 3.28, 3.27, 3.26, 3.27, 3.28, 3.3]
vels = [0, 0, 0.02, 0.04, 0.04, 0.07, 0.1]


def get_re_do_values(depths, vels, c0=6.5, time_step=5):
    """输入水深、流速序列。返回对应时间步复氧后的DO值序列"""
    ci = [c0]
    for i in range(1, len(vels)):
        c1 = cal_re_do(vels[i], depths[i], ci[i-1], time_step)
        ci.append(c1)
    return ci


def get_re_do_increments(re_do_values, c0=6.5):
    """输入DO值序列，返回每个时间步相较于初始值的复氧增量"""
    do_increments = []
    for i in range(len(re_do_values)):
        increment = re_do_values[i] - c0
        do_increments.append(increment)
    return do_increments


def cal_atmosphere_water_flux(depths_input, vels_input, do_values):
    """"输入水力要素及最终DO浓度值序列，返回其通量,换算单位后为g/(m2·day)"""
    aw_fluxes = []
    for i in range(len(depths_input)):
        k2 = 63.2 * (vels_input[i] ** 1.79) / (depths_input[i] ** 0.84)    # 单位为day-1
        value = k2 * (Cs - do_values[i]) * depths_input[i]  # g/(m2·day)
        aw_fluxes.append(value)
    return aw_fluxes


# re_do_values = get_re_do_values(depths, vels)
# re_do_increments = get_re_do_increments(re_do_values)
# print(re_do_values)
# print(re_do_increments)

# 最终DO浓度变化计算
def cal_do_values(depths_input, vels_input, k=0.01033, c_ods=0.122, css=0.5, c0=6.5):
    """输入大气复氧、底泥耗氧变化量序列，返回最终该点的DO变化情况"""
    # 大气复氧项
    re_do_values = get_re_do_values(depths_input, vels_input)
    re_do_increments = get_re_do_increments(re_do_values)

    # 底泥耗氧项
    soc_do_values = sc.get_soc_do_values(vels_input, k, c_ods, css)
    soc_increments = sc.get_soc_increments(soc_do_values)

    values = []
    for i in range(len(re_do_increments)):
        value = c0 + re_do_increments[i] - soc_increments[i]
        values.append(value)
    return values