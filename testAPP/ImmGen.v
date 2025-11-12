`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2025 10:44:11 PM
// Design Name: 
// Module Name: ImmGen
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


module ImmGen(
input wire  [31:0] instr,
    output reg [31:0] imm_out
);
    
    wire [6:0] opc = instr[6:0];

    
    localparam [6:0] OPC_LUI   = 7'b0110111;
    localparam [6:0] OPC_AUIPC = 7'b0010111;
    localparam [6:0] OPC_JAL   = 7'b1101111;
    localparam [6:0] OPC_JALR  = 7'b1100111;
    localparam [6:0] OPC_BR    = 7'b1100011; // BEQ/BNE/BLT/BGE/BLTU/BGEU
    localparam [6:0] OPC_LOAD  = 7'b0000011; // LB/LH/LW/LBU/LHU
    localparam [6:0] OPC_STORE = 7'b0100011; // SB/SH/SW
    localparam [6:0] OPC_OPIMM = 7'b0010011; // ADDI/SLTI/
    localparam [6:0] OPC_OP    = 7'b0110011; // R-type

    always @* begin
        case (opc)
            
            OPC_LOAD, OPC_OPIMM, OPC_JALR: begin
             imm_out = {{20{instr[31]}}, instr[31:20]};
            end
            
            OPC_STORE: begin
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
           // BRANCH (LSB = 0)
            OPC_BR: begin
                imm_out = {{19{instr[31]}},
                           instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            // U-type: LUI/AUIPC 
            OPC_LUI, OPC_AUIPC: begin
                imm_out = {instr[31:12], 12'b0};
            end
            // J-type: JAL 
            OPC_JAL: begin
                imm_out = {{11{instr[31]}},
                           instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            default: imm_out = 32'h00000000;
        endcase
    end
endmodule
