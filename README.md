
# *Lower global food system emissions via integrating dietary transition and localized food supply*

## Overview

This repository provides the code and supporting materials for reproducing the analyses presented in the manuscript *Lower global food system emissions via integrating dietary transition and localized food supply*.

The study investigates the potential of integrating localized food supply (LFS) and dietary transition strategies to reduce global food-system greenhouse gas (GHG) emissions. By combining spatial optimization, transportation network analysis, and GHG emission accounting, we evaluate the impacts of alternative food supply and dietary scenarios on food miles, food-related emissions, and transportation emissions.

The analysis considers spatially explicit food production and consumption, transportation infrastructure, regional production capacities, and alternative dietary demands.

## Data preparation

### 1. Livestock Production Systems data

The spatially explicit livestock production and grain-based feed consumption data were obtained from the **Livestock Production Systems** dataset available through the CSIRO Data Access Portal.

**Data source:**

[Livestock Production Systems — CSIRO Data Access Portal](https://data.csiro.au/collection/csiro:29893)

To reproduce the analysis, download the following 14 ZIP archives, comprising seven livestock production datasets and seven grain-based feed consumption datasets.

#### 1.1. Livestock production data

Download the following seven files:

1. `bvmeat_kg.zip`
2. `bvmilk_kg.zip`
3. `pimeat_kg.zip`
4. `poeggs_kg.zip`
5. `pomeat_kg.zip`
6. `sgmeat_kg.zip`
7. `sgmilk_kg.zip`

These datasets provide spatially explicit livestock production information for the corresponding livestock product categories.

#### 1.2. Grain-based feed consumption data

Download the following seven files:

1. `bvmeat_grai.zip`
2. `bvmilk_grai.zip`
3. `ls_grai.zip`
4. `pimeat_grai.zip`
5. `po_grai.zip`
6. `sgmeat_grai.zip`
7. `sgmilk_grai.zip`

These datasets provide spatially explicit estimates of grain biomass consumption associated with livestock production, expressed in kg/km²/year.

#### 1.3. Data preparation instructions

1. Open the [CSIRO dataset page](https://data.csiro.au/collection/csiro:29893).
2. Download all 14 ZIP archives listed in Sections 1.1 and 1.2.
3. Extract the downloaded archives.
4. Place the extracted files in the following directory within this repository:

```text
Input/Livestock Production Systems data/
```

The input directory should be organized as follows:

```text
Input/
├── GAMS input/
└── Livestock Production Systems data/
    ├── [Extracted livestock production files]
    └── [Extracted grain-based feed consumption files]
```

All required files from both groups should be placed in the `Livestock Production Systems data` directory. Preserve their original filenames and associated files to ensure compatibility with the subsequent data-processing scripts.

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

Additional tools for accessing and reconstructing the large input dataset include:

- **GitHub CLI (gh):** Downloading large dataset files from GitHub Releases.
- **macOS/Linux terminal or Windows PowerShell:** Reconstructing the original GDX file and verifying data integrity.

Additional R package dependencies and implementation details can be identified from the corresponding scripts.

## Data availability

The analyses draw on spatially explicit agricultural production, food consumption, transportation network, and GHG emission datasets.

Due to the size of the datasets and potential third-party data restrictions, some original input datasets may not be directly included in the main GitHub repository.

The livestock production and grain-based feed consumption datasets can be obtained from the CSIRO Data Access Portal, as described in the Data preparation section.

To facilitate reproducibility, the large GAMS input dataset `distanceHisv_all.gdx`, containing spatial distance information used in the food allocation optimization, is provided through GitHub Releases.

### Large GAMS input dataset

**Dataset:** `distanceHisv_all.gdx`

**File format:** GAMS Data Exchange (GDX)

**Original file size:** Approximately 17 GB

**Storage location:** GitHub Releases

**Release version:** `distanceHisv-data-v1`

**Download link:**

[Download the complete GAMS input dataset](https://github.com/dengzhong/Reproduction-Package-for-dietary-transition-and-localized-food-supply-/releases/tag/distanceHisv-data-v1)

Because the original dataset exceeds GitHub's individual file size limits, it has been divided into 11 consecutive parts without modifying the underlying binary data.

The release contains the following files:

| File | Description |
|---|---|
| `distanceHisv_all.gdx.part-aaa` | Data part 1 |
| `distanceHisv_all.gdx.part-aab` | Data part 2 |
| `distanceHisv_all.gdx.part-aac` | Data part 3 |
| `distanceHisv_all.gdx.part-aad` | Data part 4 |
| `distanceHisv_all.gdx.part-aae` | Data part 5 |
| `distanceHisv_all.gdx.part-aaf` | Data part 6 |
| `distanceHisv_all.gdx.part-aag` | Data part 7 |
| `distanceHisv_all.gdx.part-aah` | Data part 8 |
| `distanceHisv_all.gdx.part-aai` | Data part 9 |
| `distanceHisv_all.gdx.part-aaj` | Data part 10 |
| `distanceHisv_all.gdx.part-aak` | Data part 11 |
| `SHA256SUMS.txt` | SHA-256 checksum of the original GDX file |

Together, the 11 parts contain the complete original dataset. They can be concatenated in filename order to reconstruct the original GDX file without any loss or modification of data.

**Important:** GitHub Release assets are stored separately from the repository's source files and are not automatically downloaded when cloning the repository using `git clone`.

While the repository remains private, access to these assets requires appropriate GitHub repository permissions.

### Step 1. Download the dataset

The complete dataset can be downloaded manually from the GitHub Release page or automatically using GitHub CLI.

#### Option A: Manual download (Windows, macOS, and Linux)

1. Open the [GitHub Release page](https://github.com/dengzhong/Reproduction-Package-for-dietary-transition-and-localized-food-supply-/releases/tag/distanceHisv-data-v1).
2. Locate the **Assets** section.
3. Download all 11 files named `distanceHisv_all.gdx.part-aaa` through `distanceHisv_all.gdx.part-aak`.
4. Download `SHA256SUMS.txt`.
5. Save all 12 files in the same folder.

All 11 data parts are required to reconstruct the original GDX file.

#### Option B: Download using GitHub CLI (Windows, macOS, and Linux)

Install GitHub CLI if it is not already available:

https://cli.github.com/

Authenticate with GitHub if necessary:

```bash
gh auth login
```

Alternatively, a properly authorized GitHub personal access token can be provided through the `GH_TOKEN` environment variable.

Then execute the following command in a terminal or Windows PowerShell:

```bash
gh release download distanceHisv-data-v1 --repo "dengzhong/Reproduction-Package-for-dietary-transition-and-localized-food-supply-" --dir "distanceHisv_release_parts"
```

This command downloads all release assets, including the 11 data parts and `SHA256SUMS.txt`, into the `distanceHisv_release_parts` directory.

For private repositories, appropriate GitHub authentication and repository access permissions are required.

### Step 2. Reconstruct the original GDX file

The 11 downloaded parts must be combined in alphabetical order to restore the original `distanceHisv_all.gdx`.

The following procedures are provided separately for macOS/Linux and Windows.

#### Option A: macOS and Linux

Open a terminal and navigate to the folder containing the downloaded files:

```bash
cd distanceHisv_release_parts
```

Reconstruct the original file:

```bash
cat distanceHisv_all.gdx.part-* > distanceHisv_all.gdx
```

This command concatenates the 11 binary parts in filename order and generates:

```text
distanceHisv_all.gdx
```

The resulting file is identical to the original dataset if all parts have been downloaded correctly and remain unchanged.

#### Option B: Windows (PowerShell)

Open Windows PowerShell and navigate to the directory containing the downloaded files:

```powershell
cd "distanceHisv_release_parts"
```

Run the following PowerShell commands to reconstruct the original GDX file:

```powershell
$parts = @(Get-ChildItem -File -Filter "distanceHisv_all.gdx.part-*" | Sort-Object Name)

if ($parts.Count -ne 11) {
    throw "Expected 11 data parts, but found $($parts.Count)."
}

$output = Join-Path (Get-Location) "distanceHisv_all.gdx"

$destination = [System.IO.File]::Open(
    $output,
    [System.IO.FileMode]::CreateNew
)

try {
    foreach ($part in $parts) {
        Write-Host "Merging $($part.Name)..."

        $source = [System.IO.File]::OpenRead($part.FullName)

        try {
            $source.CopyTo($destination)
        }
        finally {
            $source.Dispose()
        }
    }
}
finally {
    $destination.Dispose()
}

Write-Host "GDX file reconstruction completed."
```

This procedure:

1. Identifies all 11 downloaded data parts.
2. Sorts the files alphabetically.
3. Reads and combines the files sequentially as binary data.
4. Writes the reconstructed dataset to `distanceHisv_all.gdx`.
5. Avoids loading the entire 17 GB dataset into memory.
6. Prevents accidental overwriting of an existing reconstructed file.

The resulting file can be used directly in GAMS after successful integrity verification.

**Note:** Ensure that sufficient free disk space is available before reconstruction. Approximately 17 GB of additional storage is required for the reconstructed file.

### Step 3. Verify data integrity

A SHA-256 checksum is provided to verify that the reconstructed GDX file is byte-for-byte identical to the original dataset.

The expected SHA-256 checksum is:

```text
3b862d64f9fddb82f1f1db5025aa97822be2be27d73d893e05f23de9186eadda
```

#### Option A: macOS

In the directory containing the reconstructed GDX file and `SHA256SUMS.txt`, execute:

```bash
shasum -a 256 -c SHA256SUMS.txt
```

#### Option B: Linux

Execute:

```bash
sha256sum -c SHA256SUMS.txt
```

If the file has been reconstructed correctly, the output should be:

```text
distanceHisv_all.gdx: OK
```

#### Option C: Windows (PowerShell)

Open PowerShell in the directory containing the reconstructed GDX file and `SHA256SUMS.txt`.

Execute:

```powershell
$expected = ((Get-Content "SHA256SUMS.txt" -TotalCount 1) -split '\s+')[0].ToLowerInvariant()

$actual = (Get-FileHash "distanceHisv_all.gdx" -Algorithm SHA256).Hash.ToLowerInvariant()

if ($actual -eq $expected) {
    Write-Host "SHA-256 verification: OK"
}
else {
    throw "SHA-256 verification failed."
}
```

If verification is successful, PowerShell will display:

```text
SHA-256 verification: OK
```

A successful checksum verification confirms that the reconstructed file is identical to the original GDX file.

If verification fails, users should check that all 11 parts were downloaded completely and concatenated in the correct order.

### Step 4. Use the reconstructed dataset in GAMS

After successful reconstruction and verification, the file:

```text
distanceHisv_all.gdx
```

can be used as an input dataset for the corresponding GAMS spatial optimization models.

Users should place the reconstructed file in the expected input directory or adjust the file paths in the GAMS scripts accordingly.

The GDX format is supported by GAMS and can be inspected using GAMS-compatible tools.

### Additional data and reproducibility information

The original source code and additional methodological information are available through the Figshare archive:

https://doi.org/10.6084/m9.figshare.28448249

The data sources, assumptions, and analytical procedures are further documented in the manuscript and its Supplementary Information.

This GitHub repository provides organized code and supporting materials to facilitate examination and reproduction of the analytical framework, while the Figshare archive preserves the original implementation for direct comparison and verification.

## Citation

If you use the code, methods, or analytical framework provided in this repository, please cite the corresponding research paper:

*Lower global food system emissions via integrating dietary transition and localized food supply.*

The complete bibliographic information and publication DOI will be added once the paper is published.

The original code archive is available at:

https://doi.org/10.6084/m9.figshare.28448249

## License

This repository is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

The license applies to the original code distributed under this repository and does not automatically extend to third-party datasets or software dependencies.
