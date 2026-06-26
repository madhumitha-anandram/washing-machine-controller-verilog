`timescale 1ns/1ps
module washing_machine_tb();

reg clk, reset;
reg door_close, start, filled, detergent_added;
reg cycle_timeout, drained, spin_timeout;

wire door_lock, motor_on, fill_valve_on;
wire drain_valve_on, done, soap_wash, water_wash;

washing_machine dut(
    .clk(clk),
    .reset(reset),
    .door_close(door_close),
    .start(start),
    .filled(filled),
    .detergent_added(detergent_added),
    .cycle_timeout(cycle_timeout),
    .drained(drained),
    .spin_timeout(spin_timeout),
    .door_lock(door_lock),
    .motor_on(motor_on),
    .fill_valve_on(fill_valve_on),
    .drain_valve_on(drain_valve_on),
    .done(done),
    .soap_wash(soap_wash),
    .water_wash(water_wash)
);

initial clk = 0;
always #5 clk = ~clk;

initial begin
    $dumpfile("washing_machine_tb.vcd");
    $dumpvars(0, washing_machine_tb);
end

initial begin
    $monitor("T=%0t | door_lock=%b motor=%b fill=%b drain=%b soap=%b water=%b done=%b",
              $time, door_lock, motor_on, fill_valve_on, drain_valve_on,
              soap_wash, water_wash, done);
end

initial begin
    // initialize ALL inputs to 0
    reset           = 1;
    door_close      = 0;
    start           = 0;
    filled          = 0;
    detergent_added = 0;
    cycle_timeout   = 0;
    drained         = 0;
    spin_timeout    = 0;

    #30; reset = 0; #10;

    // -------------------------------------------------------
    // TEST 1: door open, start pressed ? stay CHECK_DOOR
    // -------------------------------------------------------
    $display("\n--- TEST 1: door open, start=1 ---");
    start = 1; door_close = 0;
    #30;
    $display("Expected: door_lock=0, stay CHECK_DOOR");

    // -------------------------------------------------------
    // TEST 2: full wash cycle
    // -------------------------------------------------------
    $display("\n--- TEST 2: door closed, start wash ---");
    door_close = 1;
    #10;

    // FILL WATER (soap cycle)
    $display("--- FILL WATER (soap) ---");
    #30; filled = 1; #10; filled = 0;

    // ADD DETERGENT
    $display("--- ADD DETERGENT ---");
    #20; detergent_added = 1; #10; detergent_added = 0;

    // CYCLE (soap wash)
    $display("--- CYCLE soap wash ---");
    #40; cycle_timeout = 1; #10; cycle_timeout = 0;

    // DRAIN (first)
    $display("--- DRAIN WATER first ---");
    #30; drained = 1; #10; drained = 0;

    // FILL WATER (rinse cycle)
    $display("--- FILL WATER (rinse) ---");
    #30; filled = 1; #10; filled = 0;

    // CYCLE (rinse)
    $display("--- CYCLE rinse ---");
    #40; cycle_timeout = 1; #10; cycle_timeout = 0;

    // DRAIN (second)
    $display("--- DRAIN WATER second ---");
    #30; drained = 1; #10; drained = 0;

    // SPIN
    $display("--- SPIN ---");
    #40; spin_timeout = 1; #10; spin_timeout = 0;

    // *** CRITICAL FIX: clear start and door_close after wash done ***
    start      = 0;
    door_close = 0;

    #30;
    $display("--- FINAL STATE: Expected CHECK_DOOR, door_lock=0, done=0 ---");

    // -------------------------------------------------------
    // TEST 3: reset mid-cycle
    // -------------------------------------------------------
    $display("\n--- TEST 3: reset mid-cycle ---");
    start = 1; door_close = 1; #10;
    filled = 1;            #10; filled = 0;
    detergent_added = 1;   #10; detergent_added = 0;

    // assert reset while in cycle state
    reset = 1;
    #20;
    reset = 0;
    start = 0;      // clear start after reset
    door_close = 0; // clear door_close after reset
    #30;
    $display("Expected: CHECK_DOOR, door_lock=0 after reset");

    $display("\n--- SIMULATION COMPLETE ---");
    #20; $finish;
end

endmodule
