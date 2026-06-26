module washing_machine(
    input clk, reset,
    input door_close, start, filled, detergent_added,
    input cycle_timeout, drained, spin_timeout,
    output reg door_lock, motor_on, fill_valve_on,
    output reg drain_valve_on, done, soap_wash, water_wash
);

parameter check_door    = 3'b000;
parameter fill_water    = 3'b001;
parameter add_detergent = 3'b010;
parameter cycle_state   = 3'b011;
parameter drain_water   = 3'b100;
parameter spin          = 3'b101;

reg [2:0] current_state, next_state;
reg soap_done;

// combinational block
always @(*) begin
    next_state     = check_door;
    door_lock      = 0;
    motor_on       = 0;
    fill_valve_on  = 0;
    drain_valve_on = 0;
    soap_wash      = 0;
    water_wash     = 0;
    done           = 0;

    case(current_state)
        check_door: begin
            if(start && door_close) begin
                next_state = fill_water;
                door_lock  = 1;
            end else begin
                next_state = check_door;
                door_lock  = 0;
            end
        end

        fill_water: begin
            door_lock = 1;
            if(filled) begin
                if(!soap_done) begin
                    next_state = add_detergent;
                    soap_wash  = 1;
                    water_wash = 0;
                end else begin
                    next_state = cycle_state;
                    soap_wash  = 0;
                    water_wash = 1;
                end
            end else begin
                next_state    = fill_water;
                fill_valve_on = 1;
                soap_wash     = !soap_done;
                water_wash    =  soap_done;
            end
        end

        add_detergent: begin
            door_lock  = 1;
            soap_wash  = 1;
            water_wash = 0;
            if(detergent_added)
                next_state = cycle_state;
            else
                next_state = add_detergent;
        end

        cycle_state: begin
            door_lock  = 1;
            soap_wash  = !soap_done;
            water_wash =  soap_done;
            if(cycle_timeout) begin
                next_state = drain_water;
                motor_on   = 0;
            end else begin
                next_state = cycle_state;
                motor_on   = 1;
            end
        end

        drain_water: begin
            door_lock  = 1;
            soap_wash  = !soap_done;
            water_wash =  soap_done;
            if(drained) begin
                drain_valve_on = 0;
                if(!soap_done)
                    next_state = fill_water;
                else
                    next_state = spin;
            end else begin
                next_state     = drain_water;
                drain_valve_on = 1;
            end
        end

        spin: begin
            door_lock  = 1;
            soap_wash  = 0;
            water_wash = 1;
            if(spin_timeout) begin
                next_state     = check_door;
                done           = 1;
                door_lock      = 0;
                drain_valve_on = 0;
            end else begin
                next_state     = spin;
                drain_valve_on = 1;
            end
        end

        default: next_state = check_door;
    endcase
end


always @(posedge clk or posedge reset) begin
    if(reset) begin
        current_state <= check_door;
        soap_done     <= 1'b0;      // clear on reset
    end else begin
        current_state <= next_state;

        // set soap_done when transitioning OUT of drain_water (first drain)
        if(current_state == drain_water && drained && !soap_done)
            soap_done <= 1'b1;

        // clear soap_done when transitioning OUT of spin (use next_state)
        if(next_state == check_door && current_state == spin)
            soap_done <= 1'b0;
    end
end

endmodule
