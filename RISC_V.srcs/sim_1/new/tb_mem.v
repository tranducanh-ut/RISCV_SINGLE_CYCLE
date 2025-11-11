`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 01:56:03 PM
// Design Name: 
// Module Name: tb_mem
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


module tb_mem;




    reg         clk;
    reg         reset;
    reg [31:0]  addr;
    reg [31:0]  wdata;
    reg [3:0]   bmask;
    reg         wren;
    wire [31:0] rdata;

    // Instantiate memory
    mem uut (
        .i_clk(clk),
        .i_reset(reset),
        .i_addr(addr),
        .i_wdata(wdata),
        .i_bmask(bmask),
        .i_wren(wren),
        .o_rdata(rdata)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Initialize
        reset = 1;
        addr  = 0;
        wdata = 32'd0;
        bmask = 4'b1111;
        wren  = 0;
        #20;
        reset = 0;
        #10;

        // Write to address 0
        addr  = 32'd0;      // word-aligned
        wdata = 32'h12345678;
        wren  = 1;
        #10;
        wren = 0;

        // Write to address 4 (next word)
        addr  = 32'd4;
        wdata = 32'hDEADBEEF;
        wren  = 1;
        #10;
        wren = 0;

        // Read back address 0
        addr = 32'd0;
        #10;
        $display("Read data at addr 0 = %h", rdata);

        // Read back address 4
        addr = 32'd4;
        #10;
        $display("Read data at addr 4 = %h", rdata);

        // Read back address 8 (empty)
        addr = 32'd8;
        #10;
        $display("Read data at addr 8 = %h", rdata);

        $stop;
    end
endmodule
