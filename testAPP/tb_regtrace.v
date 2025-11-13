`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2025 09:11:28 PM
// Design Name: 
// Module Name: tb_regtrace
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_regtrace;
 
  // only0 print when meet diferences, 1: print all x0..x31 each state
  parameter FULL_SNAPSHOT = 0;
  //max cycle
  parameter MAX_CYCLES    = 200;

  // ===== Clock & Reset =====
  reg clk;
  reg rst;   
  // ===== I/O  =====
  reg  [9:0]  sw   = 10'h000;
  wire [9:0]  led_r;
  wire [7:0]  led_g;
  wire [6:0]  hex0,hex1,hex2,hex3,hex4,hex5,hex6,hex7;
  wire [7:0]  lcd;

  // ===== DUT =====
  riscv_top dut (
    .i_clk    (clk),
    .i_reset  (rst),
    .i_io_sw  (sw),
    .o_io_ledr(led_r),
    .o_io_ledg(led_g),
    .o_io_hex0(hex0), .o_io_hex1(hex1), .o_io_hex2(hex2), .o_io_hex3(hex3),
    .o_io_hex4(hex4), .o_io_hex5(hex5), .o_io_hex6(hex6), .o_io_hex7(hex7),
    .o_io_lcd (lcd)
  );

  // ===== Clock 10ns (100MHz) =====
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // ===== Reset sequence =====
  initial begin
    rst = 1'b0;                    
    repeat (3) @(posedge clk);
    rst = 1'b1;                    
  end

  // ===== Log file =====
  integer fd;

  initial begin
    fd = $fopen("../regtrace.txt", "w");
    if (fd == 0) begin
      $display("ERROR: cannot open reg_update_log.txt");
      $finish;
    end
    $fdisplay(fd, "              ##   ##  ######  ##   ##  ##   ##  #######");
    $fdisplay(fd, "              ##   ##  ##      ### ###  ##   ##    ##   ");
    $fdisplay(fd, "              #######  ##      #######  ##   ##    ##   ");
    $fdisplay(fd, "              ##   ##  ##      ## # ##  ##   ##    ##   ");
    $fdisplay(fd, "              ##   ##  ######  ##   ##   #####     ##   ");
    $fdisplay(fd, "");
    $fdisplay(fd, "github: tranducanh-ut");
    $fdisplay(fd, "                ==== RISC-V Register Update Trace ====");
    $fdisplay(fd, "");
    $fdisplay(fd, "            Time(ns) | PC         INSTR   | Updates");
    $fdisplay(fd, "---------------------------------------------------------------");
  end

  // ===== mem state =====
  reg [31:0] prev_regs [0:31];
  reg [31:0] prev_pc;
  reg [31:0] prev_instr;

  // ===== TEMP =====
  reg [31:0] cur_pc;
  reg [31:0] cur_instr;
  integer    any_change;
  integer    i;
  integer    cycle_cnt;

  initial begin
    for (i = 0; i < 32; i = i + 1) begin
      prev_regs[i] = 32'h0000_0000;
    end
    prev_pc     = 32'h0000_0000;
    prev_instr  = 32'h0000_0000;
    cycle_cnt   = 0;
  end

  // ===== Theo dõi thay đổi mỗi cạnh lên clock =====
  always @(posedge clk) begin
    if (rst) begin
      cur_pc    = dut.pc;
      cur_instr = dut.instr;

      if (FULL_SNAPSHOT == 0) begin
        // Only print diference
        any_change = 0;
        for (i = 0; i < 32; i = i + 1) begin
          if (dut.rf.regs[i] !== prev_regs[i]) begin
            if (!any_change) begin
              $fwrite(fd, "%8t | %08h  %08h | ", $time, cur_pc, cur_instr);
              any_change = 1;
            end
            $fwrite(fd, "x%0d:%08h->%08h ", i, prev_regs[i], dut.rf.regs[i]);
          end
        end
        if (any_change) begin
          $fwrite(fd, "\n");
        end else begin
          $fdisplay(fd, "%8t | %08h  %08h | (no reg change)", $time, cur_pc, cur_instr);
        end
      end else begin
        // In toàn bộ snapshot
        $fdisplay(fd, "%8t | %08h  %08h | FULL SNAPSHOT", $time, cur_pc, cur_instr);
        for (i = 0; i < 32; i = i + 1) begin
          $fdisplay(fd, "  x%0d = %08h", i, dut.rf.regs[i]);
        end
      end

      // Cập nhật prev_* cho chu kỳ sau
      for (i = 0; i < 32; i = i + 1) begin
        prev_regs[i] = dut.rf.regs[i];
      end
      prev_pc    = cur_pc;
      prev_instr = cur_instr;
    end

    // cycle counting
    cycle_cnt = cycle_cnt + 1;
    if (cycle_cnt >= MAX_CYCLES) begin
      $fdisplay(fd, "              ==========END==========");
      $fflush(fd);
      $fclose(fd);
      $finish;
    end
  end

endmodule
