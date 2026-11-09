Original NHIS Sample Adult data

The unchanged CDC archives are work/raw/adult22csv.zip and work/raw/adult25csv.zip
in the repository. They contain the complete 2022 and 2025 public-use Adult CSVs,
with 27651 and 24215 adult records respectively. The 65+ restriction and all
recoding are applied separately by outputs/01_prepare.R.

original_data_manifest.tsv records the source URLs, SHA-256 hashes, byte sizes,
CSV record counts and column counts. The extracted CSVs are byte-identical to
their archive entries. The CSVs are not duplicated in the repository; preparation
extracts them from the original ZIPs without changing the source archives.

NHIS nonresponse codes and structural blanks must not be treated as ordinary
numeric values. HHX identifies a record within a survey year, not a longitudinal
person identifier. Official NHIS data-use terms apply, including no attempted
identification. The analysis uses only public-use data.

https://www.cdc.gov/nchs/nhis/documentation/2022-nhis.html
https://www.cdc.gov/nchs/nhis/documentation/2025-nhis.html
