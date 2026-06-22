# SCofRemoteMry
Analysis Scripts and Software Resources Overview

This repository offers complete code to replicate and regenerate analyses and figures reported in the paper“Hippocampal-cortical coupling dynamics drive system consolidation of remote memory”

This repository contains scripts and software tools used in our study to process electrophysiological and behavioral data, perform coherence-based closed-loop optogenetic intervention

We utilized existing open‑source toolboxes packages in various parts of the pipeline, including:

Chronux Toolbox – for spectral and coherence analyses

Buzcode – for hippocampal spike sorting and LFP processing

AccuSleep – for automatic sleep stage classification

Dependencies

MATLAB
All MATLAB analysis scripts require:
MATLAB base environment (R2021b or later recommended)

Signal Processing Toolbox – for filtering, spectral estimation, and cross‑correlation

Statistics and Machine Learning Toolbox – for hypothesis testing, clustering, and PCA

Image Processing Toolbox – used only if processing calcium imaging data (not covered in this study)

Chronux Toolbox – specifically for multi‑taper spectral and coherence analysis

Note: The closed‑loop intervention code (custom) depends on the Plexon OmniPlex API (via plexon32.dll) for real‑time neural data streaming and TTL output to the Master‑9 stimulator.

External Software

OmniPlex Software (Plexon Inc.) – used for acquiring multi‑channel neural signals and synchronizing behavioral video; provides the interface for online data access.

Offline Sorter (Plexon Inc.) – manual and automated spike sorting (version x64 V4).

NeuroExplorer 5 x64 – for perievent time histograms (PSTH), interspike interval (ISI) analyses, and raster plots.

Freeze Frame 4 – automated scoring of freezing behavior (threshold‑based motion detection).

GraphPad Prism 8.0.2 – used for generating final statistical plots (bar graphs, scatter, survival curves).

ImageJ 1.47v – only for verifying optrode tip positions from histology images.

MouseOx Plus – pulse oximetry for monitoring physiological status during surgery.

