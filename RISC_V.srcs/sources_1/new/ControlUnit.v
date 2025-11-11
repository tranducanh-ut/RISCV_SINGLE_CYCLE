`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2025 10:59:28 PM
// Design Name: 
// Module Name: ControlUnit
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


module ControlUnit(
input  [31:0] instr,
    input    wire     br_less,
    input      wire   br_equal,

    output reg [1:0] pc_sel,      // 00: PC+4, 01: BR target, 10: JUMP target
    output reg       rd_wren,
    output reg       mem_wren,
    output reg [1:0] wb_sel,      // 00: ALU, 01: LD(mem), 10: PC+4
    output reg       opa_sel,     // 0: rs1, 1: pc
    output reg       opb_sel,     // 0: rs2, 1: imm
    output reg [3:0] alu_op,      
    output reg       br_un,       // 1: unsigned compare (BLTU/BGEU)
    output reg       o_insn_vld,  // 1 nếu opcode hợp lệ

    // cho LSU/adapter
    output reg [1:0] mem_size,    // 00=B, 01=H, 10=W
    output reg       mem_unsigned // 1: LBU/LHU
);
    // Trường mã
    wire [6:0] opc    = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    // Opcodes RV32I
    localparam [6:0] OPC_LUI   = 7'b0110111,
                     OPC_AUIPC = 7'b0010111,
                     OPC_JAL   = 7'b1101111,
                     OPC_JALR  = 7'b1100111,
                     OPC_BR    = 7'b1100011,
                     OPC_LOAD  = 7'b0000011,
                     OPC_STORE = 7'b0100011,
                     OPC_OPIMM = 7'b0010011,
                     OPC_OP    = 7'b0110011;

    // Mã ALU (khớp ALU của bạn)
    localparam [3:0] ADD=4'd0, SUB=4'd1, SLT=4'd2, SLTU=4'd3,
                     XOR=4'd4, OR =4'd5, AND =4'd6,
                     SLL=4'd7, SRL=4'd8, SRA =4'd9;

    always @* begin
        // defaults an toàn
        pc_sel       = 2'b00;   // PC+4
        rd_wren      = 1'b0;
        mem_wren     = 1'b0;
        wb_sel       = 2'b00;   // ALU
        opa_sel      = 1'b0;    // rs1
        opb_sel      = 1'b0;    // rs2
        alu_op       = ADD;
        br_un        = 1'b0;
        o_insn_vld   = 1'b1;
        mem_size     = 2'b10;   // W
        mem_unsigned = 1'b0;

        case (opc)
            
            OPC_LUI: begin
                // rd = immU 
                rd_wren = 1'b1;
                opa_sel = 1'b1;   
                opb_sel = 1'b1;   
                alu_op  = XOR;   
            end
            OPC_AUIPC: begin
                rd_wren = 1'b1; opa_sel=1'b1; opb_sel=1'b1; alu_op=ADD; // rd=PC+immU
            end

           
            OPC_JAL: begin
                rd_wren = 1'b1; wb_sel=2'b10; pc_sel=2'b10; // rd=PC+4, PC=PC+immJ
                opa_sel = 1'b1; opb_sel=1'b1; alu_op=ADD;
            end
            OPC_JALR: begin
                rd_wren = 1'b1; wb_sel=2'b10; pc_sel=2'b10; // rd=PC+4, PC=(rs1+immI)&~1 (mask ở PC)
                opa_sel = 1'b0; opb_sel=1'b1; alu_op=ADD;
            end

           
            OPC_BR: begin
               
                opa_sel = 1'b1; opb_sel=1'b1; alu_op=ADD;
                case (funct3)
                    3'b000: begin if (br_equal) pc_sel=2'b01; br_un=1'b0; end // BEQ
                    3'b001: begin if (!br_equal) pc_sel=2'b01; br_un=1'b0; end // BNE
                    3'b100: begin if (br_less) pc_sel=2'b01; br_un=1'b0; end // BLT
                    3'b101: begin if (!br_less || br_equal) pc_sel=2'b01; br_un=1'b0; end // BGE
                    3'b110: begin if (br_less) pc_sel=2'b01; br_un=1'b1; end // BLTU
                    3'b111: begin if (!br_less || br_equal) pc_sel=2'b01; br_un=1'b1; end // BGEU
                    default: o_insn_vld = 1'b0;
                endcase
            end

            
            OPC_LOAD: begin
                rd_wren  = 1'b1; wb_sel=2'b01;  // WB từ RAM/LSU
                opa_sel  = 1'b0; opb_sel=1'b1; alu_op=ADD; // addr=rs1+imm
                case (funct3)
                    3'b000: begin mem_size=2'b00; mem_unsigned=1'b0; end // LB
                    3'b001: begin mem_size=2'b01; mem_unsigned=1'b0; end // LH
                    3'b010: begin mem_size=2'b10; mem_unsigned=1'b0; end // LW
                    3'b100: begin mem_size=2'b00; mem_unsigned=1'b1; end // LBU
                    3'b101: begin mem_size=2'b01; mem_unsigned=1'b1; end // LHU
                    default: o_insn_vld=1'b0;
                endcase
            end

            // ----- Stores -----
            OPC_STORE: begin
                mem_wren = 1'b1;
                opa_sel  = 1'b0; opb_sel=1'b1; alu_op=ADD; // addr=rs1+immS
                case (funct3)
                    3'b000: mem_size=2'b00; // SB
                    3'b001: mem_size=2'b01; // SH
                    3'b010: mem_size=2'b10; // SW
                    default: begin mem_wren=1'b0; o_insn_vld=1'b0; end
                endcase
            end

            // I type
            OPC_OPIMM: begin
                rd_wren = 1'b1; opa_sel=1'b0; opb_sel=1'b1;
                case (funct3)
                    3'b000: alu_op=ADD; // ADDI
                    3'b010: alu_op=SLT; // SLTI
                    3'b011: alu_op=SLTU;// SLTIU
                    3'b100: alu_op=XOR; // XORI
                    3'b110: alu_op=OR ; // ORI
                    3'b111: alu_op=AND; // ANDI
                    3'b001: alu_op=SLL; // SLLI
                    3'b101: alu_op=(funct7[5] ? SRA : SRL); 
                    default: begin alu_op=ADD; o_insn_vld=1'b0; end
                endcase
            end

            // ----- R-type ALU -----
            OPC_OP: begin
                rd_wren = 1'b1; opa_sel=1'b0; opb_sel=1'b0;
                case (funct3)
                    3'b000: alu_op=(funct7[5] ? SUB : ADD); // SUB/ADD
                    3'b010: alu_op=SLT;   // SLT
                    3'b011: alu_op=SLTU;  // SLTU
                    3'b100: alu_op=XOR;   // XOR
                    3'b110: alu_op=OR;    // OR
                    3'b111: alu_op=AND;   // AND
                    3'b001: alu_op=SLL;   // SLL
                    3'b101: alu_op=(funct7[5] ? SRA : SRL); // SRA/SRL
                    default: begin alu_op=ADD; o_insn_vld=1'b0; end
                endcase
            end

            default: o_insn_vld = 1'b0;
        endcase
    end
endmodule
