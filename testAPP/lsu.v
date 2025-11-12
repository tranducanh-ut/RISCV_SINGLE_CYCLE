`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2025 09:29:35 PM
// Design Name: 
// Module Name: lsu
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


module lsu(
 input  wire        i_clk,
    input  wire        i_reset,

    input  wire [31:0] i_lsu_addr, 
    input  wire [31:0] i_st_data,
    input  wire        i_lsu_wren,   // 1 = store, 0 = load

    output reg  [31:0] o_ld_data,

    output reg [31:0] o_io_ledr,
    output reg [31:0] o_io_ledg,
    output reg [6:0]  o_io_hex0,
    output reg [6:0]  o_io_hex1,
    output reg [6:0]  o_io_hex2,
    output reg [6:0]  o_io_hex3,
    output reg [6:0]  o_io_hex4,
    output reg [6:0]  o_io_hex5,
    output reg [6:0]  o_io_hex6,
    output reg [6:0]  o_io_hex7,
    output reg [31:0] o_io_lcd,

    input  wire [31:0] i_io_sw
);

    
    localparam BASE_MEM  = 32'h00000000, TOP_MEM  = 32'h00000FFF;
    localparam BASE_LEDR = 32'h10000000, TOP_LEDR = 32'h100007FF;
    localparam BASE_LEDG = 32'h10001000, TOP_LEDG = 32'h10001FFF;
    localparam BASE_HEX0 = 32'h10002000;
    localparam BASE_HEX4 = 32'h10003000;
    localparam BASE_LCD  = 32'h10004000;
    localparam BASE_SW   = 32'h10010000;

    // 2KB Data RAM (word address)
    reg [31:0] dmem [0:511]; // 2KB / 4

    integer i;
    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_io_ledr <= 32'd0;
            o_io_ledg <= 32'd0;
            o_io_hex0 <= 7'd0; o_io_hex1 <= 7'd0; o_io_hex2 <= 7'd0; o_io_hex3 <= 7'd0;
            o_io_hex4 <= 7'd0; o_io_hex5 <= 7'd0; o_io_hex6 <= 7'd0; o_io_hex7 <= 7'd0;
            o_io_lcd  <= 32'd0;
            for (i=0;i<512;i=i+1) dmem[i] <= 32'd0;
        end
        else if (i_lsu_wren) begin
            // RED LEDs
            if (i_lsu_addr >= BASE_LEDR && i_lsu_addr <= TOP_LEDR)
                o_io_ledr <= i_st_data;

            // GREEN LEDs
            else if (i_lsu_addr >= BASE_LEDG && i_lsu_addr <= TOP_LEDG)
                o_io_ledg <= i_st_data;

            // HEX0..3
            else if (i_lsu_addr == BASE_HEX0) begin
                o_io_hex0 <= i_st_data[6:0];
                o_io_hex1 <= i_st_data[14:8];
                o_io_hex2 <= i_st_data[22:16];
                o_io_hex3 <= i_st_data[30:24];
            end

            // HEX4..7
            else if (i_lsu_addr == BASE_HEX4) begin
                o_io_hex4 <= i_st_data[6:0];
                o_io_hex5 <= i_st_data[14:8];
                o_io_hex6 <= i_st_data[22:16];
                o_io_hex7 <= i_st_data[30:24];
            end

            // LCD
            else if (i_lsu_addr >= BASE_LCD && i_lsu_addr <= BASE_LCD + 32'hFFF)
                o_io_lcd <= i_st_data;

            // DMEM store (word only, aligned)
            else if (i_lsu_addr >= BASE_MEM && i_lsu_addr <= TOP_MEM)
                dmem[i_lsu_addr[12:2]] <= i_st_data;
        end
    end

    // LOAD
    always @(*) begin
        if (i_lsu_addr >= BASE_MEM && i_lsu_addr <= TOP_MEM)
            o_ld_data = dmem[i_lsu_addr[12:2]];
        else if (i_lsu_addr >= BASE_SW && i_lsu_addr <= BASE_SW + 32'hFFF)
            o_ld_data = i_io_sw;
        else
            o_ld_data = 32'h00000000;
    end
endmodule
