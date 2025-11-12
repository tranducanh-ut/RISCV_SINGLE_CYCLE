<!-- Banner -->
<h1 align="center">⚡ RISC-V32I Single-Cycle CPU with Memory-Mapped I/O ⚡</h1>
<p align="center">
  <b>A Simple RISC-V RV32I Processor + Load-Store Unit + Peripherals</b><br>
  📅 Public: 2025 | 👤 Course / Personal Project
</p>

---

## 🌟 Overview
This project implements a **single-cycle RISC-V RV32I processor**, along with a **Load-Store Unit (LSU)** that interfaces with **memory-mapped peripherals** such as LEDs, switches, 7-segment (HEX) displays, and an LCD write register.

👉 **Supported instruction types (current state):**
- **R-type**: `ADD`, `SUB`, `AND`, `OR`, `SLT`, `SLL`, `SRL`, `SRA`
- **I-type**: `ADDI`, `ANDI`, `ORI`, `LW`
- **S-type**: `SW`
- **B-type**: conditional branches (`BEQ`, `BNE`, `BLT`, `BGE`, …)

> ⚠️ **Note:** Project is under active development. Some modules are implemented and tested; others are in progress.

---

## ⚡ Processor Design Style: Single-Cycle Architecture

The processor executes **an entire instruction in one clock cycle**, covering all 5 classical stages:

1. **IF** – Fetch instruction from program memory  
2. **ID** – Decode + Register File read  
3. **EX** – ALU performs arithmetic/logic  
4. **MEM** – Load/store via **Load-Store Unit (LSU)**  
5. **WB** – Write result back to registers
   <img width="1388" height="663" alt="image" src="https://github.com/user-attachments/assets/58c6bacd-eaad-44f1-aee2-7c00306eb926" />


### ✅ Advantages
| Feature | Description |
|--------|-------------|
| Simplicity | Control logic is straightforward |
| Easy Debugging | No pipeline hazards or forwarding logic |
| Predictable Timing | Each instruction takes exactly 1 clock cycle |
| Educational Value | Ideal for learning RISC-V datapath organization |

### ❌ Limitations
| Limitation | Description |
|-----------|-------------|
| Slow Clock | The longest instruction defines the cycle time |
| Low Performance | Only one instruction executes at a time |
| Poor Scalability | Adding new instructions increases clock period |
| Not Practical for Real CPUs | Modern CPUs always pipeline/fold units |

---

## 🧩 Load-Store Unit (LSU) + Memory-Mapped I/O

The **LSU** handles both:
- **data memory access** (internal RAM), and
- **I/O register access** (MMIO)
 <img width="800" height="368" alt="image" src="https://github.com/user-attachments/assets/9493cce0-df52-4632-b4c9-670b04923bd6" />


Peripherals are assigned fixed **base addresses**, allowing the CPU to control them using normal `LW`/`SW` instructions.

### 🗺️ LSU Memory Map (Key Regions)

| Base Address   | Top Address   | Mapping                         | Required |
|----------------|----------------|----------------------------------|----------|
| `0x0000_0000` | `0x0000_07FF` | 2KB Data Memory                 | ✅ |
| `0x1000_0000` | `0x1000_0FFF` | Red LEDs                        | ✅ |
| `0x1000_1000` | `0x1000_1FFF` | Green LEDs                      | ✅ |
| `0x1000_2000` | `0x1000_2FFF` | 7-Segment Displays (HEX)        | ✅ |
| `0x1000_4000` | `0x1000_4FFF` | LCD Display Register            | ✅ |
| `0x1001_0000` | `0x1001_0FFF` | Switch Input Registers          | ✅ |

💡 **Stores (`SW`)** to I/O addresses update outputs (LEDs, HEX, LCD).  
💡 **Loads (`LW`)** from I/O addresses read live inputs (switches).

---

## 🧠 Module Overview (Verilog)

> Sources: `alu.v`, `brc.v`, `controller.v`, `ImmGen.v`, `lsu.v`, `mem.v`, `regfile.v`, `riscv_top.v`

- **`alu.v`** – Arithmetic/Logic Unit supporting add/sub, logic ops, shifts, and set-less-than variants.
- **`brc.v`** – Branch comparator (signed/unsigned) generating equality/less-than flags.
- **`controller.v`** – Instruction decoder + control signal generation (ALU op select, PC select, WB mux, Mem write enable, etc.).
- **`ImmGen.v`** – Immediate generator for I/S/B/U/J formats (RISC-V RV32I).
- **`regfile.v`** – 32×32 register file; **x0 hard-wired to zero** (read as 0, writes to x0 ignored).
- **`mem.v`** – Instruction memory with `$readmemh` for program initialization.
- **`lsu.v`** – Data RAM and MMIO address decode; drives LED/HEX/LCD outputs and reads Switches.
- **`riscv_top.v`** – Top-level integration: PC, IMEM, Controller, ALU, RegFile, ImmGen, Branch, and LSU.

---

## 🚀 Getting Started

### 1) Build / Simulate
Use your preferred simulator (ModelSim/Questa, Icarus, Verilator, Xilinx simulator).  
For FPGA, map top-level I/O to your board (LEDs, HEX, switches, LCD).

### 2) Program Initialization
- Place your machine code in **hex** and load via `$readmemh` in `mem.v`.
- Ensure the path is valid for your toolchain/workspace.

