Setting up a project in Claude. 

Project description:
This project aim to investigate how survival and body size patterns vary along a geographical gradient south to north in Sweden. We used 6 022 harvested foxes were collected from hunters between 1967 and 1971 when efforts were made to retrieve foxes from all parts of Sweden. Carcass weight was recorded to the nearest hectogram, and age was determined by microscopic examination of cementum layers of the canine teeth.  Latitudinal regions. We grouped the collected foxes in four latitudinal regions. Sweden covers a wide range of climatic zones, and stretches more than 1 500 km from south to north.  N:: 1461 males and 1128 females. The northernmost part of Sweden that stretches mostly north of 62◦ latitude to north of the polar circle. The region is characterized by low productivity and a net primary production (NPP) below 300.  NC:: 553 males and 437 females. North-Central Sweden, between 60◦ and 62◦ latitudes, is dominated by boreal conifer forest (84%) interspersed with agricultural (4%) areas.  SC:: 929 males and 809 females. South-Central Sweden, between 58◦ and 60◦ latitudes is characterized by forests (63%) and agriculture (22%) areas. Broad leaf tree species are common in forests. S:: 374 males and 289 females. Southern part of Sweden, which is below 58◦ latitude. The region contains forest (65%) and agriculture (19%) areas, and forests contain several different broad leave species in addition to conifers. 

 I will use a  Bayesian age-at-harvest survival following Skelly et al. and initialllay use a GLM for weight analysis of sex and age in the different regions. 

I will use R to work on data, do analysis and produce tables and figures. Bayesian models will be developed in JAGS using JagsUI as the connection between R and JAGS. Workbook, reports and manuscript will be written in LateX markup langauge. I prefer to use startup.sty when writing in LateX. 

Note that the data predates the 1975–77 sarcoptic mange outbreak, which is important for interpreting the stable population assumption. 

A preliminary analysis is presented in manus_1.pdf.

The project lives in the folder fox_weight_age on my computer that has the following subfolder structure:
.
├── analysis
│   ├── models
│   │   └── archive
│   ├── output
│   │   └── archive
│   └── scripts
│       └── archive
├── data
│   ├── processed
│   │   └── archive
│   └── raw
│       └── archive
├── notes
│   └── FoxLifeHisory
└── paper
    └── archive
