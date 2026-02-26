module tb_sram;

localparam int ADDR_WIDTH = 6;
localparam int DATA_WIDTH = 8;

logic                   clk;
logic [ADDR_WIDTH-1:0]  ramaddr;
logic [DATA_WIDTH-1:0]  ramin;
logic                   cs;
logic                   rwbar;
logic [DATA_WIDTH-1:0]  ramout;

int errors = 0;

sram #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) dut_sram (
    .clk(clk),
    .ramaddr(ramaddr),
    .ramin(ramin),
    .cs(cs),
    .rwbar(rwbar),
    .ramout(ramout)
);

always #5 clk = ~clk;

task automatic check_ramout(
    input logic [DATA_WIDTH-1:0] exp,
    input string                 tag
);
begin
    if (ramout !== exp) begin
        $display("FAIL [%s] t=%0t exp=%h got=%h", tag, $time, exp, ramout);
        errors++;
    end
end
endtask

task automatic do_write(
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data
);
begin
    cs      = 1'b1;
    rwbar   = 1'b0;
    ramaddr = addr;
    ramin   = data;
    @(posedge clk);
    #1;
end
endtask

initial begin
    // init
    clk     = 1'b0;
    ramaddr = '0;
    ramin   = '0;
    cs      = 1'b0;
    rwbar   = 1'b1;
    errors  = 0;

    #1;
    check_ramout('0, "idle cs=0 -> ramout=0");

    // Write addr 3 = A5
    do_write(6'd3, 8'hA5);
    check_ramout('0, "write mode -> ramout=0");

    // Read back addr 3 (addr_reg is already 3 from write edge)
    rwbar = 1'b1;
    #1;
    check_ramout(8'hA5, "read addr3");

    // Write addr 7 = 3C
    do_write(6'd7, 8'h3C);
    rwbar = 1'b1;
    #1;
    check_ramout(8'h3C, "read addr7");

    // Address-latch behavior: ramaddr changes without clock should not change read address
    ramaddr = 6'd3;
    #1;
    check_ramout(8'h3C, "still reads latched addr7 before next edge");

    // Latch new read address on next posedge (cs=1)
    @(posedge clk);
    #1;
    check_ramout(8'hA5, "after edge, reads addr3");

    // cs low forces ramout=0
    cs    = 1'b0;
    rwbar = 1'b1;
    #1;
    check_ramout('0, "cs low -> ramout=0");

    // Write attempt when cs=0 should not modify memory
    rwbar   = 1'b0;
    ramaddr = 6'd3;
    ramin   = 8'hFF;
    @(posedge clk);
    #1;

    // Re-enable cs and read addr3; should still be A5
    cs      = 1'b1;
    rwbar   = 1'b1;
    ramaddr = 6'd3;
    @(posedge clk);
    #1;
    check_ramout(8'hA5, "cs=0 blocked write");

    if (errors == 0) begin
        $display("PASS");
    end else begin
        $display("FAIL errors=%0d", errors);
    end
    $finish;
end

endmodule
