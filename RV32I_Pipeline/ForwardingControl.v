module ForwardingControl (
    exe_alu_writeback_i,
    exe_mem_read_i,
    exe_rs1_read_i,
    exe_rs2_read_i,
    exe_rs1_addr_i,
    exe_rs1_data_i,
    exe_rs2_addr_i,
    exe_rs2_data_i,

    exe_rs1_data_o,
    exe_rs2_data_o,

    mem_alu_writeback_i,
    mem_mem_read_i,
    mem_mem_hit_i,
    mem_rs1_read_i,
    mem_rs2_read_i,
    mem_rs1_addr_i,
    //mem_rs1_data_i,
    mem_rs2_addr_i,
    mem_rs2_data_i,
    mem_rd_addr_i,
    mem_alu_result_i,

    // mem_rs1_data_o, memory address from alu
    mem_rs2_data_o,

    wb_alu_writeback_i,
    wb_mem_read_i,
    wb_rd_addr_i,
    wb_rd_data_i,

    if_stall_o,
    id_stall_o,
    exe_stall_o,
    mem_stall_o,
    wb_stall_o,
);

// I/O Port Declaration ///////////////////////////////////////////////////////
    // IO from stage 3(execute)
    input            exe_alu_writeback_i; // is alu result will write to Rd
    input            exe_mem_read_i; // is memory will write to Rd
    input            exe_rs1_read_i;
    input            exe_rs2_read_i;
    input      [ 4:0]exe_rs1_addr_i;
    input      [31:0]exe_rs1_data_i;
    input      [ 4:0]exe_rs2_addr_i;
    input      [31:0]exe_rs2_data_i;

    output     [31:0]exe_rs1_data_o;
    output     [31:0]exe_rs2_data_o;

    
    // IO from stage 4(memorye)
    input            mem_alu_writeback_i;
    input            mem_mem_read_i;
    input            mem_mem_hit_i;
    input            mem_rs1_read_i;
    input            mem_rs2_read_i;
    input      [ 4:0]mem_rs1_addr_i;
    //input      [31:0]mem_rs1_data_i;
    input      [ 4:0]mem_rs2_addr_i;
    input      [31:0]mem_rs2_data_i;
    input      [ 4:0]mem_rd_addr_i;
    input      [31:0]mem_alu_result_i;

    output     [31:0]mem_rs1_data_o;
    output     [31:0]mem_rs2_data_o;
    
    // IO from stage 5(write back)
    input            wb_alu_writeback_i;
    input            wb_mem_read_i;
    input      [ 4:0]wb_rd_addr_i;
    input      [31:0]wb_rd_data_i;

    output           if_stall_o;
    output           id_stall_o;
    output           exe_stall_o;
    output           mem_stall_o;
    output           wb_stall_o;

// Behavior Declaration ///////////////////////////////////////////////////////
    // stall control
    assign id_stall_o  = if_stall_o;
    assign if_stall_o  = exe_stall_o;
    assign exe_stall_o = mem_stall_o ||
                         (exe_rs1_read_i && ( (mem_mem_hit_i==1'b0) || // cache miss
                                              ( (exe_rs1_addr_i!=5'd00)&&exe_rs1_read_i&&(mem_rd_addr_i==exe_rs1_addr_i)&&mem_mem_read_i) )) ||
                         (exe_rs2_read_i && ( (mem_mem_hit_i==1'b0) || // cache miss
                                              ( (exe_rs2_addr_i!=5'd00)&&exe_rs2_read_i&&(mem_rd_addr_i==exe_rs2_addr_i)&&mem_mem_read_i) ));
    assign mem_stall_o = wb_stall_o ||
                         (mem_mem_hit_i==1'b0); // cache miss
    assign wb_stall_o  = 1'b0; // useless

    // forwarding to exe stage
    assign exe_rs1_data_o = (!exe_rs1_read_i)? exe_rs1_data_i: // regisiter data is useless for this operation
                            (exe_rs1_addr_i==5'd00)? 32'h0000_0000 : // reg 0 always is 0
                            (mem_alu_writeback_i&&(mem_rd_addr_i == exe_rs1_addr_i))? mem_alu_result_i : 
                            ((wb_alu_writeback_i || wb_mem_read_i)&&(wb_rd_addr_i == exe_rs1_addr_i))? wb_rd_data_i :
                            exe_rs1_data_i;
    assign exe_rs2_data_o = (!exe_rs2_read_i)? exe_rs2_data_i: // regisiter data is useless for this operation
                            (exe_rs2_addr_i==5'd00)? 32'h0000_0000 : // reg 0 always is 0
                            (mem_alu_writeback_i&&(mem_rd_addr_i == exe_rs2_addr_i))? mem_alu_result_i : 
                            ((wb_alu_writeback_i || wb_mem_read_i)&&(wb_rd_addr_i == exe_rs2_addr_i))? wb_rd_data_i :
                            exe_rs2_data_i;
    
    // forwarding to mem stage
    assign mem_rs2_data_o = (!mem_rs2_read_i)? mem_rs2_data_i: // regisiter data is useless for this operation
                            (exe_rs2_addr_i==5'd00)? 32'h0000_0000 : // reg 0 always is 0
                            ((wb_alu_writeback_i || wb_mem_read_i)&&(wb_rd_addr_i == exe_rs2_addr_i))? wb_rd_data_i : // forward from write-back stage
                            mem_rs2_data_i; // does not need fordwarding


endmodule