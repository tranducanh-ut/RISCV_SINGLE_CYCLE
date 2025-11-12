`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2025 06:21:48 AM
// Design Name: 
// Module Name: alu
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


module alu(
input wire [31:0] i_op_a,
input wire [31:0] i_op_b,
input wire [3:0]  i_alu_op,
output reg [31:0] o_alu_data
    );
    localparam ADD = 4'd0;
    localparam SUB = 4'd1;
    localparam SLT = 4'd2;
    localparam SLTU =4'd3;
    localparam XOR  =4'd4;
    localparam OR   =4'd5;
    localparam AND  =4'd6;
    localparam SLL  =4'd7;
    localparam SRL  =4'd8;
    localparam SRA  =4'd9;
    always @(*) begin
    case(i_alu_op)
    ADD: o_alu_data<=i_op_a + i_op_b;
    SUB: o_alu_data<=i_op_a - i_op_b;
    SLT: o_alu_data<=(i_op_a <i_op_b)?1:0;
    SLTU:o_alu_data<=(i_op_a <i_op_b)?1:0;
    XOR :o_alu_data<=i_op_a ^ i_op_b;
    OR : o_alu_data<=i_op_a | i_op_b;
    AND: o_alu_data<=i_op_a & i_op_b;
    SLL :o_alu_data<=i_op_a << i_op_b;
    SRL: o_alu_data<=i_op_a >> i_op_b;
    SRA: o_alu_data<=i_op_a >>> i_op_b;
    default: o_alu_data<=o_alu_data;     
    endcase 
    
    end
endmodule
