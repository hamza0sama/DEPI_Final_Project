# CareLens

CareLens is our end-to-end healthcare data analysis project. We started with
public healthcare data and finished with a Power BI project containing ten
dashboard pages. Along the way, we built the warehouse and prepared the data
so that the report could be used without constantly querying the database.

The project is based mainly on de-identified New York State SPARCS hospital
inpatient-discharge data. It lets us look at discharge volume, facilities,
patient groups, diagnoses, procedures, admission types, severity, length of
stay, charges, and costs.

The dashboards are meant to show where demand is concentrated and which groups
may need further operational attention. They are not intended to provide
clinical diagnoses or prove that one factor causes another.

## How we built it

### 1. Collecting the data

We extracted the healthcare data from public healthcare websites and collected
the related diagnosis and procedure reference files. The main source is the
New York State SPARCS de-identified inpatient-discharge dataset.

The source documentation and reference files are kept in the
[`Documentation`](./Documentation) folder.

Useful links:

- [Cleaned hospital dataset on Kaggle](https://www.kaggle.com/datasets/hamzaosamaaboshady/cleaned-hospital-data)
- [Project documentation and reference files](./Documentation)

### 2. Building the SQL Server warehouse

We loaded and transformed the extracted data in SQL Server. The warehouse uses
three main layers:

- **Bronze:** the extracted source data and initial standardization.
- **Silver:** cleaning, type conversions, deduplication, and transformations.
- **Gold:** the fact and dimension tables used for analysis.

This gave us one consistent place to combine the healthcare sources before
connecting the reporting layer.

### 3. Creating the Power BI semantic model

Once the warehouse was ready, we created the Power BI semantic model. The main
table is `gold Fact_Discharges`, supported by dimensions for year, facility,
patient, admission, payment, diagnosis, procedure, APR-DRG, APR-MDC, severity,
and medical/surgical classification. Bridge tables connect facilities with
operators and cooperators.

The model contains measures for discharges, charges, costs, average length of
stay, cost per discharge, emergency admissions, procedures, neonatal cases,
mortality, severity, and year-over-year changes. The current model covers
**2018–2021**.

### 4. Caching the Power BI data

After preparing the report, we cached the Power BI data so normal report use
would not rely heavily on repeated queries to the SQL Server. This also makes it
possible to open the project with the prepared local cache.

Download the [cached Power BI data](https://drive.google.com/file/d/17H5wqwc400MtDpuaVxZaofOPiPtxf5iE/view?usp=sharing)
and extract it into:

```text
power BI/CareLens_Power_BI_Project (3)/Final Project.SemanticModel/.pbi/
```

### 5. Creating the dashboard

The final Power BI project contains ten connected dashboard pages:

1. Executive Overview
2. Cost and Charges
3. Length of Stay and Admission
4. Patient Demographics and Payment
5. Diagnosis and Procedure
6. Severity, APR-DRG and MDC
7. Facility and Geography
8. Ownership, Operators and Cost Transparency
9. Neonatal and Birth Weight
10. Trends, Growth and Forecasting

Open the main project file in Power BI Desktop:

[Final Project.pbip](./power%20BI/CareLens_Power_BI_Project%20%283%29/Final%20Project.pbip)

## Python bonus analysis

The Python notebooks are a bonus addition to the main warehouse and Power BI
solution. They reuse the results of the previous data analysis to investigate
whether length of stay can be predicted in advance.

This work is intended to aid healthcare planning by providing an additional
analytical view of expected patient length of stay. The notebooks cover:

- data cleaning and validation;
- feature engineering;
- exploratory length-of-stay analysis;
- model training and evaluation using scikit-learn and LightGBM.

Run the notebooks in this order:

1. [Cleaning.ipynb](./blob/main/Python/Cleaning.ipynb)
2. [Feature Engineering.ipynb](./blob/main/Python/Feature%20Engineering.ipynb)
3. [Length of stay.ipynb](./blob/main/Python/Length%20of%20stay.ipynb)

### Python requirements

- Python 3.12 or a compatible version
- Jupyter Notebook, JupyterLab, or the VS Code Jupyter extension
- `pandas`
- `numpy`
- `matplotlib`
- `scikit-learn`
- `lightgbm`

The notebooks may generate intermediate CSV and Parquet files locally. These
files are derived analysis artifacts and are not required to open the Power BI
project.

## Repository structure

```text
.
├── Cleaning.ipynb
├── Feature Engineering.ipynb
├── Length of stay.ipynb
├── Documentation/
├── Plan & presentation/
├── power BI/
│   ├── CareLens_Power_BI_Project (3)/   # Main Power BI project
│   ├── Power pi/                        # Alternate project copy
│   └── Individual work/
└── sql pipelines/                       # Warehouse SQL assets
```

## How to use the project

1. Install Power BI Desktop.
2. Download and extract the cached Power BI data into the path above.
3. Open `Final Project.pbip` in Power BI Desktop.
4. Explore the ten dashboard pages and their filters.
5. Optionally install Python and Jupyter to run the LOS analysis notebooks.

The warehouse and source data are already prepared on the project server; no
local SQL Server setup is required for reviewing the Power BI report.

## Documentation

- [Dashboard build guide](./Plan%20%26%20presentation/CareLens_Power_BI_Dashboard_Build_Guide.md)
- [Data story and presentation plan](./Plan%20%26%20presentation/CareLens_Data_Story_and_Presentation.md)
- [Documentation and reference files](./Documentation)

## Data use

The project uses de-identified healthcare data for analytical and educational
purposes. Do not commit credentials, private extracts, or other sensitive
information. Confirm the applicable terms for the original datasets and
reference files before redistributing derived data.
