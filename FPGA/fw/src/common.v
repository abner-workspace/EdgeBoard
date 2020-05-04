`define VERSION         "v000"
`define PLATFORM        "RUN"

// VD FORMAT
`define VID_HD_720P50          0
`define VID_HD_720P59_94       1
`define VID_HD_720P60          2
`define VID_HD_1080I50         3
`define VID_HD_1080I59_94      4
`define VID_HD_1080I60         5
`define VID_HD_1080SFP23_98    6
`define VID_HD_1080SFP24       7
`define VID_HD_1080P23_98      8
`define VID_HD_1080P24         9
`define VID_HD_1080P25         10
`define VID_HD_1080P29_97      11
`define VID_HD_1080P30         12
`define VID_3G_1080P50         13
`define VID_3G_1080P59_94      14
`define VID_3G_1080P60         15
`define VID_6G_2160P23_98      16
`define VID_6G_2160P24         17
`define VID_6G_2160P25         18
`define VID_6G_2160P29_97      19
`define VID_6G_2160P30         20
`define VID_DL3G_2160P23_98    21
`define VID_DL3G_2160P24       22
`define VID_DL3G_2160P25       23
`define VID_DL3G_2160P29_97    24
`define VID_DL3G_2160P30       25
`define VID_SIM_I              8'hFD
`define VID_SIM_S              8'hFE
`define VID_SIM_M              8'hFF
// video size type
`define ARG_SIZE_3840x2160     0
`define ARG_SIZE_1920x1080     1
`define ARG_SIZE_1280x720      2
// video rate type
`define ARG_RATE_23_98FPS      0
`define ARG_RATE_24FPS         1
`define ARG_RATE_25FPS         2
`define ARG_RATE_29_97FPS      3
`define ARG_RATE_30FPS         4
`define ARG_RATE_50FPS         5
`define ARG_RATE_59_94FPS      6
`define ARG_RATE_60FPS         7
// video scan type
`define ARG_SCAN_P             0
`define ARG_SCAN_I             1
// video mode type
`define ARG_MODE_HD            0
`define ARG_MODE_3G            1
`define ARG_MODE_6G            2
`define ARG_MODE_12G           3
`define ARG_MODE_DL3G          4
`define ARG_MODE_DL6G          5
// video clk frequency
`define ARG_FREQ_74M25         0
`define ARG_FREQ_148M5         1
`define ARG_FREQ_297M          2
// video clk frequency frac / int
`define ARG_FRAC_DIS           0
`define ARG_FRAC_EN            1
// video clk frequency srouce sel internal/external
`define ARG_SRC_INTERNAL       0
`define ARG_SRC_EXTERNAL       1

