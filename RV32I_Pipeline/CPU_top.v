module CPU_top(
    clk_i,
    rst_n
);
    // I/O Port Declaration ///////////////////////////////////////////////////
        input           clk_i;      // System clock
        input           rst_n;      // All reset

    // Internal Signals ///////////////////////////////////////////////////////
        // Stage 1 : Instruction Facth
            wire       if_stall;
            // progrom counter
            wire [31:0]if_curr_pc;
            wire [31:0]if_pc_plus_4;
            wire [31:0]if_next_pc;
            wire [31:0]if_instr;

        // Stage 2 : Instruction Decode
            wire       id_stall;
            wire       id_clear;
            // progrom counter
            wire [31:0]id_curr_pc;
            wire [31:0]id_instr;
            // regisiter
            wire [ 4:0]id_rs1_addr;
            wire [ 4:0]id_rs2_addr;
            wire [ 4:0]id_rd_addr;
            wire [31:0]id_rs1_data;
            wire [31:0]id_rs2_data;
            wire [ 1:0]id_rd_select;
            wire       id_rs1_read;
            wire       id_rs2_read;
            wire       id_rd_write;
            // immediate value
            wire [31:0]id_imm;
            // alu
            wire [ 1:0]id_alu_s1_select;
            wire [ 1:0]id_alu_s2_select;
            wire [ 3:0]id_alu_op;
            wire       id_alu_writeback;
            // flow control
            wire       id_branch;
            wire       id_jump;
            wire       id_jalr;
            // memory
            wire       id_mem_read;
            wire       id_mem_write;
            wire [ 2:0]id_mem_type;
        // Stage 3 : Execute
            wire       exe_stall;
            wire       exe_clear;
            // progrom counter
            wire [31:0]exe_curr_pc;
            wire [31:0]exe_pc_plus_imm;
            wire [31:0]exe_pc_plus_4;
            // regisiter
            wire [ 4:0]exe_rs1_addr;
            wire [ 4:0]exe_rs2_addr;
            wire [ 4:0]exe_rd_addr;
            wire [31:0]exe_rs1_data;
            wire [31:0]exe_rs1_data_forward;
            wire [31:0]exe_rs2_data;
            wire [31:0]exe_rs2_data_forward;
            wire [ 1:0]exe_rd_select;
            wire       exe_rs1_read;
            wire       exe_rs2_read;
            wire       exe_rd_write;
            // immediate value
            wire [31:0]exe_imm;
            // alu
            wire [ 1:0]exe_alu_s1_select;
            wire [ 1:0]exe_alu_s2_select;
            wire [ 3:0]exe_alu_op;
            wire       exe_alu_writeback;
            wire [31:0]exe_alu_s1_data;
            wire [31:0]exe_alu_s2_data;
            wire [31:0]exe_alu_result;
            // flow control
            wire       exe_branch;
            wire       exe_branchResult;
            wire       exe_jump;
            wire       exe_jalr;
            // memory
            wire       exe_mem_read;
            wire       exe_mem_write;
            wire [ 2:0]exe_mem_type;
        // Stage 4 : Memory
            wire       mem_stall;
            wire       mem_clear;
            // progrom counter
            wire [31:0]mem_pc_plus_imm;
            wire [31:0]mem_pc_plus_4;
            // regisiter
            wire [ 4:0]mem_rs1_addr;
            wire [ 4:0]mem_rs2_addr;
            wire [ 4:0]mem_rd_addr;
            wire [31:0]mem_rs2_data;
            wire [31:0]mem_rs2_data_forward;
            wire [ 1:0]mem_rd_select;
            wire       mem_rs1_read;
            wire       mem_rs2_read;
            wire       mem_rd_write;
            // immediate value
            // alu
            wire       mem_alu_writeback;
            wire [31:0]mem_alu_result;
            // flow control
            wire       mem_branch;
            wire       mem_jump;
            wire       mem_jalr;
            // memory
            wire       mem_mem_read;
            wire       mem_mem_write;
            wire [ 2:0]mem_mem_type;
            wire       mem_data_mem_hit;
            wire [31:0]mem_mem_data;
        // Stage 5 : Write Back
            wire       wb_stall;
            wire       wb_clear;
            // progrom counter
            wire [31:0]wb_pc_plus_imm;
            wire [31:0]wb_pc_plus_4;
            // regisiter
            wire       wb_rd_write;
            wire [ 4:0]wb_rd_addr;
            wire [31:0]wb_rd_data;
            wire [ 1:0]wb_rd_select;
            // immediate value
            // alu
            wire [31:0]wb_alu_result;
            // flow control
            // memory
            wire       wb_mem_read;
            wire [31:0]wb_mem_data;

    // Behavior Declaration /////////////////////////////////////////////////////////
    // Stage 1 : Fatch //////////////////////////////////////////////////////////////

        ProgramCounter programcounter_u(
            .clk_i(clk_i),
            .rst_n(rst_n),
            .en_i(1'b1),
            .next_pc_i(if_next_pc),
            .curr_pc_o(if_curr_pc)
        );

        assign if_pc_plus_4 = if_curr_pc + 32'h4;
        assign if_next_pc = (mem_branch)?   mem_pc_plus_imm :
                            (mem_jump)?         mem_pc_plus_imm :
                            (mem_jalr)?         mem_alu_result :
                            (if_stall)?     if_curr_pc :
                                            if_pc_plus_4;

        Instr_Memory instr_memory_u(
            .PC_addr_i(if_curr_pc),
            .instr_o(if_instr)
        );

    // Pipe Regs Fatch-Decode ///////////////////////////////////////////////////////
        // progrom counter
        Pipe_Reg #(.size(32)) pipeReg_IfId_curr_pc_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(id_stall),
            .clear(id_clear),
            .data_i(if_curr_pc),
            .data_o(id_curr_pc)
        );
        // 
        Pipe_Reg #(.size(32)) pipeReg_IfId_instr_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(id_stall),
            .clear(id_clear),
            .data_i(if_instr),
            .data_o(id_instr)
        );

    // Stage 2 : Decode /////////////////////////////////////////////////////////////
        Decoder decoder_u(
            .instr_i(id_instr),

            .rs1_o(id_rs1_addr), // rs1 address
            .rs2_o(id_rs2_addr), // rs2 address
            .rd_o(id_rd_addr),  // rd address

            .imm_o(id_imm), // immediate value

            .alu_s1_o(id_alu_s1_select), // select the source for ALU operation
            .alu_s2_o(id_alu_s2_select), // select the source for ALU operation
            .aluop_o(id_alu_op),  // select alu operation
            .alu_writeback_o(id_alu_writeback),

            // .pc_select_o(id_pc_select), // select the next instruction address
            .branch_o(id_branch),    // is a branch instruction
            .jump_o(id_jump),      // is a JAL instruction
            .jalr_o(id_jalr),      // is a JALR instruction

            .mem_read_o(id_mem_read),  // is a load instruction
            .mem_write_o(id_mem_write), // is a store instruction
            .mem_type_o(id_mem_type),  // memery access data type

            .rs1_read_o(id_rs1_read), // is the operation need to read from regisiter 1
            .rs2_read_o(id_rs2_read), // is the operation need to read from regisiter 2
            .rd_select_o(id_rd_select), // select the value
            .rd_write_o(id_rd_write)  // write to regisiter
        );

        Reg_File regfile_u(
            .clk_i(clk_i),
            .rst_n(rst_n),
            .RegWrite_i(wb_rd_write),
            .rs1_addr_i(id_rs1_addr),
            .rs2_addr_i(id_rs2_addr),
            .rd_addr_i(wb_rd_addr),
            .rd_data_i(wb_rd_data),
            .rs1_data_o(id_rs1_data),
            .rs2_data_o(id_rs2_data)
        );

    // Pipe Regs Decode-Execute /////////////////////////////////////////////////////
        // progrom counter
        Pipe_Reg #(.size(32)) pipeReg_IdExe_curr_pc_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_curr_pc),
            .data_o(exe_curr_pc)
        );
        // regisiter
        Pipe_Reg #(.size(5)) pipeReg_IdExe_rs1_addr_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_rs1_addr),
            .data_o(exe_rs1_addr)
        );
        Pipe_Reg #(.size(5)) pipeReg_IdExe_rs2_addr_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_rs2_addr),
            .data_o(exe_rs2_addr)
        );
        Pipe_Reg #(.size(32)) pipeReg_IdExe_rs1_data_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_rs1_data),
            .data_o(exe_rs1_data)
        );
        Pipe_Reg #(.size(32)) pipeReg_IdExe_rs2_data_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_rs2_data),
            .data_o(exe_rs2_data)
        );
        Pipe_Reg #(.size(5)) pipeReg_IdExe_rsd_addr_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_rd_addr),
            .data_o(exe_rd_addr)
        );
        Pipe_Reg #(.size(2)) pipeReg_IdExe_rd_select_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_rd_select),
            .data_o(exe_rd_select)
        );
        Pipe_Reg #(.size(1)) pipeReg_IdExe_rs1_read_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_rs1_read),
            .data_o(exe_rs1_read)
        );
        Pipe_Reg #(.size(1)) pipeReg_IdExe_rs2_read_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_rs2_read),
            .data_o(exe_rs2_read)
        );
        Pipe_Reg #(.size(1)) pipeReg_IdExe_rd_write_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_rd_write),
            .data_o(exe_rd_write)
        );
        // immediate value
        Pipe_Reg #(.size(32)) pipeReg_IdExe_imm_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_imm),
            .data_o(exe_imm)
        );
        // alu
        Pipe_Reg #(.size(2)) pipeReg_IdExe_alu_s1_select_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_alu_s1_select),
            .data_o(exe_alu_s1_select)
        );
        Pipe_Reg #(.size(2)) pipeReg_IdExe_alu_s2_select_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_alu_s2_select),
            .data_o(exe_alu_s2_select)
        );
        Pipe_Reg #(.size(4)) pipeReg_IdExe_alu_op_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_alu_op),
            .data_o(exe_alu_op)
        );
        Pipe_Reg #(.size(1)) pipeReg_IdExe_alu_writeback_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_alu_writeback),
            .data_o(exe_alu_writeback)
        );
        // flow control
        Pipe_Reg #(.size(1)) pipeReg_IdExe_branch_u(
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_branch),
            .data_o(exe_branch)
        );
        Pipe_Reg #(.size(1)) pipeReg_IdExe_jump_u(
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_jump),
            .data_o(exe_jump)
        );
        Pipe_Reg #(.size(1)) pipeReg_IdExe_jalr_u(
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_jalr),
            .data_o(exe_jalr)
        );
        // memory
        Pipe_Reg #(.size(1)) pipeReg_IdExe_mem_read_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_mem_read),
            .data_o(exe_mem_read)
        );
        Pipe_Reg #(.size(1)) pipeReg_IdExe_mem_write_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_mem_write),
            .data_o(exe_mem_write)
        );
        Pipe_Reg #(.size(3)) pipeReg_IdExe_mem_type_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(exe_stall),
            .clear(exe_clear),
            .data_i(id_mem_type),
            .data_o(exe_mem_type)
        );

    // Stage 3 : Execute ////////////////////////////////////////////////////////////
        assign exe_pc_plus_imm = exe_curr_pc + exe_imm; // for branch and jump instructions
        assign exe_pc_plus_4 = exe_curr_pc + 32'h0000_0004; // for other instructions

        MUX_4to1 alu_s1_mux_u(
            .select_i(exe_alu_s1_select),
            .data0_i(exe_rs1_data_forward),
            .data1_i(exe_imm),
            .data2_i(exe_curr_pc),
            .data3_i(32'h0000_0000),
            .data_o(exe_alu_s1_data)
        );
        MUX_4to1 alu_s2_mux_u(
            .select_i(exe_alu_s2_select),
            .data0_i(exe_rs2_data_forward),
            .data1_i(exe_imm),
            .data2_i(exe_curr_pc),
            .data3_i(32'h0000_0000),
            .data_o(exe_alu_s2_data)
        );
        ALU alu_u(
            .val1_i(exe_alu_s1_data), 
            .val2_i(exe_alu_s2_data),
            .aluop_i(exe_alu_op),
            .result_o(exe_alu_result)
        );

        assign exe_branchResult = exe_branch && (exe_alu_result!=32'h0000_0000);

    // Pipe Regs Execute-Memory /////////////////////////////////////////////////////
        // progrom counter
        Pipe_Reg #(.size(32)) pipeReg_ExeMem_pc_plus_imm_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_pc_plus_imm),
            .data_o(mem_pc_plus_imm)
        );
        Pipe_Reg #(.size(32)) pipeReg_ExeMem_pc_plus_4_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_pc_plus_4),
            .data_o(mem_pc_plus_4)
        );
        // regisiter
        Pipe_Reg #(.size(5)) pipeReg_ExeMem_rs1_addr_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_rs1_addr),
            .data_o(mem_rs1_addr)
        );
        Pipe_Reg #(.size(5)) pipeReg_ExeMem_rs2_addr_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_rs2_addr),
            .data_o(mem_rs2_addr)
        );
        // Pipe_Reg #(.size(32)) pipeReg_ExeMem_rs1_data_u (
        //     .rst_i(rst_n),
        //     .clk_i(clk_i),
        //     .stall(mem_stall),
        //     .clear(mem_clear),
        //     .data_i(exe_rs1_data_forward),
        //     .data_o(mem_rs1_data)
        // );
        Pipe_Reg #(.size(32)) pipeReg_ExeMem_rs2_data_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_rs2_data_forward),
            .data_o(mem_rs2_data)
        );
        Pipe_Reg #(.size(5)) pipeReg_ExeMem_rd_addr_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_rd_addr),
            .data_o(mem_rd_addr)
        );
        Pipe_Reg #(.size(2)) pipeReg_ExeMem_rd_select_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_rd_select),
            .data_o(mem_rd_select)
        );
        Pipe_Reg #(.size(1)) pipeReg_ExeMem_rs1_read_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_rs1_read),
            .data_o(mem_rs1_read)
        );
        Pipe_Reg #(.size(1)) pipeReg_ExeMem_rs2_read_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_rs2_read),
            .data_o(mem_rs2_read)
        );
        Pipe_Reg #(.size(1)) pipeReg_ExeMem_rd_write_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_rd_write),
            .data_o(mem_rd_write)
        );
        // alu
        Pipe_Reg #(.size(1)) pipeReg_ExeMem_alu_writeback_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_alu_writeback),
            .data_o(mem_alu_writeback)
        );
        Pipe_Reg #(.size(32)) pipeReg_ExeMem_alu_result_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_alu_result),
            .data_o(mem_alu_result)
        );
        // flow control
        Pipe_Reg #(.size(1)) pipeReg_ExeMem_branch_u(
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_branchResult),
            .data_o(mem_branch)
        );
        Pipe_Reg #(.size(1)) pipeReg_ExeMem_jump_u(
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_jump),
            .data_o(mem_jump)
        );
        Pipe_Reg #(.size(1)) pipeReg_ExeMem_jalr_u(
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_jalr),
            .data_o(mem_jalr)
        );
        // memory
        Pipe_Reg #(.size(1)) pipeReg_ExeMem_mem_read_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_mem_read),
            .data_o(mem_mem_read)
        );
        Pipe_Reg #(.size(1)) pipeReg_ExeMem_mem_write_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_mem_write),
            .data_o(mem_mem_write)
        );
        Pipe_Reg #(.size(3)) pipeReg_ExeMem_mem_type_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(mem_stall),
            .clear(mem_clear),
            .data_i(exe_mem_type),
            .data_o(mem_mem_type)
        );

    // Stage 4 : Memory /////////////////////////////////////////////////////////////
        Data_Memory data_memory_u(
            .clk_i(clk_i),
            .addr_i(mem_alu_result),
            .data_wr_i(mem_rs2_data_forward),
            .MemRead_i(mem_mem_read),
            .MemWrite_i(mem_mem_write),
            .data_type_i(mem_mem_type),
            .data_rd_o(mem_mem_data),
            .hit_o(mem_data_mem_hit)
        );

    // Pipe Regs Memory-WriteBack ///////////////////////////////////////////////////
        // progrom counter
        Pipe_Reg #(.size(32)) pipeReg_MemWb_pc_plus_imm_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(wb_stall),
            .clear(wb_clear),
            .data_i(mem_pc_plus_imm),
            .data_o(wb_pc_plus_imm)
        );
        Pipe_Reg #(.size(32)) pipeReg_MemWb_pc_plus_4_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(wb_stall),
            .clear(wb_clear),
            .data_i(mem_pc_plus_4),
            .data_o(wb_pc_plus_4)
        );
        // regisiter
        Pipe_Reg #(.size(5)) pipeReg_MemWb_rd_addr_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(wb_stall),
            .clear(wb_clear),
            .data_i(mem_rd_addr),
            .data_o(wb_rd_addr)
        );
        Pipe_Reg #(.size(2)) pipeReg_MemWb_rd_select_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(wb_stall),
            .clear(wb_clear),
            .data_i(mem_rd_select),
            .data_o(wb_rd_select)
        );
        Pipe_Reg #(.size(1)) pipeReg_MemWb_rd_write_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(wb_stall),
            .clear(wb_clear),
            .data_i(mem_rd_write),
            .data_o(wb_rd_write)
        );
        // alu
        Pipe_Reg #(.size(1)) pipeReg_MemWb_alu_writeback_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(wb_stall),
            .clear(wb_clear),
            .data_i(mem_alu_writeback),
            .data_o(wb_alu_writeback)
        );
        Pipe_Reg #(.size(32)) pipeReg_MemWb_alu_result_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(wb_stall),
            .clear(wb_clear),
            .data_i(mem_alu_result),
            .data_o(wb_alu_result)
        );
        // memory
        Pipe_Reg #(.size(1)) pipeReg_MemWb_mem_read_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(wb_stall),
            .clear(wb_clear),
            .data_i(mem_mem_read),
            .data_o(wb_mem_read)
        );
        Pipe_Reg #(.size(32)) pipeReg_MemWb_mem_data_u (
            .rst_i(rst_n),
            .clk_i(clk_i),
            .stall(wb_stall),
            .clear(wb_clear),
            .data_i(mem_mem_data),
            .data_o(wb_mem_data)
        );

    // Stage 5 : Write Back /////////////////////////////////////////////////////////
        MUX_4to1 next_rd_mux_u(
            .select_i(wb_rd_select),
            .data0_i(wb_alu_result),
            .data1_i(wb_mem_data),
            .data2_i(wb_pc_plus_imm),
            .data3_i(wb_pc_plus_4),
            .data_o(wb_rd_data)
        );

    // Other control unit ///////////////////////////////////////////////////////////
        ForwardingControl forwardingControl_u(
            .exe_alu_writeback_i(exe_alu_writeback),
            .exe_mem_read_i(exe_mem_read),
            .exe_rs1_read_i(exe_rs1_read),
            .exe_rs2_read_i(exe_rs2_read),
            .exe_rs1_addr_i(exe_rs1_addr),
            .exe_rs1_data_i(exe_rs1_data),
            .exe_rs2_addr_i(exe_rs2_addr),
            .exe_rs2_data_i(exe_rs2_data),

            .exe_rs1_data_o(exe_rs1_data_forward),
            .exe_rs2_data_o(exe_rs2_data_forward),

            .mem_alu_writeback_i(mem_alu_writeback),
            .mem_mem_read_i(mem_mem_read),
            .mem_mem_hit_i(mem_data_mem_hit),
            .mem_rs1_read_i(mem_rs1_read),
            .mem_rs2_read_i(mem_rs2_read),
            .mem_rs1_addr_i(mem_rs1_addr),
            //.mem_rs1_data_i(mem_rs1_data),
            .mem_rs2_addr_i(mem_rs2_addr),
            .mem_rs2_data_i(mem_rs2_data),
            .mem_rd_addr_i(mem_rd_addr),
            .mem_alu_result_i(mem_alu_result),

            //.mem_rs1_data_o(),
            .mem_rs2_data_o(mem_rs2_data_forward),

            .wb_alu_writeback_i(wb_alu_writeback),
            .wb_mem_read_i(wb_mem_read),
            .wb_rd_addr_i(wb_rd_addr),
            .wb_rd_data_i(wb_rd_data),

            .if_stall_o(if_stall),
            .id_stall_o(id_stall),
            .exe_stall_o(exe_stall),
            .mem_stall_o(mem_stall),
            .wb_stall_o(wb_stall)
        );

        assign id_clear  = mem_jump || mem_jalr || mem_branch;
        assign exe_clear = mem_jump || mem_jalr || mem_branch;
        assign mem_clear = 1'b0;
        assign wb_clear  = 1'b0;

endmodule