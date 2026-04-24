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
  
Ran a command, read a file
Here's a summary of all changes going into v4:
**R script (`run_v4_complete.R`):**
- `Age_pool := pmin(Age, 7L)` — pools ages 7, 8, 9+ into a single "7+" class
- `S <- 8` — down from 9
- Column names and plot axes updated to `age0:age7`

**JAGS model (`modelAgeSexArea_v4.jags`):**
- `ey[i,8]` now combines both terminal classes: `p[i,7]*C[i,7] + p[i,8]*C[i,8]`
- `ey[i,1]` sums over `ey[i, 2:8]` instead of `2:9`
- `safe_theta` guard removed — no longer needed with no zero cells
- G-statistic floor restored to `0.001`

The resulting count matrix will have no zeros — the SC_M group that had 0 at age 8 now has `0 + 2 = 2` in the pooled "7+" class.

