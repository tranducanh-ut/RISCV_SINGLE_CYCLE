`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2025 08:27:50 AM
// Design Name: 
// Module Name: mem
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


module mem(
    input  wire        i_clk,
    input  wire        i_reset,
    input  wire [31:0] i_addr,
    input  wire [31:0] i_wdata,
    input  wire [3:0]  i_bmask,
    input  wire        i_wren,
    output reg  [31:0] o_rdata
    );
    reg [31:0] mem [0:2047];
initial begin
        $readmemh("mem.h", mem);
    end
    integer i;

    
    always @(posedge i_clk or negedge  i_reset) begin
        if (!i_reset) begin
        
        end
        else if (i_wren) begin
            
            if (i_bmask[0]) mem[i_addr[31:2]][7:0]   <= i_wdata[7:0];
            if (i_bmask[1]) mem[i_addr[31:2]][15:8]  <= i_wdata[15:8];
            if (i_bmask[2]) mem[i_addr[31:2]][23:16] <= i_wdata[23:16];
            if (i_bmask[3]) mem[i_addr[31:2]][31:24] <= i_wdata[31:24];
        end
       end

  
    always @(*) begin
   o_rdata = mem[i_addr[31:2]];
    end

endmodule
