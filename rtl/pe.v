module pe
    (
        input  wire signed [7:0]  a_in,
        input  wire signed [31:0] y_in,
        input  wire signed [7:0]  b,
        output wire signed [7:0]  a_out,
        output wire signed [31:0] y_out
    );
    
    wire signed [31:0] mult; 
    
    assign a_out = a_in;
    assign mult  = a_in * b;
    assign y_out = y_in + mult;

endmodule
