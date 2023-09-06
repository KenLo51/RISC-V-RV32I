module Instr_Memory
(
    PC_addr_i, // PC Address in
    instr_o,   // Instruction out
    hit_o      // weather data is ready
);
//*****************************************************************************
    // I/O Ports Declaration
    input  [31:0] PC_addr_i; // PC Address in
    output [31:0] instr_o;   // Instruction out
    output        hit_o;

    // Global variables Declaration
    // System
    reg    [31:0] memory[0:255]; //32 words Memory

    // System conection
    // Output
    assign instr_o = memory[PC_addr_i/4];
//*****************************************************************************
    initial
    begin
        memory[ 0] = 32'd0; memory[ 1] = 32'd0; memory[ 2] = 32'd0; memory[ 3] = 32'd0;
        memory[ 4] = 32'd0; memory[ 5] = 32'd0; memory[ 6] = 32'd0; memory[ 7] = 32'd0;
        memory[ 8] = 32'd0; memory[ 9] = 32'd0; memory[10] = 32'd0; memory[11] = 32'd0;
        memory[12] = 32'd0; memory[13] = 32'd0; memory[14] = 32'd0; memory[15] = 32'd0;
        memory[16] = 32'd0; memory[17] = 32'd0; memory[18] = 32'd0; memory[19] = 32'd0;
        memory[20] = 32'd0; memory[21] = 32'd0; memory[22] = 32'd0; memory[23] = 32'd0;
        memory[24] = 32'd0; memory[25] = 32'd0; memory[26] = 32'd0; memory[27] = 32'd0;
        memory[28] = 32'd0; memory[29] = 32'd0; memory[30] = 32'd0; memory[31] = 32'd0; 
    end
    assign hit_o = 1'b1;
//*****************************************************************************
endmodule
