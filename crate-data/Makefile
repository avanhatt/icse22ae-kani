.PHONY: COUNTS 

default: COUNTS
	echo "Summary for explicit trait counts"
	python3 summarize.py < explicit.json
	echo "Summary for implicit trait counts"
	python3 summarize.py < implicit.json

.PRECIOUS: counts.csv
COUNTS:
	python3 crate_scrape.py --explicit > explicit.json
	python3 crate_scrape.py --implicit > implicit.json

