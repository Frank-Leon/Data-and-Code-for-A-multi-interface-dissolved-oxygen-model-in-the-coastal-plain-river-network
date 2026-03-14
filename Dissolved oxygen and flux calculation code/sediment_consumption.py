"""底泥耗氧项"""
import math


def cal_soc_do(vel, k, c_ods, css, time_step, c0):
    """计算一个时间步后的底泥耗氧值并返回"""
    # w由速度决定= IFS(E4 < 0.2, 0.2 + E4, AND(E4 >= 0.2, E4 < 0.4), 0.2 + E4, E4 >= 0.4, E4 + 0.2)
    w = vel + 0.2
    exponent = - k * c_ods * css * w * time_step
    c1 = c0 * math.exp(exponent)
    return c1


def get_soc_do_values(vels, k, c_ods, css, time_step=5, c0=6.5):
    """输入流速序列以及底泥的相关数据，返回对应时间步耗氧后的DO值序列"""
    ci = [c0]
    for i in range(len(vels) - 1):
        c1 = cal_soc_do(vels[i], k, c_ods, css, time_step, c0)
        c0 = c1
        ci.append(c1)
    return ci


def get_soc_increments(do_values, c0=6.5):
    """输入DO值序列，返回每个时间步相较于初始值的底泥耗氧量"""
    do_increments = []
    for i in range(len(do_values)):
        increment = c0 - do_values[i]
        do_increments.append(increment)
    return do_increments


def cal_sediment_water_flux(depths_input, vels_input, do_values, k, c_ods, css):
    """"输入底泥耗氧项相关数值，返回其通量,换算单位后为g/(m2·day)"""
    sw_fluxes = []
    for i in range(len(depths_input)):
        w = vels_input[i] + 0.2
        value = k * do_values[i] * c_ods * css * depths_input[i] * w * 24 * 60
        sw_fluxes.append(value)
    return sw_fluxes


def cal_hs(depths_input, vels_input, css, Ds= 2.21E6):
    """计算对应水力要素下的悬浮沉积物等效堆积厚度，换算后单位cm，Ds为堆积密度，单位g/m3"""
    hs = []
    for i in range(len(depths_input)):
        w = vels_input[i] + 0.2
        value = css * depths_input[i] * w / Ds * (10 ** 5)
        hs.append(value)
    return hs


# vels = [0, 0, 0.02, 0.04, 0.04, 0.07,]
# soc_do_values = get_soc_do_values(vels, 0.01033,	0.122,0.5)
# soc_do_increments = get_soc_increments(soc_do_values)
#
# print(soc_do_values)
# print(soc_do_increments)
