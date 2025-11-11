`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2025 11:06:09 PM
// Design Name: 
// Module Name: top_riscv
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


module top_riscv(
 input  wire        i_clk,
    input  wire        i_reset,     // active-high (khớp regfile/mem của bạn)

    // debug
    output wire [31:0] o_pc_debug,
    output wire        o_insn_vld,

    // IO pins
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
    // ================= PC & IMEM =================
    reg  [31:0] pc;
    wire [31:0] pc_plus4 = pc + 32'd4;
    assign o_pc_debug = pc;

    // 2 KiB IMEM: 512 x 32-bit (pc[11:2])
    reg  [31:0] imem [0:511];
    wire [31:0] instr = imem[pc[11:2]];

    initial begin
        // Cập nhật đường dẫn theo môi trường mô phỏng của bạn
        $readmemh("mem.dump", imem);
    end

    // ================= ImmGen =================
    wire [31:0] imm;
    ImmGen u_imm (.instr(instr), .imm_out(imm));

    // ================= Decode fields =================
    wire [4:0] rs1 = instr[19:15];
    wire [4:0] rs2 = instr[24:20];
    wire [4:0] rd  = instr[11:7];

    // ================= Regfile =================
    wire [31:0] rs1_data, rs2_data, rd_data;
    wire        rd_wren;
    regfile u_regfile (
        .i_clk(i_clk), .i_reset(i_reset),
        .i_rs1_addr(rs1), .i_rs2_addr(rs2),
        .o_rs1_data(rs1_data), .o_rs2_data(rs2_data),
        .i_rd_addr(rd), .i_rd_data(rd_data), .i_rd_wren(rd_wren)
    );

    // ================= ControlUnit =================
    wire [1:0] pc_sel;
    wire       mem_wren;
    wire [1:0] wb_sel;
    wire       opa_sel, opb_sel;
    wire [3:0] alu_op;
    wire       br_un, insn_vld_int;
    wire [1:0] mem_size;       // 00=B, 01=H, 10=W
    wire       mem_unsigned;   // 1=LBU/LHU

    assign o_insn_vld = insn_vld_int;

    wire br_less, br_equal;

    ControlUnit u_ctl (
        .instr(instr),
        .br_less(br_less),
        .br_equal(br_equal),

        .pc_sel(pc_sel),
        .rd_wren(rd_wren),
        .mem_wren(mem_wren),
        .wb_sel(wb_sel),
        .opa_sel(opa_sel),
        .opb_sel(opb_sel),
        .alu_op(alu_op),
        .br_un(br_un),
        .o_insn_vld(insn_vld_int),

        .mem_size(mem_size),
        .mem_unsigned(mem_unsigned)
    );

    // ================= Operand muxes =================
    wire [31:0] op_a = (opa_sel) ? pc  : rs1_data;
    wire [31:0] op_b_pre = (opb_sel) ? imm : rs2_data;

    // RV32I: shamt 5 bit
    wire is_shift = (alu_op==4'd7) | (alu_op==4'd8) | (alu_op==4'd9); // SLL/SRL/SRA
    wire [31:0] op_b = is_shift ? {27'd0, op_b_pre[4:0]} : op_b_pre;

    // ================= ALU =================
    wire [31:0] alu_y;
    alu u_alu (
        .i_op_a(op_a),
        .i_op_b(op_b),
        .i_alu_op(alu_op),
        .o_alu_data(alu_y)
    );

    // ================= BRC =================
    brc u_brc (
        .i_rs1_data(rs1_data),
        .i_rs2_data(rs2_data),
        .i_br_un(br_un),
        .o_br_less(br_less),
        .o_br_equal(br_equal)
    );

    // ================= LSU (bản của BẠN, đã nâng cấp) =================
    wire [31:0] lsu_ld_data;
    wire [31:0] ledr_w, ledg_w, lcd_w;
    wire [55:0] hex_bus;

    lsu u_lsu (
        .i_clk(i_clk),
        .i_reset(i_reset),

        .i_lsu_addr(alu_y),
        .i_st_data(rs2_data),
        .i_lsu_wren(mem_wren),
        .i_mem_size(mem_size),           // << thêm
        .i_mem_unsigned(mem_unsigned),   // << thêm

        .o_ld_data(lsu_ld_data),

        .o_io_ledr(ledr_w),
        .o_io_ledg(ledg_w),
        .o_io_hex(hex_bus),
        .o_io_lcd(lcd_w),
        .i_io_sw(i_io_sw)
    );

    // Map 56-bit HEX bus -> 8x7-seg
    assign o_io_hex0 = hex_bus[ 6: 0];
    assign o_io_hex1 = hex_bus[13: 7];
    assign o_io_hex2 = hex_bus[20:14];
    assign o_io_hex3 = hex_bus[27:21];
    assign o_io_hex4 = hex_bus[34:28];
    assign o_io_hex5 = hex_bus[41:35];
    assign o_io_hex6 = hex_bus[48:42];
    assign o_io_hex7 = hex_bus[55:49];

    // LED/LCD ra chân
    assign o_io_ledr = ledr_w;
    assign o_io_ledg = ledg_w;
    assign o_io_lcd  = lcd_w;

    // ================= Write-back mux =================
    // wb_sel: 00=ALU, 01=Load(LSU), 10=PC+4
    assign rd_data =
        (wb_sel==2'b01) ? lsu_ld_data :
        (wb_sel==2'b10) ? pc_plus4    :
                          alu_y;

    // ================= Next PC =================
    // pc_sel: 00 pc+4, 01 branch target (ALU=pc+immB), 10 jump target (ALU)
    // JALR: mask bit0
    wire [31:0] pc_target = alu_y & 32'hFFFF_FFFE;
    wire [31:0] pc_next =
        (pc_sel==2'b01) ? alu_y      :
        (pc_sel==2'b10) ? pc_target  :
                          pc_plus4;

    // ================= PC reg =================
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) pc <= 32'h0000_0000;
        else         pc <= pc_next;
    end
endmodule
