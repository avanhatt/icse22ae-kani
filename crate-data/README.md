# Crate Data Extractor

This little Python tool gets the top-ranked crates from [the Crates.io data dump][crates-data] and measures some aspect of their code.

Type `make` to regenerate the data files in this directory.

## Analyzing Crate Code

The only requirements should be Python itself and [curl][].

Run the script to download the data and extract some information:

    python3 crate_scrape.py

The tool will download a `db-dump.tar.gz` file once and reuse it when run again. To fetch fresh data, just delete that file and re-run the script.

The tool prints a CSV to standard output consisting of some basic data about the crates and the results of running the report command on each.

To control the number of (top) crates to analyze, pass a positional argument `N`. The tool runs a shell command to extract data from each crate; set the `REPORT_CMD` constant to the command you want to run. The command is a [Python template string][template], so insert `{}` where you want the code directory name to appear. 

By default, this counts (1) explicit use of dynamic trait objects with by searching for the `dyn` keyword, and (2) implicit use of dynamic trait objects by searching for calls to `get_vtable`.

[crates-data]: https://crates.io/data-access
[curl]: https://curl.se
[template]: https://docs.python.org/3/library/string.html#format-string-syntax

## Summary Statistics

Translate the collected data into summary statistics using `summarize.py`. Just pipe the resulting CSV from `crate_scrape.py` into this script to produce a few useful values.