### 3) Try the Peripherals
- **LEDs**: `SW` a 32-bit word to RED (`0x1000_0000..0x1000_0FFF`) or GREEN (`0x1000_1000..0x1000_1FFF`).
- **HEX**: `SW` packed 7-seg patterns to `0x1000_2000..0x1000_2FFF`.
- **LCD**: `SW` the 32-bit value to `0x1000_4000..0x1000_4FFF`.
- **Switches**: `LW` from `0x1001_0000..0x1001_0FFF`.

---

## ✅ Status
- Core datapath + control: **Working** (subset RV32I as listed)
- LSU MMIO: **Working** for LEDs/HEX/LCD + Switch read
- IMEM: **Working** via `$readmemh`

---

## 🛠️ Limitations & TODO
- **Load/store variants**: only word `LW/SW` currently; `LB/LH/LBU/LHU/SB/SH` not fully implemented.
- **Exceptions/Alignment**: no trap/exception; unaligned access unsupported.
- **Timing**: single-cycle → low Fmax; consider simple pipeline in future.
- **Tooling**: ensure `$readmemh` uses a project-relative path.

---

## 🧪 Tutorial: Run the Testbench in `testAPP`

# ================================================================
# run_sim.tcl — TCL to run XSim (Vivado) with inline instructions
# ================================================================
# USAGE (Windows):
#   1) Open CMD in the folder that contains "sim_work\" (or use Vivado Tcl Console)
#   2) Run:  vivado -mode batch -source run_sim.tcl
#
# GOAL:
#   - Point to the RTL/testbench directory (SRC_DIR)
#   - List the .v files you want to compile (FILES)
#   - Compile (xvlog) → Elaborate (xelab) → Run (xsim)
#   - Testbench writes its log to ../regtrace.txt (if TB opens "../regtrace.txt")
#
# QUICK CUSTOMIZATION:
#   - Switch SRC_DIR to an ABSOLUTE path:  set SRC_DIR "I:/testAPP"
#   - Add/remove .v files in FILES
#   - Change TOP (testbench module name): set TOP tb_regtrace
# ================================================================

# --------- 1) CONFIGURE SOURCE DIRECTORY & BUILD TARGET ---------

# Directory of this script (run_sim.tcl)
set SCRIPT_DIR [file normalize [file dirname [info script]]]

# DEFAULT: source RTL lives one level above this script (../)
# => If run_sim.tcl is in "testAPP/sim_work", then SRC_DIR = "testAPP"
set SRC_DIR [file normalize [file join $SCRIPT_DIR ..]]

# ALTERNATIVE: use an ABSOLUTE PATH (RECOMMENDED for clarity/stability)
# set SRC_DIR "I:/testAPP"

# Testbench top module name
set TOP tb_regtrace

# List of .v files to compile (ADD/REMOVE HERE)
set FILES {
  riscv_top.v
  regfile.v
  mem.v
  alu.v
  brc.v
  controller.v
  ImmGen.v
  lsu.v
  tb_regtrace.v
}

# --------- 2) MAKE ABSOLUTE PATHS & VERIFY EXISTENCE ---------

set ABS_FILES {}
foreach f $FILES {
  set absf [file normalize [file join $SRC_DIR $f]]
  if {![file exists $absf]} {
    puts "ERROR: File not found: $absf"
    puts "Please verify SRC_DIR or filenames in FILES."
    exit 1
  }
  lappend ABS_FILES $absf
}

puts "===> SRC_DIR = $SRC_DIR"
puts "===> TOP     = $TOP"
puts "===> FILES:"
foreach f $ABS_FILES { puts "     - $f" }

# --------- 3) CLEAN PREVIOUS RUN ARTIFACTS ---------

file delete -force xsim.dir .Xil

# --------- 4) COMPILE (xvlog) ---------

puts ">> xvlog ..."
# --incr: incremental compile; --relax: relax some constraints
# Use {*}$ABS_FILES to splat the list into arguments
exec xvlog --incr --relax {*}$ABS_FILES

# --------- 5) ELABORATE (xelab) ---------

puts ">> xelab ..."
# Snapshot name is TOP + "_sim"
set SNAP "${TOP}_sim"
exec xelab $TOP -s $SNAP

# --------- 6) RUN SIMULATION (xsim) ---------

puts ">> xsim -R ..."
exec xsim $SNAP -R

puts "Simulation DONE."

# --------- 7) NOTE ABOUT LOG LOCATION (IF NEEDED) ---------
# If the testbench opens "../regtrace.txt" (from sim_work), the log will be here:
set EXPECT_LOG [file normalize [file join $SRC_DIR regtrace.txt]]
puts "If TB uses ../regtrace.txt, expected log file: $EXPECT_LOG"

# ================================================================
# NOTES:
# - TO ADD A FILE: append its name in FILES above. Example:
#     set FILES { riscv_top.v regfile.v mem.v alu.v my_new_module.v tb_regtrace.v }
# - TO USE AN ABSOLUTE SOURCE PATH: set SRC_DIR "I:/path/to/your/sources"
# - TO CHANGE TESTBENCH: set TOP <your_tb_module_name>
# - If Vivado cannot find files: verify SRC_DIR and FILES
# - If INSTR shows xxxxxxxx in the log: check $readmemh("mem.h", mem) and the mem.h location
# ================================================================
