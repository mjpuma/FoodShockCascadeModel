# Original MATLAB code (2012–2015)

These are the MATLAB scripts behind Puma, M.J., Bose, S., Chon, S.Y., and Cook, B.I. (2015), *Assessing the evolving fragility of the global food system*, Environmental Research Letters 10, 024007, [doi:10.1088/1748-9326/10/2/024007](https://doi.org/10.1088/1748-9326/10/2/024007). They are kept exactly as they were last saved in 2014–2015, as a record of the code that produced the published results. Nothing has been edited, including the hard-coded local paths.

The maintained implementation is the Python package in [`../fsc2015/`](../fsc2015/). It is a new implementation of the same rules, not a port of these scripts; see [`../README.md`](../README.md) for how it compares with the paper.

## Files

| File | Last saved | What it does (from its header comments) |
|---|---|---|
| `Global_Trade_network_twocommodities.m` | Dec 2014 | Builds the annual bilateral trade networks for two commodities (wheat and rice) and computes complex-network statistics. M.J. Puma, 2012–2014. |
| `GTN_climatedisturbances.m` | Dec 2014 | Targeted attacks on the network (export bans), self-sufficiency ratios, and the bar plots and maps of losses in the ERL article. M.J. Puma, 2013–2014. |
| `GTN_totalproduction.m` | Sep 2014 | Percentage of world production affected by a targeted attack. M.J. Puma, 2014. |
| `ComplexNetworkExtract_climatedisturbances.m` | Oct 2014 | Network files for plotting in Cytoscape, and network statistics with and without an attack. M.J. Puma, 2013–2014. |
| `GlobalFoodReserves.m` | May 2015 | Global food reserves (stocks) from FAO, IGC, USDA and national data compiled in November 2014. M.J. Puma, 2014. |
| `Global_Trade_network_quantities.m` | Oct 2013 | Earlier version of the network script: reads the annual bilateral trade network and computes complex-network statistics with the Complex Networks toolbox by Lev Muchnik. M.J. Puma, 2012. |
| `FAO_bilateral_trade_load_v09272013.m` | Oct 2013 | Builds trade networks from the FAOSTAT bilateral trade files (1986–2009 by commodity, later years by year), optionally weighted by green and blue virtual water content. |
| `FAO_bilateral_trade_loadCE_v10162013.m` | Oct 2013 | The same, with crop-equivalent weighting instead of virtual water. This is the loader the network scripts above name in their headers. |
| `colormap_function.m` | May 2015 | Colour maps used in the figures (ColorBrewer and colour-blind-safe tables). |
| `VW_analyses/` | 2011–2012 | Country and crop lookup helpers (`country_*.m`, `crop_lookup.m`) and `VWC_siebert_open.m`, which reads the Siebert and Döll (2010) crop water use grids used for virtual water weighting. |

## Historical drought maps (`historical/`)

The two historical analogues in the paper, the 1816 "Year Without a Summer" in Europe and the 1876–1878 Great Drought in Asia, were chosen by mapping paleoclimate reconstructions. Countries with the anomaly over at least half their territory became the export-ban scenarios in table S1 (now [`../scenarios/`](../scenarios/)). These scripts made those maps; [`../fsc2015/figures.py`](../fsc2015/figures.py) redraws them as figure 3.

| File | Last saved | What it does |
|---|---|---|
| `T_anomolies_Europe1500_2002.m` | Feb 2014 | Summer (JJA) temperature anomaly over Europe from the Luterbacher et al. (2004) seasonal reconstruction, 0.5°, for 1816. Figure: `figures/TTanomaly_JJA_1816.eps`. |
| `Great_Victorian_Drought.m` | Aug 2015 | Summer (JJA) PDSI over Asia from the Monsoon Asia Drought Atlas (Cook et al. 2010) for 1876–1878. Figure: `figures/PDSI.JJA.GreatDrought.eps`. This copy was saved after the paper was published. |
| `China_1960_Drought.m` | Dec 2013 | The same map for the 1959–1961 drought in China. It is not one of the paper's scenarios. Figure: `figures/PDSI.JJA.China1960Drought.eps`. |

The reconstructions themselves are not included. Cite and download them from NOAA NCEI Paleoclimatology:

- Luterbacher, J., Dietrich, D., Xoplaki, E., Grosjean, M., and Wanner, H. (2004), European seasonal and annual temperature variability, trends, and extremes since 1500, *Science* 303, 1499–1503, doi:10.1126/science.1093877.
- Cook, E.R., Anchukaitis, K.J., Buckley, B.M., D'Arrigo, R.D., Jacoby, G.C., and Wright, W.E. (2010), Asian monsoon failure and megadrought during the last millennium, *Science* 328, 486–489, doi:10.1126/science.1185188.

They also use `colormap_function.m` (above), the m_map toolbox, and `rgb.m` from the MATLAB File Exchange.

## Running them

They will not run as they are. They read FAOSTAT and World Bank extracts downloaded in 2012–2014 from local Dropbox folders that are not part of this repository (country lists, GDP and population spreadsheets, bilateral trade matrices, shapefiles). The project's own helpers (the FAOSTAT loaders, colour maps and lookups) are included above. Third-party code they call is not included and should be obtained from its authors: `logfit` by Jonathan Lansey (MATLAB File Exchange), the Complex Networks toolbox by Lev Muchnik (`GraphLoadFromFile`, `GraphRemoveUnlinkedNodes`), and the m_map mapping toolbox by Rich Pawlowicz (`m_proj`, `m_patch`, `m_grid`).
