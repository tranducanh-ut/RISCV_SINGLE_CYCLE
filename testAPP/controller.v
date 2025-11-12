`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2025 12:25:12 PM
// Design Name: 
// Module Name: controller
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


module controller(
input  wire [31:0] i_insn,
    input  wire        i_br_less,
    input  wire        i_br_equal,

    output reg         o_pc_sel,
    output reg         o_rd_wren,
    output reg         o_br_un,
    output reg         o_opa_sel,
    output reg         o_opb_sel,
    output reg [3:0]   o_alu_op,
    output reg         o_mem_wren,
    output reg [1:0]   o_wb_sel
);

    // Extract fields
    wire [6:0] opcode = i_insn[6:0];
    wire [2:0] funct3 = i_insn[14:12];
    wire [6:0] funct7 = i_insn[31:25];

    // ALU operations encoding (match ALU module)
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_SLT = 4'b0010;
    localparam ALU_SLTU= 4'b0011;
    localparam ALU_XOR = 4'b0100;
    localparam ALU_OR  = 4'b0101;
    localparam ALU_AND = 4'b0110;
    localparam ALU_SLL = 4'b0111;
    localparam ALU_SRL = 4'b1000;
    localparam ALU_SRA = 4'b1001;

    // wb_sel:
    // 00 → ALU result
    // 01 → Load data (from LSU)
    // 10 → PC + 4
    // 11 → Imm (LUI)
    
    always @(*) begin
        // Default values
        o_pc_sel   = 0;
        o_rd_wren  = 0;
        o_br_un    = 0;
        o_opa_sel  = 0;
        o_opb_sel  = 0;
        o_alu_op   = ALU_ADD;
        o_mem_wren = 0;
        o_wb_sel   = 2'b00;

        case (opcode)

        //===================== R-TYPE =====================
        7'b0110011: begin
            o_rd_wren = 1;
            o_opa_sel = 0; // rs1
            o_opb_sel = 0; // rs2
            case ({funct7, funct3})
                10'b0000000000: o_alu_op = ALU_ADD;
                10'b0100000000: o_alu_op = ALU_SUB;
                10'b0000000010: o_alu_op = ALU_SLT;
                10'b0000000011: o_alu_op = ALU_SLTU;
                10'b0000000100: o_alu_op = ALU_XOR;
                10'b0000000110: o_alu_op = ALU_OR;
                10'b0000000111: o_alu_op = ALU_AND;
                10'b0000000001: o_alu_op = ALU_SLL;
                10'b0000000101: o_alu_op = ALU_SRL;
                10'b0100000101: o_alu_op = ALU_SRA;
            endcase
        end

        //===================== I-TYPE ALU ===================
        7'b0010011: begin
            o_rd_wren = 1;
            o_opa_sel = 0;
            o_opb_sel = 1; // immediate
            case (funct3)
                3'b000: o_alu_op = ALU_ADD;   // ADDI
                3'b010: o_alu_op = ALU_SLT;   // SLTI
                3'b011: o_alu_op = ALU_SLTU;  // SLTIU
                3'b100: o_alu_op = ALU_XOR;
                3'b110: o_alu_op = ALU_OR;
                3'b111: o_alu_op = ALU_AND;
                3'b001: o_alu_op = ALU_SLL;
                3'b101: o_alu_op = (funct7 == 7'b0100000) ? ALU_SRA : ALU_SRL;
            endcase
        end

        //===================== LOAD =======================
        7'b0000011: begin
            o_rd_wren  = 1;
            o_opa_sel  = 0;
            o_opb_sel  = 1;
            o_alu_op   = ALU_ADD;
            o_wb_sel   = 2'b01; // write-back from memory
        end

        //===================== STORE ======================
        7'b0100011: begin
            o_opa_sel  = 0;
            o_opb_sel  = 1;
            o_alu_op   = ALU_ADD;
            o_mem_wren = 1;
        end

        //===================== BRANCH =====================
        7'b1100011: begin
            o_opa_sel = 0;
            o_opb_sel = 0;
            case (funct3)
                3'b000: o_pc_sel = i_br_equal;      // BEQ
                3'b001: o_pc_sel = ~i_br_equal;     // BNE
                3'b100: begin o_br_un = 1; o_pc_sel = i_br_less; end  // BLT signed
                3'b101: begin o_br_un = 1; o_pc_sel = ~i_br_less; end // BGE signed
                3'b110: begin o_br_un = 0; o_pc_sel = i_br_less; end  // BLTU
                3'b111: begin o_br_un = 0; o_pc_sel = ~i_br_less; end // BGEU
            endcase
        end

        //===================== JAL =====================
        7'b1101111: begin
     o_rd_wren = 1;
    o_pc_sel  = 1;
    o_wb_sel  = 2'b10;   // rd <- PC+4
    o_opa_sel = 1;       // op_a = PC (SỬA: trước là 0)
    o_opb_sel = 1;       // op_b = imm
    o_alu_op  = ALU_ADD; // target = PC + imm
        end

        //===================== JALR ====================
        7'b1100111: begin
            o_rd_wren = 1;
    o_pc_sel  = 1;
    o_wb_sel  = 2'b10;   // rd <- PC+4
    o_opa_sel = 0;       // op_a = rs1   
    o_opb_sel = 1;       // op_b = imm   
    o_alu_op  = ALU_ADD; // target = rs1 + imm  
        end

        //===================== LUI =====================
        7'b0110111: begin
            o_rd_wren = 1;
            o_wb_sel  = 2'b11; // immediate to rd
        end

        //===================== AUIPC ==================
        7'b0010111: begin
            o_rd_wren = 1;
            o_opa_sel = 1; // use PC
            o_opb_sel = 1;
            o_alu_op  = ALU_ADD;
        end

        endcase
    end
endmodule
