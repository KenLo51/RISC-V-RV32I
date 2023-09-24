module MUX_2to1
(
    select_i, // Select
    data0_i,  // Mux Data 0
    data1_i,  // Mux Data 1
    data_o    // Mux output
);
//*****************************************************************************
    // I/O port declaration
    input           select_i; // Select
    input  [32-1:0] data0_i;  // Mux Data 0
    input  [32-1:0] data1_i;  // Mux Data 1
    output [32-1:0] data_o;   // Mux output

    // System conection
    // Output
    assign data_o = (select_i)? data1_i:data0_i;
//*****************************************************************************
endmodule
