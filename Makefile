all: other_support_brokamp.md other_support_brokamp.docx
		R CMD BATCH parse_support.R

other_support_brokamp.md: support.yaml parse_support.R
		R CMD BATCH parse_support.R

other_support_brokamp.docx: other_support_brokamp.md reference.dotx
		pandoc other_support_brokamp.md --reference-doc=reference.dotx -o other_support_brokamp.docx

sign:
		open -a "PDF Expert.App" other_support_brokamp.docx
