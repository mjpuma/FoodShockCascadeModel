# Cascade model in MATLAB, 2016–2018

This folder is the MATLAB (and one Python) code that links the reserves-and-trade cascade of Marchand et al. (2016) to the Food Shock Cascade model in R. M.J. Puma wrote it from June 2016 to January 2018 to run the Marchand et al. cascade on cereal networks for specific historical and hypothetical shocks: a multi-year US Dust Bowl, a Laki-type eruption, other volcanic eruptions, and generic production declines of increasing size.

The Dust Bowl simulations are early versions of the study published as Heslin, A., Puma, M.J., Marchand, P., et al. (2020), *Simulating the cascading effects of an extreme agricultural production shock: global implications of a contemporary US Dust Bowl event*, Frontiers in Sustainable Food Systems 4:26, [doi:10.3389/fsufs.2020.00026](https://doi.org/10.3389/fsufs.2020.00026), which used the R model in [`../main/`](../main/).

The files are kept exactly as last saved, as a record of the computations. They are not maintained. For current work use the R model; see the [Lineage](../README.md#lineage) section of the repository README.

## The cascade

`sim_cascade.m` follows Marchand, P., Carr, J.A., Dell'Angelo, J., et al. (2016), *Reserves and trade jointly determine exposure to food supply shocks*, Environmental Research Letters 11, 095009, [doi:10.1088/1748-9326/11/9/095009](https://doi.org/10.1088/1748-9326/11/9/095009); their code is at [pmarchand1/cereals-network-shocks](https://github.com/pmarchand1/cereals-network-shocks). A production decline `dP` is absorbed first by a country's available reserves and consumption, and the rest is passed along existing trade links in proportion to trade volume, iterating until the remaining shock is negligible. Net supply is S = P + I − E = R + C.

| File | Last saved | What it does |
|---|---|---|
| `sim_cascade.m` | Dec 2017 | The cascade: inputs `dP`, `P0`, `R0`, `E0`, the share of the shock absorbed by consumption (`cfrac`), and whether shocked countries can export once their reserves are gone (`asym`). Returns changes in reserves, consumption and trade. |
| `dEalloc.m` | Jun 2016 | Relative change in each trade link from the share of each country's trade affected by the shock. |
| `sim_diagnostics.m` | Dec 2016 | Checks a run: total change in reserves and consumption equals the initial shock, and imports minus exports balance reserves plus consumption for each country. |
| `sim_cascade.py` | Jun 2016 | A first Python version of the cascade. |

## Shock scenarios

| File | Last saved | Scenario |
|---|---|---|
| `DustBowlShock.m` | Jun 2016 | Single-year US Dust Bowl shock |
| `DustBowlShock_multiyear.m` | Jun 2016 | Multi-year Dust Bowl shock |
| `DustBowlShock_v2.m` | Oct 2016 | Multi-year Dust Bowl shock with network statistics before and after |
| `VolcanoShock_multiyear.m` | Jun 2016 | Multi-year volcanic shock |
| `LakiEruptionShock.m` | Dec 2016 | Multi-year shock from a Laki-type (1783) eruption |
| `GenericFoodShock.m` | Apr 2017 | Any multi-year production shock |
| `GenericFoodShock_SingleYearMultiP.m` | Nov 2017 | One year, a range of shock sizes |
| `GenericFoodShock_MultiProd.m` | Nov 2017 | A range of shock sizes, multiple years |
| `SingleLayerShock_MultiProd.m` | Jan 2018 | A range of shock sizes on a single cereal layer |

## Outputs

`Tables/` holds cereal trade (million kcal) for the G8+5 countries and Pakistan before and after the Dust Bowl shock, and baseline network statistics, for the 2010 and 2011 networks. `Stats_DustBowl_2010.dat` and `Stats_DustBowl_2011.dat` are network statistics after the shock. `Figures/` holds the matching EPS figures: network size, links, flows, centrality, efficiency, diameter and radius, the largest connected component, reserves and stocks-to-use ratios.

## Running them

They will not run as they are. They read processed FAOSTAT and USDA production, trade and stocks data and country code tables from local Dropbox folders that are not part of this repository. The network statistics use the [Brain Connectivity Toolbox](https://sites.google.com/site/bctnet/), which is not included.
