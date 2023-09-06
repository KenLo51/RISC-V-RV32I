module CPU_top(
    clk_i,
    rst_n
);
    // I/O Port Declaration
    input           clk_i;      // System clock
    input           rst_n;      // All reset

    // Behavior Declaration
    wire [31:0]next_pc;
    wire [31:0]curr_pc;
    wire [31:0]curr_pc_plus_4;
    wire [31:0]curr_pc_plus_imm;

    wire [31:0]instr;
    wire       instr_mem_hit;

    wire [ 4:0]rd_addr;
    wire [31:0]rd_data;
    wire [ 4:0]rs1_addr;
    wire [31:0]rs1_data;
    wire [ 4:0]rs2_addr;
    wire [31:0]rs2_data;
    wire       rd_write;
    wire [ 1:0]rd_select;
    wire       mem_read;
    wire       mem_write;
    wire [ 2:0]mem_type;
    wire [31:0]mem_data;
    wire       data_mem_hit;

    wire [ 1:0]pc_select;
    wire       jump;

    wire [ 3:0]alu_op; // alu operation select
    wire [ 1:0]alu_s1_select; // alu source select 1
    wire [31:0]alu_s1_data; // alu source 1
    wire [ 1:0]alu_s2_select; // alu source select 2
    wire [31:0]alu_s2_data; // alu source 2
    wire [31:0]alu_result;

    wire [31:0]imm; 

    // Stage 1 : Fatch ////////////////////////////////////////////////////////
    ProgramCounter programcounter_u(
        .clk_i(clk_i),
        .rst_n(rst_n),
        .en_i(instr_mem_hit && (!(mem_read||mem_write) || ((mem_read||mem_write)&&data_mem_hit))),
        .next_pc_i(next_pc),
        .curr_pc_o(curr_pc)
    );


    Instr_Memory instr_memory_u(
        .PC_addr_i(curr_pc),
        .instr_o(instr),
        .hit_o(instr_mem_hit)
    );

    // Stage 2 : Decode ///////////////////////////////////////////////////////
    Decoder decoder_u(
        .instr_i(instr),

        .rs1_o(rs1_addr), // rs1 address
        .rs2_o(rs2_addr), // rs2 address
        .rd_o(rd_addr),  // rd address

        .imm_o(imm), // immediate value

        .alu_s1_o(alu_s1_select), // select the source for ALU operation
        .alu_s2_o(alu_s2_select), // select the source for ALU operation
        .aluop_o(alu_op),  // select alu operation

        .pc_select_o(pc_select), // select the next instruction address

        .mem_read_o(mem_read),  // is a load instruction
        .mem_write_o(mem_write), // is a store instruction
        .mem_type_o(mem_type),  // memery access data type

        .rd_select_o(rd_select), // select the value
        .rd_write_o(rd_write)  // write to regisiter
    );

    Reg_File regfile_u(
        .clk_i(clk_i),
        .rst_n(rst_n),
        .RegWrite_i(rd_write),
        .rs1_addr_i(rs1_addr),
        .rs2_addr_i(rs2_addr),
        .rd_addr_i(rd_addr),
        .rd_data_i(rd_data),
        .rs1_data_o(rs1_data),
        .rs2_data_o(rs2_data)
    );

    // Stage 3 : Execute //////////////////////////////////////////////////////
    assign curr_pc_plus_imm = curr_pc + imm; // for branch and jump instructions
    assign curr_pc_plus_4 = curr_pc + 32'h0000_0004; // for other instructions

    MUX_4to1 alu_s1_mux_u(
        .select_i(alu_s1_select),
        .data0_i(rs1_data),
        .data1_i(imm),
        .data2_i(curr_pc),
        .data3_i(32'h0000_0000),
        .data_o(alu_s1_data)
    );
    MUX_4to1 alu_s2_mux_u(
        .select_i(alu_s2_select),
        .data0_i(rs2_data),
        .data1_i(imm),
        .data2_i(curr_pc),
        .data3_i(32'h0000_0000),
        .data_o(alu_s2_data)
    );
    ALU alu_u(
        .val1_i(alu_s1_data), 
        .val2_i(alu_s2_data),
        .aluop_i(alu_op),
        .result_o(alu_result)
    );

    // Stage 4 : Memory ///////////////////////////////////////////////////////
    Data_Memory data_memory_u(
        .clk_i(clk_i),
        .addr_i(alu_result),
        .data_wr_i(rs2_data),
        .MemRead_i(mem_read),
        .MemWrite_i(mem_write),
        .data_type_i(mem_type),
        .data_rd_o(mem_data),
        .hit_o(data_mem_hit)
    );

    MUX_4to1 next_pc_mux_u(
        .select_i(pc_select),
        .data0_i(curr_pc_plus_4),
        .data1_i(alu_result),
        .data2_i(curr_pc_plus_imm),
        .data3_i((alu_result[0])? curr_pc_plus_imm : curr_pc_plus_4), // branch
        .data_o(next_pc)
    );

    // Stage 5 : Write Back ///////////////////////////////////////////////////
    MUX_4to1 next_rd_mux_u(
        .select_i(rd_select),
        .data0_i(alu_result),
        .data1_i(mem_data),
        .data2_i(curr_pc_plus_imm),
        .data3_i(curr_pc_plus_4),
        .data_o(rd_data)
    );

endmodule