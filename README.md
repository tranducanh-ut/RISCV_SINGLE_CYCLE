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

This testbench logs **register updates** to `regtrace.txt` (per cycle). The TB writes to `../regtrace.txt`, so with the scripts below you’ll get **`testAPP/regtrace.txt`** after the run.

### 📁 Minimal Folder Layout
testAPP/
├─ alu.v
├─ brc.v
├─ controller.v
├─ ImmGen.v
├─ lsu.v
├─ mem.v # $readmemh("mem.h")
├─ regfile.v
├─ riscv_top.v
├─ tb_regtrace.v # testbench (writes ../regtrace.txt)
├─ mem.h # program hex for $readmemh
├─ run_sim.tcl # Vivado batch script
└─ run_trace.bat # one-click batch

markdown
Copy code

> 🔗 In `mem.v`, ensure you load program hex from the same folder:
> ```verilog
> initial begin
>   $readmemh("mem.h", mem);
> end
> ```

### ▶️ One-Click (Recommended)

1. Open **CMD** in `testAPP/`
2. Run:
   ```bat
   run_trace.bat
After the simulation, open:
testAPP/regtrace.txt

If Vivado isn’t at the default location, edit the path at the top of run_trace.bat:

bat
Copy code
set VIVADO_BAT="C:\Xilinx\Vivado\2024.2\bin\vivado.bat"
▶️ Manual Run (Vivado Tcl / CMD)
tcl
Copy code
cd testAPP/sim_work
vivado -mode batch -source ../run_sim.tcl
Result file: ../regtrace.txt → testAPP/regtrace.txt.

📜 run_sim.tcl (reference)
tcl
Copy code
# run_sim.tcl — build & run XSim
file delete -force xsim.dir .Xil

puts ">> xvlog ..."
exec xvlog --incr --relax  ../riscv_top.v  ../regfile.v  ../mem.v  ../alu.v  ../brc.v  ../controller.v  ../ImmGen.v  ../lsu.v  ../tb_regtrace.v

puts ">> xelab ..."
exec xelab tb_regtrace -s tb_regtrace_sim

puts ">> xsim -R ..."
exec xsim tb_regtrace_sim -R

puts "Simulation DONE."
📌 The script assumes the working directory is testAPP/sim_work.
The TB opens "../regtrace.txt" so the log lands in testAPP/.

🧯 Troubleshooting
No regtrace.txt generated

Make sure you ran from testAPP/sim_work/ (for the Tcl script), or used run_trace.bat.

Increase MAX_CYCLES in tb_regtrace.v if your program is longer.

Check write permissions.

xxxxxxxx for INSTR (can’t fetch)

Wrong $readmemh path or missing/invalid mem.h.

PC index out of range vs. mem[] depth (i_addr[31:2] bounds).

Instruction & register update appear off by one line

If you’re using the “pipeline-delay TB” (Cách B), tune PIPE_DELAY (e.g., 4 for classic 5-stage).
If still off by one, try ±1.

Vivado cannot find .v sources

run_sim.tcl references files with ../ (one level up from sim_work/). Keep the folder layout.

✅ Current Status
Core datapath + control: Working (subset RV32I as listed)

LSU MMIO: Working for LEDs/HEX/LCD + Switch read

IMEM/DataMem: Working via $readmemh

🛠️ Roadmap
Add LB/LH/LBU/LHU/SB/SH

Basic exception / unaligned access handling

Optional 2–5 stage pipeline (higher Fmax)

Expose WB-trace ports from top for perfect commit logging in TB
