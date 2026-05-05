Sounds good! When you come back it would be useful to have the regional harvest trends from `sw_stat_early.csv` plotted alongside the lambda estimates — that will make for a compelling triangulation of the model results.

A few things to think about in the meantime:

1. **Do the harvest trends by region match the lambda gradient?** Increasing harvests in SC and stable/declining in N would support the model findings.
2. **The bp of 0.660** — once you're happy with the lambda interpretation, it's worth deciding whether to pursue further model improvements or accept this as the final model. The original was 0.712 so v5 is already an improvement.
3. **Figure 2 for v5** — when you're ready to write up, the survival plot with the sawtooth pattern needs a sentence in the methods or results acknowledging it as a known artefact of the stable stage back-calculation, not a biological signal. Figure 2 in the manuscript already sets that precedent.

Take your time — good luck with the harvest data check!

**FIX THE MANNUSCRIPT**

### Major Problems

**1. The abstract contradicts the results on survival direction** The abstract states "Survival was lower in the two southern regions than in the northern regions" (lines 21–22), but Table 4 shows that Region S has a negative coefficient (−0.052) while NC and SC are both _positive_ relative to North. The actual pattern is that NC and SC have slightly _higher_ survival than both N and S — not a simple north-higher pattern. This is also stated more carefully in the results (lines 211–213), making the abstract a misleading oversimplification of an already uncertain result. Since all CrIs span zero, the abstract should not present a directional survival claim as if it were a finding.

**2. The discussion ends abruptly and incompletely** The manuscript ends mid-discussion on page 13, with the density-dependence paragraph as the final substantive text. There is no synthesis of what the study contributes, no discussion of limitations, and no concluding statement. Key topics mentioned as important in the draft notes — dispersal from south to north biasing northern age structure, assumptions of the age-at-harvest model, the pre-mange stable population assumption — are entirely absent from the final text. Reviewers will notice this immediately.

**3. The survival result is undersold and poorly framed** The main survival finding — a hump-shaped, age-dependent curve with low sub-adult survival, higher female survival, and uncertain regional differences — is presented very briefly. The discussion does not adequately engage with _why_ sub-adult survival is so much lower, why females survive better than males, or what the hump-shaped curve implies biologically for a fast-living carnivore. These are the most robust findings and deserve more attention than the uncertain regional differences.

**4. The reference "Oskyrko et al. 2026" (line 243) appears to be a future-dated paper** A 2026 publication cited mid-discussion is unusual and will raise reviewer flags. If this is a recently published paper, confirm the year is correct and that it is properly accessible. If it is in press or a preprint, label it accordingly.

**5. The λ prior for SC and S is wider than for N and NC without justification** In the JAGS model (lines 537–538), N and NC get `dunif(0.8153, 1.1000)` while SC and S get `dunif(0.7500, 1.1500)`. This asymmetry is never explained in the methods. Wider and lower-bounded priors for the south could meaningfully affect the posterior λ estimates, and the choice needs to be justified or at minimum acknowledged as a sensitivity assumption.

**6. The model selection table (Table 3) is inconsistent** DIC is reported for all models except the top model (region-specific λ), which shows "—". This makes it impossible for the reader to evaluate how much better the top model is by DIC. Either report DIC for the top model or explicitly explain why it is not comparable (different likelihood structure). The Bayesian p-value actually _worsened_ from 0.712 to 0.660 when moving to region-specific λ, yet the model is still selected — this should be addressed directly rather than just noted in passing.

---

### Minor Problems

**1. Duplicate sentence in the discussion (lines 291–295)** The sentence _"The lack of a clear latitudinal pattern in survival..."_ appears almost verbatim twice in consecutive paragraphs. One instance should be removed or rewritten.

**2. Grammatical error, line 302** _"This analogous to work..."_ — missing verb, should be _"This is analogous to work..."_

**3. Grammatical error, lines 271–273** _"it was shown that the mean longevity decreased that and age structure..."_ — "that and" is a clear typo, likely "and the age structure".

**4. "Ursus actor" (line 248)** The brown bear species is _Ursus arctos_, not _Ursus actor_. This should be corrected.

**5. The NC region description (lines 118–125) contains an internal inconsistency** The text says "Human settlements are more common than in NC" within the NC region description itself — this was presumably meant to say "more common than in N."

**6. Figure 3 caption is uninformative** _"The estimated age distribution of male and female Red fox in four different regions"_ — it should clarify that age class 1 is set to 1 (as in the earlier draft), and what the y-axis represents, since the figure shows relative proportions, not absolute numbers.

**7. Figure 2 lacks error bars or credible intervals in the caption description** The figure itself appears to show point estimates only. Given that all regional differences are uncertain, showing CrIs in this figure would strengthen transparency and is common practice for Bayesian survival estimates.

**8. "Red fox" capitalization is inconsistent** Sometimes written "Red fox" (capitalized), sometimes "red fox." Pick one convention and apply it throughout. Most ecological journals use lowercase for common names.

**9. The sub-adult weight model excludes age but the adults include it — this asymmetry needs a sentence of justification in the methods** Line 145–148 gives a brief rationale, but it could be stated more explicitly that sub-adults are all age 0 (first-year) animals where within-class age variation is not recorded, making the models non-comparable in structure.

**10. Missing overall λ estimate in results** The abstract mentions λ = 0.946 for North and λ = 1.017 for SC, but there is no single overall growth rate reported. The earlier draft had an overall λ = 1.040. If this has been dropped in favour of region-specific λ, the text should acknowledge this change explicitly rather than leaving readers to infer it.

### What you can firmly conclude

**On body weight:**

- Red fox body weight decreases with latitude in Sweden, contrary to Bergmann's rule. This is a clean, well-supported result with large effect sizes (the latitudinal gradient exceeds even the sex difference) and robust statistics.
- The pattern is consistent across both sexes and age classes, and the sex × region interaction is absent — meaning the gradient is not driven by one sex.
- This is your strongest and clearest result.

**On survival:**

- Sub-adult survival is substantially lower than adult survival across all regions — this is a robust finding.
- Females survive better than males across all regions and ages — credible and consistent with other studies.
- The hump-shaped adult survival curve is real and biologically meaningful for a fast-living carnivore.
- Regional differences in survival are _uncertain_ — this is itself a finding worth stating clearly. You looked for a latitudinal gradient in survival and did not find one.

**On population growth:**

- The λ estimates suggest a north-declining, south-stable pattern that is independently corroborated by harvest bag statistics. This cross-validation is genuinely valuable and strengthens the λ estimates considerably.

---

### What is interesting about these findings

The most intellectually interesting result is the **decoupling between body weight and survival across the latitudinal gradient.** Body weight shows a strong, clean gradient. Survival does not. That paradox is the heart of the paper and deserves to be stated explicitly as a conclusion, not buried in hedged language.

The second interesting point is the **λ corroboration by harvest statistics** — this is methodologically useful for other researchers using age-at-harvest models, and worth highlighting.

---

### A suggested concluding paragraph structure

1. The latitudinal decline in body weight is contrary to Bergmann's rule and consistent with productivity-driven resource limitation.
2. Despite this, survival did not show a corresponding latitudinal gradient — regional differences were uncertain.
3. The decoupling of body condition and survival across regions suggests that factors beyond individual nutritional state — possibly density-dependent processes — regulate mortality similarly across the gradient.
4. Population growth rates, independently supported by harvest statistics, suggest a north-declining trend consistent with the productivity gradient.
5. One sentence on what future work should address — ideally density estimates per region, or recruitment data.