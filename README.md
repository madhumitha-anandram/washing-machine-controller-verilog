## What this project does

A complete washing machine controller that sequences through all real washing stages automatically. The FSM manages door locking, water fill, detergent addition, wash cycles, draining, and spin — exactly as a real washing machine does.

The washing cycle

CHECK_DOOR → FILL_WATER → ADD_DETERGENT → CYCLE (wash) → DRAIN_WATER

↑                                               |

└───── (if soap wash not done yet) ────────────┘

↓ (if soap done)

SPIN → done

The machine runs two wash cycles: first with soap (soap wash), then a clean rinse (water wash). The soap_done flag stored in a register tracks which wash is happening.

States and what each does

| State | Encoding | What happens | Outputs active |
| --- | --- | --- | --- |
| CHECK_DOOR | 3'b000 | Waits for start AND door_close | — |
| FILL_WATER | 3'b001 | Opens fill valve until filled signal | fill_valve_on, door_lock |
| ADD_DETERGENT | 3'b010 | Waits for detergent_added signal | door_lock, soap_wash |
| CYCLE_STATE | 3'b011 | Runs motor until cycle_timeout | motor_on, door_lock |
| DRAIN_WATER | 3'b100 | Opens drain valve until drained | drain_valve_on, door_lock |
| SPIN | 3'b101 | Spins drum until spin_timeout | drain_valve_on, door_lock |

The soap_done flag — how the two-cycle logic works

soap_done is a 1-bit register. It starts at 0 (soap wash not done). After the first drain completes, it is set to 1. The FSM uses this flag in FILL_WATER and DRAIN_WATER to decide whether to loop back for the rinse cycle or move forward to spin.

First run:  FILL → DETERGENT → CYCLE → DRAIN (soap_done set to 1) → back to FILL

Second run: FILL → CYCLE → DRAIN → SPIN → done (soap_done cleared)

## Inputs and outputs

| Signal | Direction | Meaning |
| --- | --- | --- |
| door_close | input | Door closed sensor |
| start | input | Start button |
| filled | input | Water level sensor |
| detergent_added | input | Detergent dispenser sensor |
| cycle_timeout | input | Wash timer expired |
| drained | input | Water fully drained |
| spin_timeout | input | Spin timer expired |
| door_lock | output | Lock solenoid |
| motor_on | output | Drum motor |
| fill_valve_on | output | Water inlet valve |
| drain_valve_on | output | Drain pump |
| soap_wash | output | Indicates soap-wash phase |
| water_wash | output | Indicates rinse phase |
| done | output | Cycle complete |

## File structure

washing_machine.v      — Full FSM with soap_done register logic

washing_machine_tb.v   — Testbench driving all sensor signals through a complete cycle
