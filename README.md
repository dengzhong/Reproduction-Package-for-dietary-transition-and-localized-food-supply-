# *Lower global food system emissions via integrating dietary transition and localized food supply*

## Overview

This repository provides the code and supporting materials for reproducing the analyses presented in the manuscript *"Lower global food system emissions via integrating dietary transition and localized food supply"*.

The study investigates the potential of integrating localized food supply (LFS) and dietary transition strategies to reduce global food-system greenhouse gas (GHG) emissions. By combining spatial optimization, transportation network analysis, and GHG emission accounting, we evaluate the impacts of alternative food supply and dietary scenarios on food miles, food-related emissions, and transportation emissions.

The analysis considers spatially explicit food production and consumption, transportation infrastructure, regional production capacities, and alternative dietary demands.

## Code and reproducibility

The computational framework primarily uses **R and GAMS** for data processing, spatial analysis, optimization, emission accounting, and visualization.

The main analytical procedures include:

1. **Data preparation:** Processing spatially explicit food production, consumption, and emission datasets.
2. **Transportation network construction:** Constructing transportation resistance surfaces and estimating transport distances using road, rail, and shipping networks.
3. **Spatial optimization:** Optimizing food allocation between production and consumption locations under different dietary and food supply scenarios.
4. **GHG emission accounting:** Quantifying on-farm agricultural production emissions and transportation emissions associated with optimized food flows.
5. **Results and visualization:** Analyzing scenario outcomes and generating the figures and supporting results.

The analyses examine the localized food supply strategy under baseline dietary demands (*LFS-Base*) and its integration with the EAT-Lancet dietary transition (*LFS-EAT*).

### Original code archive for verification

For transparency and ease of verification, the **original source code** used in the study has been archived on Figshare:

**[Original source code on Figshare](https://doi.org/10.6084/m9.figshare.28448249)**

This archive is provided to allow reviewers and interested researchers to directly compare the original implementation with the organized code presented in this GitHub repository.

## Software requirements

The main software environments used in this study include:

- **R:** Spatial data processing, transportation network analysis, emission calculations, and visualization.
- **GAMS:** Mathematical programming and spatial optimization.
- **CPLEX:** Linear programming solver used for the optimization models.

Additional R package dependencies and implementation details can be identified from the corresponding scripts.

## Data availability

The analyses draw on spatially explicit agricultural production, food consumption, transportation network, and GHG emission datasets.

Due to the size of the datasets and potential third-party data restrictions, some original input datasets may not be directly included in this GitHub repository.

The original code archive and the data sources documented in the manuscript and its Supplementary Information provide additional information for understanding and reproducing the analytical framework.

## Citation

If you use the code, methods, or analytical framework provided in this repository, please cite the corresponding research paper:

*Lower global food system emissions via integrating dietary transition and localized food supply.*

The complete bibliographic information and publication DOI will be added once the paper is published.

The original code archive is available at:

https://doi.org/10.6084/m9.figshare.28448249

## License

This repository is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

The license applies to the original code distributed under this repository and does not automatically extend to third-party datasets or software dependencies.
