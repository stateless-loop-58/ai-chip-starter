module axis_systolic
    (
        input  wire         aclk,
        input  wire         aresetn,
        // *** AXIS slave port ***
        output wire         s_axis_tready,
        input  wire [31:0]  s_axis_tdata,
        input  wire         s_axis_tvalid,
        input  wire         s_axis_tlast,
        // *** AXIS master port ***
        input  wire         m_axis_tready,
        output wire [127:0] m_axis_tdata,
        output wire         m_axis_tvalid,
        output wire         m_axis_tlast
    );
    
    // State machine
    reg [2:0] state_reg, state_next;
    reg [2:0] cnt_word_reg, cnt_word_next;

    // MM2S FIFO    
    wire [8:0] mm2s_data_count;
    wire start_from_mm2s;
    reg mm2s_ready_reg, mm2s_ready_next;
    wire [31:0] mm2s_data;
    
    // Systolic
    wire signed [7:0] a0, a1, a2, a3;
    wire in_valid;
    reg signed [7:0] b00, b01, b02, b03;
    reg signed [7:0] b10, b11, b12, b13;
    reg signed [7:0] b20, b21, b22, b23;
    reg signed [7:0] b30, b31, b32, b33;
    wire load_b0, load_b1, load_b2, load_b3;
    wire signed [31:0] y0, y1, y2, y3;
    wire out_valid;

    // S2MM FIFO
    wire [8:0] s2mm_data_count;
    wire [127:0] s2mm_data;
    wire s2mm_valid;
    wire s2mm_last;
        
    // *** MM2S FIFO ************************************************************
    // xpm_fifo_axis: AXI Stream FIFO
    // Xilinx Parameterized Macro, version 2018.3
    xpm_fifo_axis
    #(
        .CDC_SYNC_STAGES(2),                 // DECIMAL
        .CLOCKING_MODE("common_clock"),      // String
        .ECC_MODE("no_ecc"),                 // String
        .FIFO_DEPTH(256),                    // DECIMAL, depth 256 elemen 
        .FIFO_MEMORY_TYPE("auto"),           // String
        .PACKET_FIFO("false"),               // String
        .PROG_EMPTY_THRESH(10),              // DECIMAL
        .PROG_FULL_THRESH(10),               // DECIMAL
        .RD_DATA_COUNT_WIDTH(1),             // DECIMAL
        .RELATED_CLOCKS(0),                  // DECIMAL
        .SIM_ASSERT_CHK(0),                  // DECIMAL
        .TDATA_WIDTH(32),                    // DECIMAL, data width 32 bit
        .TDEST_WIDTH(1),                     // DECIMAL
        .TID_WIDTH(1),                       // DECIMAL
        .TUSER_WIDTH(1),                     // DECIMAL
        .USE_ADV_FEATURES("0004"),           // String, write data count
        .WR_DATA_COUNT_WIDTH(9)              // DECIMAL, width log2(256)+1=9 
    )
    xpm_fifo_axis_0
    (
        .almost_empty_axis(), 
        .almost_full_axis(), 
        .dbiterr_axis(), 
        .prog_empty_axis(), 
        .prog_full_axis(), 
        .rd_data_count_axis(), 
        .sbiterr_axis(), 
        .injectdbiterr_axis(1'b0), 
        .injectsbiterr_axis(1'b0), 
    
        .s_aclk(aclk), // aclk
        .m_aclk(aclk), // aclk
        .s_aresetn(aresetn), // aresetn
        
        .s_axis_tready(s_axis_tready), // ready    
        .s_axis_tdata(s_axis_tdata), // data
        .s_axis_tvalid(s_axis_tvalid), // valid
        .s_axis_tdest(1'b0), 
        .s_axis_tid(1'b0), 
        .s_axis_tkeep(8'hff), 
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tstrb(8'hff), 
        .s_axis_tuser(1'b0), 
        
        .m_axis_tready(mm2s_ready_reg), // ready  
        .m_axis_tdata(mm2s_data), // data
        .m_axis_tvalid(), // valid
        .m_axis_tdest(), 
        .m_axis_tid(), 
        .m_axis_tkeep(), 
        .m_axis_tlast(), 
        .m_axis_tstrb(), 
        .m_axis_tuser(),  
        
        .wr_data_count_axis(mm2s_data_count) // data count
    );

    // *** Main control *********************************************************
    // Start signal from DMA MM2S
    assign start_from_mm2s = (mm2s_data_count >= 8); // B = 4 word, A = 4 word, total = 8 word

    // State machine for AXI-Stream protocol
    always @(posedge aclk)
    begin
        if (!aresetn)
        begin
            state_reg <= 0;
            mm2s_ready_reg <= 0;
            cnt_word_reg <= 0;
        end
        else
        begin
            state_reg <= state_next;
            mm2s_ready_reg <= mm2s_ready_next;
            cnt_word_reg <= cnt_word_next;
        end
    end

    always @(*)
    begin
        state_next = state_reg;
        mm2s_ready_next = mm2s_ready_reg;
        cnt_word_next = cnt_word_reg;
        case (state_reg)
            0: // Wait until data from MM2S is ready (8 words) and result FIFO has room
            begin
                if (start_from_mm2s && (s2mm_data_count < 250))
                begin
                    state_next = 1;
                    mm2s_ready_next = 1; // Tell the MM2S FIFO that it is ready to accept data
                end
            end
            1: // Write input B to systolic stationary input
            begin
                if (cnt_word_reg == 3)
                begin
                    state_next = 2;
                    cnt_word_next = 0;
                end
                else
                begin
                    cnt_word_next = cnt_word_reg + 1;
                end
            end
            2: // Write input A to systolic moving input
            begin
                if (cnt_word_reg == 3)
                begin
                    state_next = 3;
                    mm2s_ready_next = 0; // Tell the MM2S FIFO to hold new data from DMA
                    cnt_word_next = 0;
                end
                else
                begin
                    cnt_word_next = cnt_word_reg + 1;
                end                
            end
            3: // Wait until last row of systolic output Y
            begin
                if (cnt_word_reg == 7)
                begin
                    state_next = 4;
                    cnt_word_next = 0;
                end
                else
                begin
                    cnt_word_next = cnt_word_reg + 1;
                end 
            end
            4: // Set tlast to 1
            begin
                state_next = 0;
            end
        endcase
    end
    
    // Control systolic moving input
    assign a0 = mm2s_data[7:0];
    assign a1 = mm2s_data[15:8];
    assign a2 = mm2s_data[23:16];
    assign a3 = mm2s_data[31:24];
    assign in_valid = (state_reg == 2) ? 1 : 0;
    
    // Control systolic stationary input
    always @(posedge aclk)
    begin
        if (!aresetn)
        begin
            b00 <= 0; b01 <= 0; b02 <= 0; b03 <= 0;
            b10 <= 0; b11 <= 0; b12 <= 0; b13 <= 0;
            b20 <= 0; b21 <= 0; b22 <= 0; b23 <= 0;
            b30 <= 0; b31 <= 0; b32 <= 0; b33 <= 0;
        end
        else if (load_b0)
        begin
            b00 <= mm2s_data[7:0]; b01 <= mm2s_data[15:8]; b02 <= mm2s_data[23:16]; b03 <= mm2s_data[31:24];
        end
        else if (load_b1)
        begin
            b10 <= mm2s_data[7:0]; b11 <= mm2s_data[15:8]; b12 <= mm2s_data[23:16]; b13 <= mm2s_data[31:24];
        end
        else if (load_b2)
        begin
            b20 <= mm2s_data[7:0]; b21 <= mm2s_data[15:8]; b22 <= mm2s_data[23:16]; b23 <= mm2s_data[31:24];
        end
        else if (load_b3)
        begin
            b30 <= mm2s_data[7:0]; b31 <= mm2s_data[15:8]; b32 <= mm2s_data[23:16]; b33 <= mm2s_data[31:24];
        end
    end
    assign load_b0 = ((state_reg == 1) && (cnt_word_reg == 0)) ? 1 : 0;
    assign load_b1 = ((state_reg == 1) && (cnt_word_reg == 1)) ? 1 : 0;
    assign load_b2 = ((state_reg == 1) && (cnt_word_reg == 2)) ? 1 : 0;
    assign load_b3 = ((state_reg == 1) && (cnt_word_reg == 3)) ? 1 : 0;

    // Control S2MM FIFO
    assign s2mm_data = {y3, y2, y1, y0};
    assign s2mm_valid = out_valid;
    assign s2mm_last = (state_reg == 4) ? 1 : 0;

    // *** NN *******************************************************************
    systolic systolic_0
    (
        .clk(aclk),
        .rst_n(aresetn),
        .en(1'b1),
        .clr(1'b0),
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .in_valid(in_valid),
        .b00(b00), .b01(b01), .b02(b02), .b03(b03),
        .b10(b10), .b11(b11), .b12(b12), .b13(b13),
        .b20(b20), .b21(b21), .b22(b22), .b23(b23),
        .b30(b30), .b31(b31), .b32(b32), .b33(b33),
        .y0(y0), .y1(y1), .y2(y2), .y3(y3),
        .out_valid(out_valid)
    );

    // *** S2MM FIFO ************************************************************
    // xpm_fifo_axis: AXI Stream FIFO
    // Xilinx Parameterized Macro, version 2018.3
    xpm_fifo_axis
    #(
        .CDC_SYNC_STAGES(2),                 // DECIMAL
        .CLOCKING_MODE("common_clock"),      // String
        .ECC_MODE("no_ecc"),                 // String
        .FIFO_DEPTH(256),                    // DECIMAL, depth 256 elemen 
        .FIFO_MEMORY_TYPE("auto"),           // String
        .PACKET_FIFO("false"),               // String
        .PROG_EMPTY_THRESH(10),              // DECIMAL
        .PROG_FULL_THRESH(10),               // DECIMAL
        .RD_DATA_COUNT_WIDTH(1),             // DECIMAL
        .RELATED_CLOCKS(0),                  // DECIMAL
        .SIM_ASSERT_CHK(0),                  // DECIMAL
        .TDATA_WIDTH(128),                   // DECIMAL, data width 128 bit
        .TDEST_WIDTH(1),                     // DECIMAL
        .TID_WIDTH(1),                       // DECIMAL
        .TUSER_WIDTH(1),                     // DECIMAL
        .USE_ADV_FEATURES("0004"),           // String, write data count
        .WR_DATA_COUNT_WIDTH(9)              // DECIMAL, width log2(256)+1=9 
    )
    xpm_fifo_axis_1
    (
        .almost_empty_axis(), 
        .almost_full_axis(), 
        .dbiterr_axis(), 
        .prog_empty_axis(), 
        .prog_full_axis(), 
        .rd_data_count_axis(), 
        .sbiterr_axis(), 
        .injectdbiterr_axis(1'b0), 
        .injectsbiterr_axis(1'b0), 
    
        .s_aclk(aclk), // aclk
        .m_aclk(aclk), // aclk
        .s_aresetn(aresetn), // aresetn
        
        .s_axis_tready(), // ready    
        .s_axis_tdata(s2mm_data), // data
        .s_axis_tvalid(s2mm_valid), // valid
        .s_axis_tdest(1'b0), 
        .s_axis_tid(1'b0), 
        .s_axis_tkeep(8'hff), 
        .s_axis_tlast(s2mm_last),
        .s_axis_tstrb(8'hff), 
        .s_axis_tuser(1'b0), 
        
        .m_axis_tready(m_axis_tready), // ready  
        .m_axis_tdata(m_axis_tdata), // data
        .m_axis_tvalid(m_axis_tvalid), // valid
        .m_axis_tdest(), 
        .m_axis_tid(), 
        .m_axis_tkeep(), 
        .m_axis_tlast(m_axis_tlast), 
        .m_axis_tstrb(), 
        .m_axis_tuser(),  
        
        .wr_data_count_axis(s2mm_data_count) // data count
    );
    
endmodule
