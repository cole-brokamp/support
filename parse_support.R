library(dplyr)
library(tidyr)
library(purrr)
library(glue)

c("Name of Individual: Cole Brokamp",
  "Commons ID: brokampr",
  "## Other Support – Project/Proposal\n\n") %>%
  cat(file = "other_support_brokamp.md", sep = "\n\n", append = FALSE)

d <-
  yaml::yaml.load_file("support.yaml") %>%
  tibble::enframe(name = "id", value = "support_data") %>%
  mutate(status = map_chr(support_data, "status"))

d$status <- factor(d$status, levels = c("Active", "Pending", "Completed"))
d <- arrange(d, status)

make_support_entry <- function(.x = d$support_data[[5]]) {

  start_date <- as.Date(.x$start_date, format = "%m/%d/%y")
  end_date <- as.Date(.x$end_date, format = "%m/%d/%y")
  today <- Sys.Date()
  year <- as.numeric(format(today, "%Y"))

  # if project is older than three years, don't show it
  if ((end_date - today) < -(365 * 3)) {
    return(NULL)
  }

  dates <- glue(
    "{format(start_date, format = '%m/%Y')}",
    " — ",
    "{format(end_date, format = '%m/%Y')}"
  )

  # only try to format numeric amounts 
  if (is.numeric(.x$amount)) {
    .x$amount <- scales::dollar(.x$amount)
  }

  out <-
    with(.x, glue::glue(
    "Title: {title}  \n",
    "Major Goals: {goals}  \n",
    "Status of Support: {status}  \n",
    "Project Number: {number}  \n",
    "Name of PD/PI: {pi_name}  \n",
    "Source of Support: {source}  \n",
    "Primary Place of Performance: {ppp}  \n",
    "Project/Proposal Start and End Date: {dates}  \n",
    "Total Award Amount: {amount}  \n"
  ))


  # calculate current effort table only for pending and active projects
  if (.x$status %in% c("Active", "Pending")) {
    out <- glue("{out}\nPerson Months (Calendar) per budget period:")
    effort_table <-
      .x$effort %>%
      tibble::enframe(name = "Year", value = "Person Months") %>%
      mutate(`Person Months` = unlist(`Person Months`)) %>%
      mutate(year_number = as.numeric(Year)) %>%
      mutate(Year = paste(1:length(.x$effort), Year, sep = ". ")) %>%
      filter(year_number - year >= -1) %>%
      filter(`Person Months` > 0) %>%
      select(-year_number) %>%
      knitr::kable(digits = 2, align = "cc")

    out <- c(out, "  ", paste(effort_table, collapse = "\n"), "\n  ")
  } else {
    out <- c(out, "\n  ")
    }

  return(out)

}

safely_make_support_entry <- purrr::possibly(make_support_entry, otherwise = NA)

purrr::map(d$support_data, safely_make_support_entry) %>%
  unlist() %>%
  cat(file = "other_support_brokamp.md", sep = "\n", append = TRUE)

c("## In-Kind",
  "Not Applicable\n\n") %>%
  cat(file = "other_support_brokamp.md", sep = "\n\n", append = TRUE)

boilerplate <- c(
  "Overlap: There is no scientific overlap between funded and pending projects. Where budget overlap occurs between funded projects, Dr. Brokamp will make appropriate adjustments to reduce his effort in order not to exceed a total committed effort of 12.0 calendar months across all funded projects and work with appropriate institutional administration to resolve any conflicts.",
  ## "I, PD/PI or other senior/key personnel, certify that the statements herein are true, complete and accurate to the best of my knowledge, and accept the obligation to comply with Public Health Services terms and conditions if a grant is awarded as a result of this application. I am aware that any false, fictitious, or fraudulent statements or claims may subject me to criminal, civil, or administrative penalties.",
  ## "Signature:",
  glue("Date: {Sys.Date()}")
)

cat(boilerplate, file = "other_support_brokamp.md", sep = "\n\n", append = TRUE)
