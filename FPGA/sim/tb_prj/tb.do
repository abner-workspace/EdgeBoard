# -----------------------------------------------------------------------------------
#
#  open modelsim
#  input example: cd C:/chengyang/workspace/EdgeBoard/FPGA/sim/tb_prj
#                 cd D:/workspace/space/EdgeBoard/FPGA/sim/tb_prj
#  input example: do ./tb.do
#
# -----------------------------------------------------------------------------------
# set MODELSIMTOOL        {C:/chengyang/tools/ModelSim/win64}
set MODELSIMTOOL        {D:/Tool/modelsim/win64}
set COMPILE_IP          {../../fw/par/ip}
set COMPILE_SRC         {../../fw/src}
set COMPILE_TB          {../tb_src}
set SIM_TOP_NAME        {tb}

# ---------------------------------------------------------------------
# Setup SimProject File
# ---------------------------------------------------------------------

$MODELSIMTOOL\\vlib modelsim_lib
$MODELSIMTOOL\\vlib modelsim_lib/work
$MODELSIMTOOL\\vlib modelsim_lib/msim
$MODELSIMTOOL\\vmap modelsim_lib modelsim_lib/msim

# ################################################
# notes

# Usage: vlog [options] files

# -incr  Enable incremental compilation
#   +incdir+<dir>      Search directory for files included with
#                      `include "filename"
# -y <path> Specify Verilog source library directory
# -source :   Print the source line with error messages
# -v <path>          Specify Verilog source library file
#   -vopt              Run the "vopt" compiler before simulation
#   +libext+<suffix>   Specify suffix of files in library directory
#   +libext+<suffix>   Specify suffix of files in library directory
#   -93                Preserve the case of Verilog module (and parameter
#                      and port) names in the equivalent VHDL entity by using
#                      VHDL-1993 extended identifiers; this may be useful
#                      in mixed-language designs
# ################################################



# ---------------------------------------------------------------------
# Compile IP Format
# ---------------------------------------------------------------------

$MODELSIMTOOL\\vlog -64 -93 -incr -work modelsim_lib \
"$COMPILE_IP/ip_scaler_dsp_v/*_netlist.v" \
"$COMPILE_IP/ip_scaler_dsp_h/*_netlist.v" \
"$COMPILE_IP/ip_scaler_vout/*_netlist.v" \
"$COMPILE_IP/ip_vout_fifo/*_netlist.v" \

# ---------------------------------------------------------------------
# Compile SRC Format
# "$COMPILE_SRC/audio/*.v" \
# ---------------------------------------------------------------------

$MODELSIMTOOL\\vlog -64 -93 -incr -work modelsim_lib \
+define+SIM \
+incdir+"$COMPILE_SRC/common.v" \
"$COMPILE_SRC/pattern/*.v" \
"$COMPILE_SRC/scaler/*.v" \
"$COMPILE_SRC/scaler/core/*.v" \
"$COMPILE_SRC/scaler/core/scaler_dsp/*.v" \
"$COMPILE_SRC/scaler/core/scaler_stream/*.v" \
"$COMPILE_SRC/scaler/ctrl/*.v" \
"$COMPILE_SRC/scaler/matrix/*.v" \
"$COMPILE_SRC/scaler/vin/*.v" \
"$COMPILE_SRC/scaler/vout/*.v" \
"$COMPILE_SRC/*.v" \



# ---------------------------------------------------------------------
# Compile TB Format
# ---------------------------------------------------------------------

$MODELSIMTOOL\\vlog -64 -93 -incr -work modelsim_lib \
+define+SIM \
+incdir+"$COMPILE_SRC/common.v" \
"$COMPILE_TB/tb.v" \


#compile glbl module

$MODELSIMTOOL\\vlog -64 -93 -incr -work modelsim_lib "glbl.v"

# Related libraries
vsim -voptargs="+acc" \
    -L modelsim_lib \
    -L xilinx_vip \
    -L unisims_ver \
    -L unimacro_ver \
    -L secureip \
    -L xpm \
    -lib modelsim_lib modelsim_lib.$SIM_TOP_NAME modelsim_lib.glbl

################################################################################
#
#   view -new wave
#
################################################################################
# do {wave.do}

# log all signals
log -r /*

# run time
run 10us
