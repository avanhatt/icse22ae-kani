.PHONY: COUNTS 

default: COUNTS
	$(info Summary for trait counts)
	python3 summarize.py < explicit.json
	python3 summarize.py < implicit.json

.PRECIOUS: counts.csv
COUNTS:
	$(info Scraping trait counts)
	python3 crate_scrape.py --explicit > explicit.json
	python3 crate_scrape.py --implicit > implicit.json

