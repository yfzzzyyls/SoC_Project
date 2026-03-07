module tb_bist_top;

localparam int ADDR_W = 6;
localparam int DATA_W = 8;

logic              clk;
logic              rst;
logic              start;
logic              csin;
logic              rwbarin;
logic              opr;
logic [ADDR_W-1:0] address;
logic [DATA_W-1:0] datain;
logic [DATA_W-1:0] dataout;
logic              fail;

int errors = 0;

mbist_top #(
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W)
) dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .csin(csin),
    .rwbarin(rwbarin),
    .opr(opr),
    .address(address),
    .datain(datain),
    .dataout(dataout),
    .fail(fail)
);

always #5 clk = ~clk;

task automatic check_data(
    input logic [DATA_W-1:0] exp,
    input string             tag
);
begin
    if (dataout !== exp) begin
        $display("FAIL [%s] t=%0t exp_data=%h got_data=%h", tag, $time, exp, dataout);
        errors++;
    end
end
endtask

task automatic check_fail(
    input logic exp,
    input string tag
);
begin
    if (fail !== exp) begin
        $display("FAIL [%s] t=%0t exp_fail=%b got_fail=%b", tag, $time, exp, fail);
        errors++;
    end
end
endtask

task automatic normal_write(
    input logic [ADDR_W-1:0] addr,
    input logic [DATA_W-1:0] data
);
begin
    csin    = 1'b1;
    rwbarin = 1'b0;
    address = addr;
    datain  = data;
    @(posedge clk);
    #1;
end
endtask

task automatic normal_read_and_check(
    input logic [ADDR_W-1:0] addr,
    input logic [DATA_W-1:0] exp,
    input string             tag
);
begin
    csin    = 1'b1;
    rwbarin = 1'b1;
    address = addr;
    @(posedge clk);
    #1;
    check_data(exp, tag);
end
endtask

initial begin
    // Init
    clk     = 1'b0;
    rst     = 1'b1;
    start   = 1'b0;
    csin    = 1'b0;
    rwbarin = 1'b1;
    opr     = 1'b1;
    address = '0;
    datain  = '0;
    errors  = 0;

    // Apply reset
    repeat (2) @(posedge clk);
    #1;
    rst = 1'b0;

    // ------------------------------------------------------------
    // 1) Normal SRAM mode sanity (NbarT=0 in RESET state)
    // ------------------------------------------------------------
    normal_write(6'd5, 8'hA6);
    check_data('0, "normal write drives dataout=0");

    normal_read_and_check(6'd5, 8'hA6, "normal read addr5");

    normal_write(6'd12, 8'h3C);
    normal_read_and_check(6'd12, 8'h3C, "normal read addr12");

    check_fail(1'b0, "fail remains low in normal mode");

    // ------------------------------------------------------------
    // 2) Start BIST and ensure no fail in clean run
    // Note: opr=0 gates fail during this check.
    // ------------------------------------------------------------
    opr = 1'b0;
    start = 1'b1;
    @(posedge clk);
    #1;
    start = 1'b0;

    // Wait until read phase begins (rwbar_int driven by counter[6])
    wait (dut.rwbar_int === 1'b1);

    // Observe several read cycles; fail should remain low
    repeat (80) begin
        @(posedge clk);
        #1;
        check_fail(1'b0, "clean BIST read phase");
    end

    // ------------------------------------------------------------
    // 3) Inject mismatch in read phase and expect fail assertion
    // ------------------------------------------------------------
    // Reset and restart to clear fail
    rst = 1'b1;
    repeat (2) @(posedge clk);
    #1;
    rst = 1'b0;

    opr   = 1'b1;
    start = 1'b1;
    @(posedge clk);
    #1;
    start = 1'b0;

    wait (dut.rwbar_int === 1'b1);

    // Force comparator mismatch for one clock to trigger fail flop
    force dut.eq = 1'b0;
    @(posedge clk);
    #1;
    release dut.eq;

    check_fail(1'b1, "fail asserted on mismatch in BIST read");

    if (errors == 0) begin
        $display("PASS");
    end else begin
        $display("FAIL errors=%0d", errors);
    end

    $finish;
end

endmodule
