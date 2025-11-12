file delete -force xsim.dir .Xil
puts ">> xvlog ..."
exec xvlog --incr --relax  ../riscv_top.v  ../regfile.v  ../mem.v  ../alu.v  ../brc.v  ../controller.v  ../ImmGen.v  ../lsu.v  ../tb_regtrace.v
puts ">> xelab ..."
exec xelab tb_regtrace -s tb_regtrace_sim
puts ">> xsim -R ..."
exec xsim tb_regtrace_sim -R --testplusarg LOGFILE=regtrace.txt
puts "Simulation DONE."
