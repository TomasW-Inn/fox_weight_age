ANalysis:
**Data preparation** replicates `StartData1.r` exactly:

- Reads `work_file_NEW.csv`, filters to 1967–1971, age ≥ 0, known `LSkp`
- Assigns the 5 area groups, pools sparse area 1 (Lappland/Norrbotten/Västerbotten) into area 2 (N)
- Recodes Sex (codes 1,3,5,7 → male; 2,4,6,8 → female)
- Caps age at 8 (the "8+" pooled class)
- Builds the **8 × 9** count matrix `y` (4 regions × 2 sexes, 9 age classes)

The resulting counts (verified against your original script):

|Group|N|
|---|---|
|N male|1461|
|NC male|553|
|SC male|929|
|S male|374|

**To run it**, place the script in the same directory as `modelAgeSexArea_v2.jags` and `work_file_NEW.csv`, then:

r

```r
source("run_v2_complete.R")
```

**Key outputs to assess model fit:**

1. **Bayesian p-value** — the original model gave 0.712 (too high, indicating over-fitting to the multinomial). The v2 model (Dirichlet-multinomial + RW2) should pull this closer to 0.5
2. **`ppc_plot_v2.pdf`** — scatter of G-statistic replicated vs. observed; points should scatter symmetrically around the 1:1 line
3. **`phi`** — if large (>500), overdispersion is negligible; if modest (say 10–100), the DM extension is doing real work
4. **`sigma_age`** — controls smoothness of the RW2 age curve
5. **`survival_v2.pdf`** — posterior mean survival by region and sex