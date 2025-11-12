`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2025 07:10:27 AM
// Design Name: 
// Module Name: brc
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


module brc(
input wire [31:0] i_rs1_data,
input wire [31:0] i_rs2_data,
input wire        i_br_un,
output reg        o_br_less=1'b0,
output reg        o_br_equal =1'b0      
    );
    always @(*) begin
    o_br_equal=(i_rs1_data == i_rs2_data);
     if (i_br_un) begin
          
    o_br_less = ($signed(i_rs1_data) < $signed(i_rs2_data));
        end else begin
            
      o_br_less = (i_rs1_data < i_rs2_data);
        end
    end
endmodule
