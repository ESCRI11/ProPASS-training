# ProPASS DataSHIELD Training

A comprehensive training program for performing federated data analysis using DataSHIELD within the ProPASS consortium.

## 📚 Course Modules

### Module 1: Getting Started
- Prerequisites and environment setup
- Connecting to DataSHIELD servers

### Module 2: Data Cleaning & Management
- Filtering and subsetting datasets
- Conditional operations (ifelse-style)
- Creating derived variables
- Producing Table 1 descriptive summaries

### Module 3: Statistical Modelling
- Generalized Linear Models (`ds.glm`)
- Survival Analysis (`ds.Surv`, Cox models)
- Compositional Data Analysis (CoDA)

## 🚀 Quick Start

### Prerequisites

- R (≥ 4.3.0)
- RStudio Desktop
- Quarto (for building the website)

### Installing R Dependencies

```r
# Core DataSHIELD packages
install.packages(c("DSI", "DSOpal", "devtools", "metafor"))

# DataSHIELD client packages
devtools::install_github("datashield/dsBaseClient")
devtools::install_github("neelsoumya/dsSurvivalClient")
devtools::install_github("timcadman/ds-helper")
```

## 🖥️ Training Server

This training uses the public OBiBa Opal demo server:

| Setting | Value |
|---------|-------|
| **URL** | `https://opal-demo.obiba.org` |
| **Username** | `dsuser` |
| **Password** | `P@ssw0rd` |
| **Profile** | `margin-idiom` |

> **Note**: The `margin-idiom` profile includes `dsSurvival` and other advanced DataSHIELD packages.

### Building the Website

```bash
cd website
make preview  # Local preview
make render   # Build to ../docs
```

Or directly with Quarto:

```bash
cd website
quarto preview
```

## 📁 Project Structure

```
ProPASS-training/
├── website/                    # Quarto website source
│   ├── _quarto.yml            # Site configuration
│   ├── index.qmd              # Landing page
│   ├── 1-prerequisites.qmd    # Setup guide
│   ├── 2-getting-connected.qmd
│   ├── 3-filtering-subsetting.qmd
│   ├── 4-conditional-operations.qmd
│   ├── 5-derived-variables.qmd
│   ├── 6-table-one.qmd
│   ├── 7-glm-models.qmd
│   ├── 8-survival-analysis.qmd
│   ├── 9-coda-analysis.qmd
│   ├── figures/               # Images and logos
│   └── Makefile               # Build commands
├── docs/                       # Built website (for GitHub Pages)
├── scripts/                    # Standalone R scripts
└── README.md
```

## 🔗 Resources

- [DataSHIELD Documentation](https://www.datashield.org/)
- [dsBaseClient Package](https://github.com/datashield/dsBaseClient)
- [dsSurvival Package](https://github.com/neelsoumya/dsSurvival)
- [DataSHIELD Workshop Materials](https://github.com/isglobal-brge/workshop_datashield)

## 📄 License

This training material is provided for the ProPASS consortium.

## 📧 Contact

For questions about this training, please contact the ProPASS training team.
