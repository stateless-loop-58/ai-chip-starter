# AI Chip Starter
Starter baseline for an AI chip hackathon.

- This repo provides a starter Verilog implementation of matrix multiplication and a simple Python-based neural network that runs on it.
- This baseline is optional for the AI chip hackathon. If you already have your own hardware architecture, feel free to ignore this template and use your custom design instead.
- Note that hardware acceleration performance is not guaranteed, as this repository serves only as a starter baseline. 

# Quantization

For symmetric scale-based quantization, we represent an FP32
value using an INT8 integer plus a scale.

### 1. Calculate the quantization scale

Given an FP32 tensor x:

&emsp; $S = \frac{\max(|x|)}{127}$

where:

- $S$ = quantization scale
- $max(|x|)$ = maximum absolute FP32 value
- $127$ = maximum positive INT8 value

### 2. Quantize FP32 → INT8

To quantize FP32 value to INT8:

&emsp; $x_{int8} = \text{clip}(\text{round}(\frac{x_{fp32}}{S}), -128, 127)$

### 3. Dequantize INT8 → FP32

To approximately recover the original FP32 value:

&emsp; $x_{fp32} \approx x_{int8} × S$

### Example

Suppose the FP32 tensor has values between:

&emsp; $-2.0$ and $+2.0$

Then:

&emsp; $S = 2.0 / 127 \approx 0.01575$

For an FP32 value:

&emsp; $x = 1.0$

Quantization:

&emsp; $x_{int8} = round(1.0 / 0.01575) \approx 64$

Dequantization:

&emsp; $x_{fp32} \approx 64 × 0.01575 \approx 1.008$

There is a small quantization error:

&emsp; $error = |1.0 - 1.008| \approx 0.008$

# FPGA Matrix Multiplication

This repo features a 4x4 systolic matrix multiplication engine integrated with an ARM CPU and accessible via Python. It includes block matrix multiplication to handle matrices larger than 4x4. The matrix multiplication uses INT8 for inputs and INT32 for accumulation.

<img src="https://github.com/stateless-loop-58/ai-chip-starter/blob/main/image/system_fpga.jpg" width="600" />