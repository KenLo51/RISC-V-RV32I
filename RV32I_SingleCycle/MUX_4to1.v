module MUX_4to1
(
    select_i,
    data0_i,
    data1_i,
    data2_i,
    data3_i,
    data_o
);
//*****************************************************************************
    // I/O Port Declaration
    input  wire [ 2-1:0] select_i; // Select
    input  wire [32-1:0] data0_i;  // Mux Data 0
    input  wire [32-1:0] data1_i;  // Mux Data 1
    input  wire [32-1:0] data2_i;  // Mux Data 2
    input  wire [32-1:0] data3_i;  // Mux Data 3
    output reg  [32-1:0] data_o;   // Mux output
//*****************************************************************************
// Block: MUX select
    always @(*)
    begin
        case (select_i)
            2'b00:   data_o = data0_i;
            2'b01:   data_o = data1_i;
            2'b10:   data_o = data2_i;
            2'b11:   data_o = data3_i;
            default: data_o = 32'd0; // None
        endcase 
    end
//*****************************************************************************
endmodule