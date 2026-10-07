`timescale 1ns / 1ps

module axis_systolic_tb();
    localparam T = 10;
    
    reg aclk;
    reg aresetn;
    
    wire s_axis_tready;
    reg [31:0] s_axis_tdata;
    reg s_axis_tvalid;
    reg s_axis_tlast;
    
    reg m_axis_tready;
    wire [127:0] m_axis_tdata;
    wire m_axis_tvalid;
    wire m_axis_tlast;
    
    axis_systolic dut
    (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast)
    );
    
    always
    begin
        aclk = 0;
        #(T/2);
        aclk = 1;
        #(T/2);
    end

    initial
    begin
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;
        
        aresetn = 0;
        #(T*5);
        aresetn = 1;
        #(T*5);

        s_axis_tvalid = 1;
        s_axis_tdata = {8'd4, 8'd3, 8'd2, 8'd1};
        #T;
        s_axis_tdata = {8'd8, 8'd7, 8'd6, 8'd5};
        #T;
        s_axis_tdata = {8'd12, 8'd11, 8'd10, 8'd9};
        #T; 
        s_axis_tdata = {8'd16, 8'd15, 8'd14, 8'd13};
        #T;
        s_axis_tdata = {8'd4, 8'd3, 8'd2, 8'd1};
        #T;
        s_axis_tdata = {8'd8, 8'd7, 8'd6, 8'd5};
        #T;
        s_axis_tdata = {8'd12, 8'd11, 8'd10, 8'd9};
        #T; 
        s_axis_tdata = {8'd16, 8'd15, 8'd14, 8'd13};
        s_axis_tlast = 1;
        #T;
        s_axis_tvalid = 0;
        s_axis_tdata = 0; 
        s_axis_tlast = 0; 

        s_axis_tvalid = 1;
        s_axis_tdata = {8'd4, 8'd3, 8'd2, 8'd1};
        #T;
        s_axis_tdata = {8'd8, 8'd7, 8'd6, 8'd5};
        #T;
        s_axis_tdata = {8'd12, 8'd11, 8'd10, 8'd9};
        #T; 
        s_axis_tdata = {8'd16, 8'd15, 8'd14, 8'd13};
        #T;
        s_axis_tdata = {8'd4, 8'd3, 8'd2, 8'd1};
        #T;
        s_axis_tdata = {8'd8, 8'd7, 8'd6, 8'd5};
        #T;
        s_axis_tdata = {8'd12, 8'd11, 8'd10, 8'd9};
        #T; 
        s_axis_tdata = {8'd16, 8'd15, 8'd14, 8'd13};
        s_axis_tlast = 1;
        #T;
        s_axis_tvalid = 0;
        s_axis_tdata = 0; 
        s_axis_tlast = 0;   
    end
    
endmodule
