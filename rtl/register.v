module register
    #( 
        parameter BIT_BIT_WIDTH = 16
    )
    (
        input wire                            clk,
        input wire                            rst_n,
        input wire                            en,
        input wire                            clr,
        input wire signed [BIT_BIT_WIDTH-1:0] d,
        output reg signed [BIT_BIT_WIDTH-1:0] q
    );
    
    always @(posedge clk)
    begin
        if (!rst_n || clr)
        begin
            q <= 0;
        end
        else if (en)
        begin
            q <= d;
        end
    end
    
endmodule
