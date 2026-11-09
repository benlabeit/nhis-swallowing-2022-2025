Original NHIS Sample Adult data

The current repository does not include the original data archives. Run
Rscript outputs/01_prepare.R from the repository root after setup to download
missing archives directly from the CDC into work/raw/:

2022: https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2022/adult22csv.zip
2025: https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2025/adult25csv.zip

The archives contain the complete public-use Adult CSVs, with 27651 and 24215
adult records respectively. Preparation extracts them locally without changing
the source archives; the 65+ restriction and recoding are applied separately.
Downloaded archives, extracted CSVs and derived individual-record working data
are excluded from version control. Earlier Git revisions retain the archives;
the existing history has not been rewritten.

original_data_manifest.tsv records source URLs, SHA-256 hashes, byte sizes,
CSV record counts and column counts for comparison with downloaded files.
The preparation script records an MD5 checksum in outputs/download_manifest.tsv;
it does not automatically validate against the recorded SHA-256 hashes.

NHIS nonresponse codes and structural blanks must not be treated as ordinary
numeric values. HHX identifies a record within a survey year, not a longitudinal
person identifier. Official NHIS data-use terms apply, including no attempted
identification. The analysis uses only public-use data.

https://www.cdc.gov/nchs/nhis/documentation/2022-nhis.html
https://www.cdc.gov/nchs/nhis/documentation/2025-nhis.html
