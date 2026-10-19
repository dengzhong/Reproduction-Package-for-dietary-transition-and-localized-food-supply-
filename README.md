
# *Lower global food system emissions via integrating dietary transition and localized food supply*

## Overview

This repository provides the code and supporting materials for reproducing the analyses presented in the manuscript *Lower global food system emissions via integrating dietary transition and localized food supply*.

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
- **GitHub CLI:** Downloading large datasets stored as GitHub Release assets.

Additional R package dependencies and implementation details can be identified from the corresponding scripts.

## Data availability

The analyses draw on spatially explicit agricultural production, food consumption, transportation network, and GHG emission datasets.

Due to the size of the datasets and potential third-party data restrictions, some original input datasets may not be directly included in this repository.

To facilitate reproducibility, the large GAMS input dataset `distanceHisv_all.gdx`, containing spatial distance information used in the food allocation optimization, is provided through GitHub Releases.

### Large GAMS input dataset

**Dataset:** `distanceHisv_all.gdx`

**File format:** GAMS Data Exchange (GDX)

**Original file size:** Approximately 17 GB

**Storage:** GitHub Releases

**Release:** `distanceHisv-data-v1`

**Download link:**

[Download distanceHisv_all.gdx dataset](https://github.com/dengzhong/Reproduction-Package-for-dietary-transition-and-localized-food-supply-/releases/tag/distanceHisv-data-v1)

Because the original dataset exceeds GitHub's individual file size limits, it has been divided into 11 consecutive parts without modifying the underlying data.

The release contains:

- `distanceHisv_all.gdx.part-aaa`
- `distanceHisv_all.gdx.part-aab`
- `distanceHisv_all.gdx.part-aac`
- `distanceHisv_all.gdx.part-aad`
- `distanceHisv_all.gdx.part-aae`
- `distanceHisv_all.gdx.part-aaf`
- `distanceHisv_all.gdx.part-aag`
- `distanceHisv_all.gdx.part-aah`
- `distanceHisv_all.gdx.part-aai`
- `distanceHisv_all.gdx.part-aaj`
- `distanceHisv_all.gdx.part-aak`
- `SHA256SUMS.txt`

The 11 parts collectively contain the complete original GDX file. The SHA-256 checksum is provided to verify data integrity after reconstruction.

**Note:** Release assets are stored separately from the Git repository and are not downloaded automatically by `git clone`. Access to release assets requires appropriate repository permissions while the repository remains private.

### Downloading the dataset

The complete dataset can be downloaded manually from the GitHub Release page.

Alternatively, users with access to the repository can download all release assets using GitHub CLI:

```bash
gh release download distanceHisv-data-v1 \
  --repo "dengzhong/Reproduction-Package-for-dietary-transition-and-localized-food-supply-" \
  --dir distanceHisv_release_parts
```

This command downloads all 11 data parts and the SHA-256 checksum file into the specified directory.

For private repositories, GitHub CLI authentication and appropriate repository access permissions are required.

### Reconstructing the original GDX file

After downloading all parts, the original `distanceHisv_all.gdx` file can be reconstructed on macOS or Linux using:

```bash
cd distanceHisv_release_parts

cat distanceHisv_all.gdx.part-* > distanceHisv_all.gdx
```

The command concatenates all 11 parts in alphabetical order to reconstruct the original binary GDX file.

**Important:** All 11 parts must be present in the same directory before reconstruction. The files must be combined as binary data without modification.

The reconstructed `distanceHisv_all.gdx` can then be used as an input to the corresponding GAMS optimization scripts, with file paths adjusted as necessary.

### Data integrity verification

To verify that the reconstructed file is identical to the original dataset, calculate its SHA-256 checksum.

On macOS:

```bash
shasum -a 256 -c SHA256SUMS.txt
```

On Linux:

```bash
sha256sum -c SHA256SUMS.txt
```

If reconstruction is successful, the command should return:

```text
distanceHisv_all.gdx: OK
```

The expected SHA-256 checksum of the original file is:

```text
3b862d64f9fddb82f1f1db5025aa97822be2be27d73d893e05f23de9186eadda
```

A matching checksum confirms that the reconstructed file is byte-for-byte identical to the original dataset.

### Additional data and reproducibility information

The original code archive and the data sources documented in the manuscript and its Supplementary Information provide additional information for understanding and reproducing the analytical framework.

The GitHub repository provides organized code for examination and reproduction, while the Figshare archive preserves the original implementation for direct comparison and verification.

## Citation

If you use the code, methods, or analytical framework provided in this repository, please cite the corresponding research paper:

*Lower global food system emissions via integrating dietary transition and localized food supply.*

The complete bibliographic information and publication DOI will be added once the paper is published.

The original code archive is available at:

https://doi.org/10.6084/m9.figshare.28448249

## License

This repository is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

The license applies to the original code distributed under this repository and does not automatically extend to third-party datasets or software dependencies.
