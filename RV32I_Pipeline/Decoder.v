`include "ConstantDefine.v"

module Decoder(
    instr_i,

    rs1_o, // rs1 address
    rs2_o, // rs2 address

    rd_o,  // rd address

    imm_o, // immediate value

    alu_s1_o, // select the source for ALU operation
    alu_s2_o, // select the source for ALU operation
    aluop_o,  // select alu operation
    alu_writeback_o, // is regisiter-regisiter or regisiter-immediate operation to rd

    pc_select_o, // select the next instruction address
    branch_o,    // is a branch instruction
    jump_o,      // is a JAL instruction
    jalr_o,      // is a JALR instruction

    mem_read_o,  // is a load instruction
    mem_write_o, // is a store instruction
    mem_type_o,  // memery access data type

    rs1_read_o,
    rs2_read_o,
    rd_select_o, // select the value
    rd_write_o  // write to regisiter
);
// I/O Port Declaration ///////////////////////////////////////////////////////
    input      [31:0]instr_i;

    output     [ 4:0]rs1_o;
    output     [ 4:0]rs2_o;
    output     [ 4:0]rd_o;

    output reg [31:0]imm_o;

    output reg [ 1:0]alu_s1_o;
    output reg [ 1:0]alu_s2_o;
    output reg [ 3:0]aluop_o;
    output           alu_writeback_o;

    output reg [ 1:0]pc_select_o;
    output           branch_o;
    output           jump_o;
    output           jalr_o;

    output           mem_read_o;
    output           mem_write_o;
    output reg [ 2:0]mem_type_o;
    
    output reg [ 1:0]rd_select_o;
    output           rd_write_o;
    output           rs1_read_o;
    output           rs2_read_o;

// Internal Signals ///////////////////////////////////////////////////////////
    wire    [ 6:0]opcode;
    wire    [ 2:0]funct3;

// Behavior Declaration ///////////////////////////////////////////////////////
    assign opcode = instr_i[ 6: 0];
    assign funct3 = instr_i[14:12];

    // regisiter address //////////////////////////////////////////////////
    assign rs1_o = instr_i[19:15];
    assign rs2_o = instr_i[24:20];
    assign rd_o = instr_i[11: 7];

    // branch & jump control //////////////////////////////////////////////
    always@(*)begin
		case(opcode)
            7'b1100011 : pc_select_o = `PC_SRCMUX_BRANCH;// branch
            7'b1100111 : pc_select_o = `PC_SRCMUX_ALU; // JAL
            7'b1101111 : pc_select_o = `PC_SRCMUX_PCIMM;   // JALR
            default    : pc_select_o = `PC_SRCMUX_PLUS4; // normal instruction
		endcase
	end
    assign branch_o = (opcode==7'b1100011)? 1'b1 : 1'b0;
    assign jump_o   = (opcode==7'b1101111)? 1'b1 : 1'b0;
    assign jalr_o   = (opcode==7'b1100111)? 1'b1 : 1'b0;


    // sign extension immediate value /////////////////////////////////////
	always@(*)begin
		case(opcode)
            // R-Type
			7'b0110011 : ;                       // imm_o = 32'hxxxx_xxxx_xxxx_xxxx; // do not care
            // I-Type
			7'b0000011, 7'b0010011, 7'b1100111 :    imm_o = {{20{instr_i[31]}}, {instr_i[31:20]}};
            // S-Type
            7'b0100011 :                            imm_o = {{20{instr_i[31]}}, {instr_i[31:25], instr_i[11:7]}};
            // B-Type
            7'b1100011 :                            imm_o = {{19{instr_i[31]}}, {instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0}};
            // U-Type
            7'b0010111, 7'b0110111 :                imm_o = {instr_i[31:12], 12'h000};
            // J-type
            7'b1101111 :                            imm_o = {{11{instr_i[31]}}, {instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21]}, 1'b0};

            default :                               imm_o = 32'h0000_0000;
        endcase
	end

    // ALU Opcode /////////////////////////////////////////////////////////
    assign alu_writeback_o = (opcode==7'b0110011) || // regisiter-regisiter
                             (opcode==7'b0010011); //regisiter-immediate
    always@(*)begin
		case(opcode)
            // regisiter-regisiter & regisiter-immediate operation
			7'b0110011, 7'b0010011 : begin
                case(funct3)
                    3'b000 : aluop_o = (opcode==7'b0110011)?     (instr_i[30])? `ALUOP_SUB : `ALUOP_ADD :
                                                                `ALUOP_ADD;
                    3'b001 : aluop_o = `ALUOP_SLL;
                    3'b010 : aluop_o = `ALUOP_SLT;
                    3'b011 : aluop_o = `ALUOP_SLTU;
                    3'b100 : aluop_o = `ALUOP_XOR;
                    3'b101 : aluop_o = (instr_i[30])? `ALUOP_SRA : `ALUOP_SRL;
                    3'b110 : aluop_o = `ALUOP_OR;
                    3'b111 : aluop_o = `ALUOP_AND;
                    default: aluop_o = `ALUOP_ADD;
                endcase
            end

            // load & store
            7'b0000011, 7'b0100011 : begin
                aluop_o = `ALUOP_ADD;
            end

            // branch
            7'b1100011 : begin
                case(funct3)
                    3'b000 : aluop_o = `ALUOP_EQU;  //BEQ
                    3'b001 : aluop_o = `ALUOP_NEQ;  //BNE
                    3'b100 : aluop_o = `ALUOP_SLT;  //BLT
                    3'b101 : aluop_o = `ALUOP_SLTU; //BGT
                    3'b110 : aluop_o = `ALUOP_SGE;  //BLTU
                    3'b111 : aluop_o = `ALUOP_SGEU; //BGTU
                    default: aluop_o = `ALUOP_ADD;
                endcase
            end

            // JALR(imm+rs1) & LUI(load upper immediate)(imm+0)
            7'b1100111, 7'b0110111 : begin
                aluop_o = `ALUOP_ADD;
            end

            default : begin
                aluop_o = `ALUOP_NONE;
            end
		endcase
	end

    // ALU source select //////////////////////////////////////////////////
    	always@(*)begin
		case(opcode)
            // regisiter-regisiter operations & branch
			7'b0110011, 7'b1100011 : begin
                alu_s1_o = `ALU_SRCMUX_RS1;
                alu_s2_o = `ALU_SRCMUX_RS2;
            end
            // regisiter-immediate operations & loaad & store & 
			7'b0010011, 7'b0000011, 7'b0100011 : begin
                alu_s1_o = `ALU_SRCMUX_RS1;
                alu_s2_o = `ALU_SRCMUX_IMM;
            end
            // JALR(imm+rs1)
            7'b1100111 : begin
                alu_s1_o = `ALU_SRCMUX_RS1;
                alu_s2_o = `ALU_SRCMUX_IMM;
            end
            // LUI(load upper immediate)(imm+0)
            7'b0110111 : begin
                alu_s1_o = `ALU_SRCMUX_IMM;
                alu_s2_o = `ALU_SRCMUX_ZERO;
            end
            default    : begin
                alu_s1_o = `ALU_SRCMUX_RS1;
                alu_s2_o = `ALU_SRCMUX_RS2;
            end
		endcase
	end

    // Reg control /////////////////////////////////////////////////////////
    assign rs1_read_o = (opcode==7'b0110011 || // regisiter-regisiter
                         opcode==7'b1100011 || // branch
                         opcode==7'b0100011 || // store
                         opcode==7'b0000011 || // load
                         opcode==7'b1100111 || // JALR
                         opcode==7'b0010011    // regisiter-immediate
                        ) ? 
                        1'b1 : 1'b0;
    assign rs2_read_o = (opcode==7'b0110011 || // regisiter-regisiter
                         opcode==7'b1100011 || // branch
                         opcode==7'b0100011 || // store
                         opcode==7'b0000011    // load
                        ) ? 
                        1'b1 : 1'b0;
    assign rd_write_o = (opcode==7'b0110011 || // regisiter-regisiter operations
                         opcode==7'b0010011 || // regisiter-immediate operation
                         opcode==7'b0000011 || // load
                         opcode==7'b0110111 || // LUI(load upper immediate)
                         opcode==7'b1101111 || // JAL
                         opcode==7'b1100111 || // JALR
                         opcode==7'b0010111    // AUIPC
                        ) ? 
                        1'b1 : 1'b0;
    // Rd source select
    always@(*)begin
		case(opcode)
            // regisiter-regisiter operations & regisiter-immediate operations, LUI(load upper immediate)
			7'b0110011, 7'b0010011, 7'b0110111 :    rd_select_o = `RD_SRCMUX_ALU;
            // load
			7'b0000011 :                            rd_select_o = `RD_SRCMUX_MEM;
            // JAL & JALR
            7'b1101111, 7'b1100111 :                rd_select_o = `RD_SRCMUX_PCPLUS4;
            // AUIPC
            7'b0010111 :                            rd_select_o = `RD_SRCMUX_PCIMM;
            //
            default :                               rd_select_o = `RD_SRCMUX_PCPLUS4;
		endcase
	end

    // Memory control /////////////////////////////////////////////////////
    assign mem_read_o  = (opcode==7'b0000011)? 1'b1 : 1'b0; // load instruction
    assign mem_write_o = (opcode==7'b0100011)? 1'b1 : 1'b0; // store instruction
    always@(*)begin
		case(funct3)
            3'b000  : mem_type_o = `MEM_TYPE_INT8;   // LB, SB
            3'b001  : mem_type_o = `MEM_TYPE_INT16;  // LH, SH
            3'b010  : mem_type_o = `MEM_TYPE_INT32;  // LW, SW
            3'b100  : mem_type_o = `MEM_TYPE_UINT16; // LHU
            3'b101  : mem_type_o = `MEM_TYPE_UINT8;  // LBU
            default : mem_type_o = `MEM_TYPE_INT32;  // 
		endcase
	end


    
endmodule