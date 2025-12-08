Preclinical in silico assessement of drugs' safety is a process aimed to reduce the time and resources, which are needed to make sure that drug candidate is safe enough to be studied in clinic. Toxicity prediction is an important part of it. Here is the code and notes for the retrival of the data on the toxicity of chemical compounds towards animal models from PubChem [1d].

It is important to note that PubChem's usage in general should be in accordance wit its and its sources data policies:
https://www.ncbi.nlm.nih.gov/home/about/policies/
https://www.nlm.nih.gov/web_policies.html

In this study, ChemIDplus accessed via PubChem is the main data source, thus, the data should be further used in accordance with its and National Library of Medicine data policies:
https://www.nlm.nih.gov/web_policies.html#copyright

Source: National Library of Medicine

Also, pay attention to the PubChem's Programmatic Access Policy: https://pubchem.ncbi.nlm.nih.gov/docs/programmatic-access

To extarct and process the data the following tools were used: R programming language ecosystem [1t] in general and Tidyverse [2t], JSONlite library  [3t].

Also, a tool called "makemna.exe", which was developed earlier in the LSFBDD (https://en.ibmc.msk.ru/departments?view=article&id=26:laboratory-of-structure-function-based-drug-design&catid=10:data), was used to generate MNA descriptors [Filimonov, Dmitrii, et al. "Chemical similarity assessment through multilevel neighborhoods of atoms: definition and comparison with the other descriptors." Journal of chemical information and computer sciences 39.4 (1999): 666-670.]. MNA descriptors are used to aggregate the data on similar structures in some scripts. Makemna is proprietary and is not provided. But, it should be noted that in similar pipelines MNA descriptors could be replaced by the other descriptors for the sake of aggregation.

This repo is a part of the report for ongoing project RSF 25-15-00300, thus, due to the shortage of time, all the explanations for the data processing and results' descriptions will be quite short and will be provided along with the code. 

Data References:

1d. Kim, Sunghwan, et al. "PubChem 2023 update." Nucleic acids research 51.D1 (2023): D1373-D1380.

Tool References:

1t. Team, R. Core. "R language definition." Vienna, Austria: R foundation for statistical computing 3.1 (2000): 116.

2t. Wickham, Hadley, et al. "Welcome to the Tidyverse." Journal of open source software 4.43 (2019): 1686.

3t. Ooms, Jeroen. "The jsonlite package: A practical and consistent mapping between json data and r objects." arXiv preprint arXiv:1403.2805 (2014).
