`include "ConstantDefine.v"

module ALU(
	val1_i, val2_i,
	aluop_i,
	result_o
);
// I/O Port Declaration ///////////////////////////////////////////////////////
	input     [ 31:0]val1_i;
	input     [ 31:0]val2_i;
	input     [  3:0]aluop_i;
	    
	output reg[ 31:0]result_o;

// Behavior Declaration ///////////////////////////////////////////////////////

	always@(*)begin
		case(aluop_i)
			`ALUOP_ADD		:begin result_o = val1_i + val2_i; end // Additions
			`ALUOP_SUB		:begin result_o = val1_i - val2_i; end // Subtraction

			`ALUOP_SLL		:begin result_o = val1_i << val2_i; end // Logic Left Shift(Put 0)
			`ALUOP_SRL		:begin result_o = val1_i >> val2_i; end // Logic Right Shift(Put 0)
			`ALUOP_SRA		:begin result_o = val1_i >>> val2_i; end // Arithmetic Right Shift(Put the leftest bits)

			`ALUOP_SLT		:begin result_o = (val1_i+32'h8000_0000) < (val2_i+32'h8000_0000); end // Set Less Than for signed int ((rs1<rs2)? 1:0)
			`ALUOP_SLTU		:begin result_o = val1_i < val2_i; end // Set Less Than for unsigned int ((rs1<rs2)? 1:0)
			`ALUOP_SGE		:begin result_o = (val1_i+32'h8000_0000) > (val2_i+32'h8000_0000); end // Set Less Than for signed int ((rs1<rs2)? 1:0)
			`ALUOP_SGEU		:begin result_o = val1_i > val2_i; end // Set Less Than for unsigned int ((rs1<rs2)? 1:0)
			`ALUOP_EQU		:begin result_o = val1_i == val2_i; end // Set Less Than for signed int ((rs1<rs2)? 1:0)
			`ALUOP_NEQ 		:begin result_o = val1_i != val2_i; end // Set Less Than for unsigned int ((rs1<rs2)? 1:0)

			`ALUOP_AND		:begin result_o = val1_i & val2_i; end // Bit wise AND
			`ALUOP_OR		:begin result_o = val1_i | val2_i; end // Bit wise OR
			`ALUOP_XOR		:begin result_o = val1_i ^ val2_i; end // Bit wise XOR
			default			:begin result_o = 32'h0000_0000; end
		endcase
	end
endmodule
