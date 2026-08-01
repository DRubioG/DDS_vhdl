nvc -a ../src/DDS_trig.vhd

nvc -a tb_DDS_trig.vhd

nvc -e tb_DDS_trig

nvc -r tb_DDS_trig --stop-time=100us --wave=tb_DDS_trig.vcd