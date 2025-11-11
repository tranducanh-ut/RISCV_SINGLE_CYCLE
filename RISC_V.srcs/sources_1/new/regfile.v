`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2025 07:29:29 AM
// Design Name: 
// Module Name: regfile
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


module regfile(
input wire i_clk,
input wire i_reset,
input wire [4:0] i_rs1_addr,
input wire [4:0] i_rs2_addr,
output wire [31:0]o_rs1_data,
output wire [31:0]o_rs2_data,
input wire [4:0] i_rd_addr,
input wire [31:0] i_rd_data ,
input wire i_rd_wren

  
    );
    integer i;
      reg [31:0] regs [0:31];
      always @(posedge i_clk or negedge  i_reset) begin
      if(!i_reset) begin
      for (i=0;i<32;i=i+1) begin
      regs[i]<=32'b0;
      end
      end
      else if(i_rd_wren && i_rd_addr != 5'b0) begin
       regs[i_rd_addr] <= i_rd_data;
      end
      end
     
    assign o_rs1_data = (i_rs1_addr == 5'b0) ? 32'b0 : regs[i_rs1_addr];
    assign o_rs2_data = (i_rs2_addr == 5'b0) ? 32'b0 : regs[i_rs2_addr];
    
endmodule
