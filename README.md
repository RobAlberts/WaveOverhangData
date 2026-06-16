# Supplementary Data — Wave Overhang Material Study

**Investigating different materials' effect on support-free 3D printing**

R. Alberts · J.A. Andersons · University of Twente, Faculty of Engineering Technology, 2026

📧 r.alberts@student.utwente.nl

\---

## About

This repository contains all supplementary data for the BSc research paper investigating how material selection affects the dimensional accuracy of the **wave overhang** support-free FDM 3D printing method.

Six polymer grades were printed across six test geometries. Each specimen was 3D-scanned and compared against the original CAD model to produce surface deviation heatmaps. RMS deviation is used as the primary metric.

> \*\*Paper:\*\* \*Investigating different materials' effect on support-free 3D printing\*
> R. Alberts, J.A. Andersons — University of Twente, 2026

\---

## Repository Structure

```
WaveOverhangData/
├── CAD Models/                  # Reference CAD files for all test geometries (TS01–TS06)
├── Deviations/                  # CSV deviation exports and heatmap images from Zeiss Inspect
├── Final Test Samples gcode/    # Sliced G-code for each material × sample combination
├── Preliminary Testing GCode/   # G-code used during TS00 monolayer calibration per material
└── Zeiss Inspect/               # Zeiss Quality Suite project files and raw inspection data
```

\---

## Materials

|#|Material|Role|
|-|-|-|
|1|Neat PLA|Primary control|
|2|PLA-CF|H1 — CF reinforcement on PLA base|
|3|PLA-GF|H1 — GF reinforcement on PLA base|
|4|Neat PETG|Secondary control; higher Tg, slower solidification|
|5|PETG-CF|H1 — CF reinforcement on PETG base|
|6|ABS|High-CTE reference; lower printability bound|

\---

## Test Geometries

|ID|Description|
|-|-|
|TS00|Monolayer preliminary calibration specimen (one per material)|
|TS01|Baseline cantilever — reference geometry|
|TS02|Thick overhang — 10 mm section above wave layer|
|TS03|Line seed, incline, corner — 85° overhang angle|
|TS04|Looped seed, narrow passages|
|TS05|Looped seed, holes — combined challenge specimen|
|TS06|Line seed, bridging, thick overhang|

\---

## Slicing Parameters

All specimens were sliced using the [OrcaSlicer-WaveOverhangs fork](https://github.com/dennisklappe/OrcaSlicer-WaveOverhangs) with the Andersons algorithm.

**Shared parameters across all materials and samples:**

|Parameter|Value|
|-|-|
|Nozzle diameter|0.4 mm hardened steel|
|Layer height|0.24 mm|
|Wave print speed|2.0 mm/s|
|Wave algorithm|Andersons|
|Part-cooling fan (wave layer)|100%|
|Infill pattern|Zigzag (TS01–TS04, TS06) / Smart (TS05)|

**Calibrated wave parameters per material** (determined during TS00 preliminary testing):

|Material|Nozzle Temp (°C)|Line Spacing (mm)|Wave Flow (mm³/mm)|
|-|-|-|-|
|Neat PLA|210|0.46|0.20|
|PLA-CF|210|0.37|0.18|
|PLA-GF|190|0.39|0.22|
|Neat PETG|230|0.42|0.20|
|PETG-CF|240|0.38|0.18|
|ABS|250|0.44|0.23|

\---

## Key Results

RMS deviation across all specimens ranged from **0.11 mm** (PETG-CF, TS03) to **1.11 mm** (Neat PETG, TS02).

* **CF-reinforced grades** (PLA-CF, PETG-CF) consistently achieved the lowest deviations, confirming that fibre reinforcement suppresses the Shape Memory Polymer effect driving upward curl.
* **ABS** showed the highest deviations across all geometries, consistent with its high coefficient of thermal expansion.
* A **5° angle reduction** (90° → 85°, TS01 → TS03) produced 30–70% RMS reductions across all materials — the single most effective intervention, outperforming any material substitution.

\---

## Equipment

|Item|Details|
|-|-|
|3D Printers|Bambu Lab A1 Mini; Anycubic Kobra S1|
|3D Scanner|Shining3D Einscan 2X Plus|
|Deviation Analysis|Zeiss Quality Suite|
|Slicer|OrcaSlicer-WaveOverhangs — Andersons algorithm|

\---

## Related Links

* 🌐 [waveoverhangs.com](https://www.waveoverhangs.com) — community site and gallery
* 🔧 [OrcaSlicer-WaveOverhangs fork](https://github.com/dennisklappe/OrcaSlicer-WaveOverhangs)
* 📄 [Wave overhang method paper (Andersons et al.)](https://ssrn.com/abstract=6640458)

\---

## 

