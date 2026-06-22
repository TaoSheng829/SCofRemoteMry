losed‑Loop Coherence Detection System
Real‑time Theta & Gamma Closed‑Loop Stimulation Control
Patent Pending / Protected – Chinese Patent Application No. ZL 2021 1 1254993.1

This repository contains the MATLAB source code (provided in a non‑editable compiled/protected format) for two real‑time closed‑loop systems that detect neural coherence in the theta or gamma frequency bands using a Plexon data acquisition system. Upon crossing a predefined threshold, the system triggers a digital output (e.g., LED or TTL pulse) with a random delay, enabling closed‑loop stimulation experiments.

Overview
Two independent scripts are included:

Script	Frequency Band	Channels	Coherence Band	Threshold File	Default p
main_thetaCL.m	Theta (≈4–8 Hz)	48 selected	Low gamma (first 4 freq. bins)	Tos_th.mat	280
main_GammaCL.m	Gamma (≈30–80 Hz)	64 selected	Low gamma (first 16 freq. bins)	Gos_th.mat	384
Both scripts share the same core architecture:

Continuous A/D streaming from Plexon.

Multi‑taper coherence estimation (Chronux toolbox).

GPU‑accelerated FFT for real‑time performance.

Conditional triggering with random delay and pulse generation.

Important Patent Notice
This software is protected under Chinese Patent No. ZL 2021 1 1254993.1.
The source code is provided in a non‑editable format (e.g., P‑code or encrypted MATLAB files) to protect intellectual property. You may run the code for research or evaluation purposes, but you may not modify, reverse‑engineer, or redistribute the protected portions. Any use beyond personal research requires explicit permission from the patent holder.

If you are a collaborator and need to adjust parameters, please refer to the configuration section below – these parameters remain accessible even in the protected version.

Dependencies
MATLAB (R2016b or later) with Parallel Computing Toolbox (for GPU support).

Plexon SDK – provides the mexPlex and PlexDO interface functions (PL_InitClient, PL_GetAD, PL_DOSetBit, etc.).
Available from Plexon Support.

Chronux Toolbox – provides spectral analysis functions (dpsschk, getfgrid, getparams).
Download from chronux.org.

A compatible NVIDIA GPU is recommended for real‑time performance.

File Structure
main_thetaCL.m / main_GammaCL.m – protected main scripts (non‑editable).

Tos_th.mat – threshold values for theta version (LG_th, HG_th, MG_th).

Gos_th.mat – threshold values for gamma version.

matlab_theta.mat – Chronux parameters for theta version.

matlab_gamma.mat – Chronux parameters for gamma version.

README.md – this document.

Configuration Parameters
Even though the core code is protected, the following parameters are user‑configurable (via the load statements or directly in the script’s header):

Variable	Description
p	Number of frequency bins that must exceed the threshold to trigger a response.
*_th	Threshold values loaded from Tos_th.mat or Gos_th.mat (only LG_th is used in both scripts by default).
coh_params	Chronux configuration structure (loaded from matlab_*.mat).
You can also adjust:

Digital output bit numbers (lines near PL_DOSetBit calls).

Pulse durations and delays (e.g., 10 ms, 400 ms, and random delay range 100–300 ms).

Running the Program
Hardware: Ensure the Plexon server is running and the A/D device is correctly configured.

Path: Add the Plexon SDK and Chronux toolbox folders to your MATLAB path.

Data files must be placed in the expected directories (default paths):

Tos_th.mat → D:\wy\20200509_closedloop-v4.0\Tos_th.mat

Gos_th.mat → D:\wy\20200509_closedloop-v4.0\Gos_th.mat

matlab_theta.mat / matlab_gamma.mat → current working directory.
(Modify the load paths if your directory structure differs.)

Choose the appropriate script for your experiment (theta or gamma) and run it:

matlab
main_thetaCL   % for theta detection
main_GammaCL   % for gamma detection
To stop the loop, press Ctrl+C in the MATLAB console. The script will release all Plexon devices upon termination.

Algorithm (Both Scripts)
Connect to Plexon server, identify sampling rate, and initialize digital output.

Stream data from selected channels (48 for theta, 64 for gamma).

Segment the data into two halves of length Fs*0.5 samples.

Apply 9 DPSS tapers to each half and compute FFT.

Compute coherence spectrum between the two halves.

Average coherence across the low‑gamma frequency band (first 4 bins for theta, first 16 bins for gamma).

If the number of bins exceeding the threshold (LG_th) is ≥ p, trigger a stimulation event:

Set bit 2 (random‑delay mark) for 10 ms.

Wait a random delay (100–300 ms).

Set bit 1 (CL light) for 400 ms.

The loop maintains a ~10 Hz cycle (100 ms per iteration) with timing control.

Differences Between Theta and Gamma Versions
Feature	main_thetaCL	main_GammaCL
Channel count	48	64
Channel mapping	[1‑20, 21‑32, 49‑64] (with offset 128)	[33‑48, 1‑32, 49‑64] (with offset 128)
Coherence band width	4 frequency bins	16 frequency bins
Threshold file	Tos_th.mat	Gos_th.mat
Default p	280	384
Artifact safeguard threshold	mean(mean(C_new)) > 0.9	mean(mean(C_new)) > 0.5
Note: Both scripts currently only use LG_th for triggering; MG_th and HG_th are present but commented out.

Troubleshooting
PL_InitClient returns 0: Plexon server not running or connection failed.

Missing functions: Verify that Plexon SDK and Chronux are correctly added to the MATLAB path.

GPU out of memory: Consider reducing the number of tapers or FFT length, or switch to CPU processing (requires code modification, which is not allowed in protected version – contact the developer if needed).

Timing accuracy: The while loop may cause high CPU usage; adjust the tolerance or switch to a timer‑based approach if required (again, requires developer intervention).

Licensing & Disclaimer
This software is provided as‑is for academic and research use under the protection of the mentioned patent.
No warranty is provided for fitness for any particular purpose.
Commercial use or redistribution without explicit permission is prohibited.

For collaboration or licensing inquiries, please contact the patent holder directly.

Author Information
This code was developed as part of closed‑loop neuromodulation research.
For questions regarding the algorithm or experimental setup, refer to the original laboratory documentation.

Version: 1.0