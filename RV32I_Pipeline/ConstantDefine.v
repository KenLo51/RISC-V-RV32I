// Program counter ////////////////////////////////////////////////////////////
`define PC_SRCMUX_PLUS4  2'h0 // pc + 4
`define PC_SRCMUX_ALU    2'h1 // rs1 + imm
`define PC_SRCMUX_PCIMM  2'h2 // pc  + imm
`define PC_SRCMUX_BRANCH 2'h3 // wait for branch condition

// Regisiter //////////////////////////////////////////////////////////////////
`define RD_SRCMUX_ALU     3'h0
`define RD_SRCMUX_MEM     3'h1
`define RD_SRCMUX_PCIMM   3'h2
`define RD_SRCMUX_PCPLUS4 3'h3

// ALU ////////////////////////////////////////////////////////////////////////
`define ALUOP_NONE 4'h0

`define ALUOP_ADD  4'h1 // Additions
`define ALUOP_SUB  4'h2 // Subtraction

`define ALUOP_SLL  4'h3 // Logic Left Shift(Put 0)
`define ALUOP_SRL  4'h4 // Logic Right Shift(Put 0)
`define ALUOP_SRA  4'h5 // Arithmetic Right Shift(Put the leftest bits)

`define ALUOP_SLT  4'h6 // Set Less Than for signed int ((rs1<rs2)? 1:0)
`define ALUOP_SLTU 4'h7 // Set Less Than for unsigned int ((rs1<rs2)? 1:0)
`define ALUOP_SGE  4'h8 // Set Gteater Than or Euqal to for signed int ((rs1<rs2)? 1:0)
`define ALUOP_SGEU 4'h9 // Set Gteater Than or Euqal to for unsigned int ((rs1<rs2)? 1:0)
`define ALUOP_EQU  4'ha // Set Equal ((rs1==rs2)? 1:0)
`define ALUOP_NEQ  4'hb // Set Not Equal ((rs1==rs2)? 1:0)

`define ALUOP_AND  4'hc // Bit wise AND
`define ALUOP_OR   4'hd // Bit wise OR
`define ALUOP_XOR  4'he // Bit wise XOR

// ALU source select
`define ALU_SRCMUX_RS1  2'h0
`define ALU_SRCMUX_RS2  2'h0
`define ALU_SRCMUX_IMM  2'h1
`define ALU_SRCMUX_PC   2'h2
`define ALU_SRCMUX_ZERO 2'h3



// Memory /////////////////////////////////////////////////////////////////////
`define MEM_TYPE_INT32  3'h0
`define MEM_TYPE_UINT32 3'h0
`define MEM_TYPE_INT16  3'h1
`define MEM_TYPE_UINT16 3'h2
`define MEM_TYPE_INT8   3'h3
`define MEM_TYPE_UINT8  3'h4