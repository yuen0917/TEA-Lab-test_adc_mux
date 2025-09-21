// `timescale 1ns/1ps

// module wrapper_tb;

//     // Clock / reset
//     reg  sck;
//     reg  rst;
//     reg  start;

//     // I2S-like framing
//     reg  ws;
//     // 8 serial data lines (one per channel) – all zeros per request
//     reg  [7:0] sd;
//     // AXIS sink ready
//     reg  S_AXIS_tready;
//     // DUT outputs
//     wire [127:0] S_AXIS_tdata;
//     wire         S_AXIS_tvalid;
//     wire         S_AXIS_tlast;
//     wire [7:0]   flag_mux_to_adc;
//     wire [7:0]   flag_adc_to_mux;

//     // --- Modified clock generation for 1.024 MHz ---
//     localparam real SCK_PERIOD_NS = 976.5625; // 1 / 1.024MHz in ns
//     localparam real SCK_HALF_NS   = SCK_PERIOD_NS / 2.0;

//     // Instantiate DUT
//     wrapper dut (
//         .sck(sck),
//         .ws(ws),
//         .rst(rst),
//         .start(start),
//         .S_AXIS_tready(S_AXIS_tready),
//         .sd(sd),
//         .S_AXIS_tdata(S_AXIS_tdata),
//         .S_AXIS_tvalid(S_AXIS_tvalid),
//         .S_AXIS_tlast(S_AXIS_tlast),
//         .flag_mux_to_adc_fuck(flag_mux_to_adc),
//         .flag_adc_to_mux_fuck(flag_adc_to_mux)
//     );
//     always #(SCK_HALF_NS) sck = ~sck;

//     // --- Generate ws = 16 kHz (sck / 64) ---
//     always #(31250) ws = ~ws; //單位為ns (timescale 1ns/1ps)
//      // Simplified stimulus
//      initial begin
//          sck=0;
//          S_AXIS_tready=0;
//          ws=0;
//          $display("Start simulation");
//          rst   = 0;
//          start = 0;
//          sd = 8'h00;
//          #2929.687;

//          start = 1;
//          rst   = 1;
//          sd = 8'b11111111;  // 簡單的測試值
//          S_AXIS_tready=1;
//          #2929.687;

//          start = 1;
//          rst   = 0;
//          sd = 8'b11111111;  // 保持相同的值
//          S_AXIS_tready=1;
//        #292968.7;

//          $display("Done");
//          $finish;
//      end

//      // 觀察資料流
//      initial begin
//          $display("=== Data stream ===");
//          forever begin
//              @(posedge sck);
//              if(S_AXIS_tvalid) begin
//                  $display("time=%8t ws=%b sd=%02h tdata[127:0]=%032h",
//                          $time, ws, sd, S_AXIS_tdata[127:0]);
//                  $display("  data1=%08h data2=%08h data3=%08h data4=%08h",
//                          dut.data[0], dut.data[1], dut.data[2], dut.data[3]);
//                  $display("  data5=%08h data6=%08h data7=%08h data8=%08h",
//                          dut.data[4], dut.data[5], dut.data[6], dut.data[7]);
//                  $display("  flag_mux_to_adc=%02h flag_adc_to_mux=%02h",
//                          flag_mux_to_adc, flag_adc_to_mux);
//              end
//          end
//      end

//      // 觀察 flag 信號變化
//      initial begin
//          $display("=== Flag signal ===");
//          forever begin
//              @(posedge sck);
//              if(flag_mux_to_adc != 8'h00 || flag_adc_to_mux != 8'h00) begin
//                  $display("time=%8t flag_mux_to_adc=%02h flag_adc_to_mux=%02h",
//                          $time, flag_mux_to_adc, flag_adc_to_mux);
//              end
//          end
//      end

// endmodule

