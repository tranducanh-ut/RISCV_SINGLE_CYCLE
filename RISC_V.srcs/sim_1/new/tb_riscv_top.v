`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 01:08:37 PM
// Design Name: 
// Module Name: tb_riscv_top
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


module tb_riscv_top;
      // =================== SIGNALS ===================
    reg clk;
    reg reset;
    reg [31:0] sw;

    wire [31:0] pc_debug;
    wire insn_vld;
    wire [31:0] led_r;
    wire [31:0] led_g;

    // các cổng hex/lcd bỏ qua cho test
    wire [6:0] hex0, hex1, hex2, hex3, hex4, hex5, hex6, hex7;
    wire [31:0] lcd;

    // Instantiate DUT
    riscv_top DUT (
        .i_clk(clk),
        .i_reset(reset),
        .i_io_sw(sw),
        .o_pc_debug(pc_debug),
        .o_insn_vld(insn_vld),
        .o_io_ledr(led_r),
        .o_io_ledg(led_g),
        .o_io_hex0(hex0), .o_io_hex1(hex1), .o_io_hex2(hex2), .o_io_hex3(hex3),
        .o_io_hex4(hex4), .o_io_hex5(hex5), .o_io_hex6(hex6), .o_io_hex7(hex7),
        .o_io_lcd(lcd)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // Test sequence
    initial begin
        // Initialize
        reset = 1;
        sw = 32'h00000000;
        #10;
        reset = 0; // release reset
        #10;
        reset = 1; // active
        #10;

        // Mô phỏng STORE: giả lập lệnh STORE tại địa chỉ BASE_LEDR
        // Cách nhanh: trực tiếp set ALU output và mem_wren = 1 bằng một lệnh giả
        // Bạn có thể load file hex chứa lệnh STORE vào mem để chạy tự nhiên
        $display("START TEST");

        // Chạy vài chu kỳ để DUT fetch và thực hiện lệnh
        repeat (20) @(posedge clk);

        // Quan sát LEDR
        $display("LED_R = %h", led_r);
        $display("PC_DEBUG = %h", pc_debug);

        $stop;
    end

    
 
endmodule
