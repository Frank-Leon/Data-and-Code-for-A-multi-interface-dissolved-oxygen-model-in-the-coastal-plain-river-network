# Data-and-Code-for-A-multi-interface-dissolved-oxygen-model-in-the-coastal-plain-river-network
This repository contains the datasets and Python scripts supporting the findings of the paper: "A multi-interface dissolved oxygen model development for the rivers controlled by gates in the coastal plain river network: An empirical analysis in Jinhuigang River, Shanghai".
# Description of Files
1. Data
Measured cross-sectional data of key sections (CS1-CS3).xls: This file contains the actual measured topographic data for the three key river cross-sections (CS1, CS2, and CS3) investigated in this study.

2. Dissolved oxygen and flux calculation code (Python)
main_do.py: The core script for DO calculation. It takes the corresponding hydrodynamic data and relevant sediment property indicators as inputs to compute the temporal variations of Dissolved Oxygen (DO) at the specific monitoring points.

main_wai_fluxes.py: A dedicated script to calculate the mass transfer fluxes across the Water-Air Interface (WAI).

main_wsi-fluxes.py: A dedicated script to calculate the oxygen consumption fluxes across the Water-Sediment Interface (WSI), specifically focusing on sediment oxygen demand (SOD) under resuspension conditions.

3. Plotting scripts (R)
This folder contains the R scripts used to generate the core high-resolution figures presented in the manuscript:

Total oxygen demand.R: Script to visualize the total oxygen demand results.

scatter_plot.R: Script for generating scatter plots (e.g., the relationship between the equivalent bulk thickness of resuspended sediment and SOD).

plot_heat_map.R: Script to plot the spatiotemporal heat maps of the calculated fluxes or DO variations.

DO depletion.R: Script to visualize the DO depletion processes over time.

combined_flux_plots.R: Script to create combined or comparative plots for the interfacial fluxes.

## License
* **Code:** The Python and R scripts in this repository are licensed under the [MIT License](LICENSE).
* **Data:** The datasets (including topographic measurements and calculated fluxes) are made available under the [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/). 