`timescale 1ns/1ps

module wrapper_tb;

  // =======================
  // 參數：1.024 MHz sck
  // =======================
  localparam real SCK_PERIOD_NS = 976.5625;   // 1 / 1.024MHz
  localparam real SCK_HALF_NS   = SCK_PERIOD_NS / 2.0;

  // I/O to DUT
  reg         sck   = 1'b0;
  reg         ws    = 1'b0;
  reg         rst   = 1'b0;   // 假設 rst 高有效
  reg         start = 1'b0;
  reg         S_AXIS_tready = 1'b0;
  reg  [7:0]  sd    = 8'h00;

  wire [127:0] S_AXIS_tdata;
  wire         S_AXIS_tvalid;
  wire         S_AXIS_tlast;
  wire  [7:0]  flag_mux_to_adc;
  wire  [7:0]  flag_adc_to_mux;

  // =======================
  // DUT
  // =======================
  wrapper dut (
    .sck(sck),
    .ws(ws),
    .rst(rst),
    .start(start),
    .S_AXIS_tready(S_AXIS_tready),
    .sd(sd),
    .S_AXIS_tdata(S_AXIS_tdata),
    .S_AXIS_tvalid(S_AXIS_tvalid),
    .S_AXIS_tlast(S_AXIS_tlast),
    .flag_mux_to_adc_fuck(flag_mux_to_adc),
    .flag_adc_to_mux_fuck(flag_adc_to_mux)
  );

  // =======================
  // sck：1.024 MHz
  // =======================
  always #(SCK_HALF_NS) sck = ~sck;

  // =======================
  // ws：sck/64 = 16 kHz（同步除頻）
  // =======================
  reg [6:0] ws_div = 7'd0;
  always @(posedge sck) begin
    if (ws_div == 7'd63) begin
      ws_div <= 7'd0;
      ws     <= ~ws;
    end else begin
      ws_div <= ws_div + 7'd1;
    end
  end

  // =======================
  // 小工具：等 n 個 sck 正緣
  // =======================
  task wait_sck;
    input integer n;
    integer k;
    begin
      for (k = 0; k < n; k = k + 1) @(posedge sck);
    end
  endtask

   // =======================
   // 產生模擬 ADC 輸入位流
   // =======================
   reg [191:0] sd_pattern;  // 8個24位資料 = 192位
   reg [4:0] bit_counter = 5'd0;  // 位元計數器 (0-23)

   // 在每個 sck 週期更新 sd 值
   always @(posedge sck or posedge rst) begin
     if (rst) begin
       sd_pattern <= {24'haaaaaa, 24'hbbbbbb, 24'hcccccc, 24'hdddddd, 24'heeeeee, 24'hffffff, 24'h111111, 24'h222222};
       sd <= 8'h00;
       bit_counter <= 5'd0;
     end else begin
       // 只有在 ws=0 時才傳輸資料
       if (!ws) begin
         // 每個 ADC 接收對應 24 位資料的當前位元
         sd[0] <= sd_pattern[23 - bit_counter];      // ADC0: 0xaaaaaa 的位元
         sd[1] <= sd_pattern[47 - bit_counter];      // ADC1: 0xbbbbbb 的位元
         sd[2] <= sd_pattern[71 - bit_counter];      // ADC2: 0xcccccc 的位元
         sd[3] <= sd_pattern[95 - bit_counter];      // ADC3: 0xdddddd 的位元
         sd[4] <= sd_pattern[119 - bit_counter];     // ADC4: 0xeeeeee 的位元
         sd[5] <= sd_pattern[143 - bit_counter];     // ADC5: 0xffffff 的位元
         sd[6] <= sd_pattern[167 - bit_counter];     // ADC6: 0x111111 的位元
         sd[7] <= sd_pattern[191 - bit_counter];     // ADC7: 0x222222 的位元

         // 計數位元，但只在 ws=0 時計數
         if (bit_counter < 5'd23) begin
           bit_counter <= bit_counter + 5'd1;
         end else begin
           // 24位傳完後，保持 bit_counter=23，等待 ws=1 來重置
           bit_counter <= 5'd23;
         end
       end else begin
         // ws=1 時重置計數器，準備下一次傳輸
         bit_counter <= 5'd0;
         sd <= 8'h00;  // 可選：在 ws=1 時清除 sd
       end
     end
   end

  // =======================
  // 測試流程
  // =======================
  initial begin
    $display("[%0t] TB start", $time);

    // reset 拉高 32 個 sck 週期，確保所有暫存器初始化
    rst = 1'b1; start = 1'b0; S_AXIS_tready = 1'b0; sd = 8'h00;
    wait_sck(32);
    rst = 1'b0;
    wait_sck(16);

    // 啟動設計
    start = 1'b1;
    S_AXIS_tready = 1'b1;

    // 跑 300 週期，觀察正常輸出
    wait_sck(300);

    // 模擬 AXI 背壓：停 20 週期，再恢復
    S_AXIS_tready = 1'b0;
    wait_sck(20);
    S_AXIS_tready = 1'b1;
    wait_sck(300);

    $display("[%0t] TB done", $time);
    $finish;
  end

   // =======================
   // 觀察資料流
   // =======================
   initial begin
     $display("=== 資料流觀察 ===");
     forever begin
       @(posedge sck);
       if(S_AXIS_tvalid) begin
         $display("time=%8t ws=%b sd=%02h tdata[127:0]=%032h",
                 $time, ws, sd, S_AXIS_tdata[127:0]);
         $display("  data1=%08h data2=%08h data3=%08h data4=%08h",
                 dut.data[0], dut.data[1], dut.data[2], dut.data[3]);
         $display("  data5=%08h data6=%08h data7=%08h data8=%08h",
                 dut.data[4], dut.data[5], dut.data[6], dut.data[7]);
         $display("  flag_mux_to_adc=%02h flag_adc_to_mux=%02h",
                 flag_mux_to_adc, flag_adc_to_mux);
         $display("  ADC inputs: sd[0]=%b sd[1]=%b sd[2]=%b sd[3]=%b sd[4]=%b sd[5]=%b sd[6]=%b sd[7]=%b",
                 sd[0], sd[1], sd[2], sd[3], sd[4], sd[5], sd[6], sd[7]);
       end
     end
   end



  // Vivado 會自動生成 .wdb 波形檔，無需手動 dump
  // initial begin
  //   $dumpfile("wrapper_tb.vcd");
  //   $dumpvars(0, wrapper_tb);
  // end

endmodule
