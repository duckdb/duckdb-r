.PHONY: all opt unit clean debug release test unittest allunit benchmark docs doxygen format sqlite readme warnings warnings-glue warnings-vendored

all: format-check

format-check:
	python3 scripts/format.py --all --check

format-check-silent:
	python3 scripts/format.py --all --check --silent

format-fix:
	rm -rf src/amalgamation/*
	python3 scripts/format.py --all --fix --noconfirm

format-head:
	python3 scripts/format.py HEAD --fix --noconfirm

format-changes:
	python3 scripts/format.py HEAD --fix --noconfirm

format-main:
	python3 scripts/format.py main --fix --noconfirm

readme:
	R -q -e 'rmarkdown::render("README.Rmd", quiet = TRUE)'

# The compiler-warning gate; handbook/build/warnings/README.md.
warnings: warnings-glue warnings-vendored

warnings-glue:
	scripts/warnings.sh glue

warnings-vendored:
	scripts/warnings.sh vendored
