`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 12:31:56 PM
// Design Name: 
// Module Name: riscv_top
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


module riscv_top(
 input  wire        i_clk,
    input  wire        i_reset,

    output wire [31:0] o_pc_debug,
    output wire        o_insn_vld,

    output wire [31:0] o_io_ledr,
    output wire [31:0] o_io_ledg,
    output wire [6:0]  o_io_hex0,
    output wire [6:0]  o_io_hex1,
    output wire [6:0]  o_io_hex2,
    output wire [6:0]  o_io_hex3,
    output wire [6:0]  o_io_hex4,
    output wire [6:0]  o_io_hex5,
    output wire [6:0]  o_io_hex6,
    output wire [6:0]  o_io_hex7,
    output wire [31:0] o_io_lcd,

    input  wire [31:0] i_io_sw
);

    

 
    //=================== PC REGISTER ===================
    reg [31:0] pc=32'd0;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4 = pc + 4;
 assign pc_next = (pc_sel) ? alu_out : pc_plus4;
    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset)
            pc <= 32'h00000000;
       
        else
            pc <= pc_next;
    end

    assign o_pc_debug = pc;


    //=================== INSTRUCTION MEMORY ===================
    wire [31:0] instr;

    mem inst_mem (
        .i_clk   (i_clk),
        .i_reset (i_reset),
        .i_addr  (pc),   // 32bit
        .i_wdata (32'b0),
        .i_bmask (4'b0000),
        .i_wren  (1'b0),
        .o_rdata (instr)
    );

    assign o_insn_vld = 1'b1; 


    //=================== IMMEDIATE GENERATOR ===================
    wire [31:0] imm;
    ImmGen immgen (
        .instr  (instr),
        .imm_out   (imm)
    );


    //=================== REGFILE ===================
    wire [31:0] rs1_data, rs2_data, wb_data;
    wire        rd_wren;
    wire [4:0]  rs1 = instr[19:15];
    wire [4:0]  rs2 = instr[24:20];
    wire [4:0]  rd  = instr[11:7];

    regfile rf (
        .i_clk     (i_clk),
        .i_reset   (i_reset),
        .i_rs1_addr(rs1),
        .i_rs2_addr(rs2),
        .o_rs1_data(rs1_data),
        .o_rs2_data(rs2_data),
        .i_rd_addr (rd),
        .i_rd_data (wb_data),
        .i_rd_wren (rd_wren)
    );


    //=================== BRANCH COMPARE ===================
    wire br_un, br_less, br_equal;

    brc cmp (
        .i_rs1_data(rs1_data),
        .i_rs2_data(rs2_data),
        .i_br_un   (br_un),
        .o_br_less (br_less),
        .o_br_equal(br_equal)
    );


    //=================== CONTROL UNIT ===================
    wire pc_sel, opa_sel, opb_sel, mem_wren;
    wire [3:0] alu_op;
    wire [1:0] wb_sel;

    controller ctrl (
        .i_insn    (instr),
        .i_br_less (br_less),
        .i_br_equal(br_equal),

        .o_pc_sel  (pc_sel),
        .o_rd_wren (rd_wren),
        .o_br_un   (br_un),
        .o_opa_sel (opa_sel),
        .o_opb_sel (opb_sel),
        .o_alu_op  (alu_op),
        .o_mem_wren(mem_wren),
        .o_wb_sel  (wb_sel)
    );


    //=================== ALU ===================
    wire [31:0] op_a = (opa_sel) ? pc : rs1_data;
    wire [31:0] op_b = (opb_sel) ? imm : rs2_data;
    wire [31:0] alu_out;

    alu alu_u (
        .i_op_a   (op_a),
        .i_op_b   (op_b),
        .i_alu_op (alu_op),
        .o_alu_data(alu_out)
    );


    //=================== LSU (DATA + IO) ===================
    wire [31:0] ld_data;

    lsu lsu_u (
        .i_clk      (i_clk),
        .i_reset    (i_reset),
        .i_lsu_addr (alu_out),
        .i_st_data  (rs2_data),
        .i_lsu_wren (mem_wren),
        .o_ld_data  (ld_data),

        .o_io_ledr  (o_io_ledr),
        .o_io_ledg  (o_io_ledg),
        .o_io_hex0  (o_io_hex0), .o_io_hex1(o_io_hex1), .o_io_hex2(o_io_hex2), .o_io_hex3(o_io_hex3),
        .o_io_hex4  (o_io_hex4), .o_io_hex5(o_io_hex5), .o_io_hex6(o_io_hex6), .o_io_hex7(o_io_hex7),
        .o_io_lcd   (o_io_lcd),
        .i_io_sw    (i_io_sw)
    );


    //=================== WRITEBACK MUX ===================
    assign wb_data =
        (wb_sel == 2'b00) ? alu_out  :
        (wb_sel == 2'b01) ? ld_data  :
        (wb_sel == 2'b10) ? pc_plus4 :
                            imm;

    //=================== NEXT PC ===================
    always @(posedge i_clk) begin
  if (i_reset) begin
    $display("t=%0t PC=%08h INSTR=%08h pc_sel=%b alu_out=%08h",
              $time, pc, instr, pc_sel, alu_out);
  end
end
   
endmodule
