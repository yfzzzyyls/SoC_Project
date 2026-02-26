
module tb_controller;

logic clk;
logic rst;
logic start;
logic cout;
logic NbarT;
logic ld;

int errors = 0;

controller dut_controller (
    .clk(clk),
    .rst(rst),
    .start(start),
    .cout(cout),
    .NbarT(NbarT),
    .ld(ld)
);

always #5 clk = ~clk;

task automatic check_outputs(
    input logic exp_NbarT,
    input logic exp_ld,
    input string tag
);
begin
    if ((NbarT !== exp_NbarT) || (ld !== exp_ld)) begin
        $display("FAIL [%s] t=%0t exp(NbarT,ld)=%b,%b got=%b,%b",
                 tag, $time, exp_NbarT, exp_ld, NbarT, ld);
        errors++;
    end
end
endtask

initial begin
    // Init
    clk   = 1'b0;
    rst   = 1'b1;
    start = 1'b0;
    cout  = 1'b0;
    errors = 0;

    // Reset should force RESET state on clock edge => NbarT=0, ld=1
    @(posedge clk);
    #1;
    check_outputs(1'b0, 1'b1, "after reset");

    // Deassert reset, remain in RESET while start=0
    rst = 1'b0;
    @(posedge clk);
    #1;
    check_outputs(1'b0, 1'b1, "hold RESET when start=0");

    // Drive start=1, transition RESET->TEST on next edge
    start = 1'b1;
    @(posedge clk);
    #1;
    check_outputs(1'b1, 1'b0, "enter TEST when start=1");

    // In TEST with cout=0, stay TEST
    start = 1'b0; // don't-care in TEST for this FSM
    cout  = 1'b0;
    @(posedge clk);
    #1;
    check_outputs(1'b1, 1'b0, "stay TEST when cout=0");

    // In TEST with cout=1, transition TEST->RESET
    cout = 1'b1;
    @(posedge clk);
    #1;
    check_outputs(1'b0, 1'b1, "return RESET when cout=1");

    // Back in RESET, start=0 should hold RESET
    cout  = 1'b0;
    start = 1'b0;
    @(posedge clk);
    #1;
    check_outputs(1'b0, 1'b1, "hold RESET again");

    if (errors == 0) begin
        $display("PASS");
    end else begin
        $display("FAIL errors=%0d", errors);
    end
    $finish;
end

endmodule
