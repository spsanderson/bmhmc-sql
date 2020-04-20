provider_case_type_pvt <-
function () 
{
    data <- df_tbl %>% pivot_table(.rows = provider_name, .columns = ~case_type, 
        .values = ~COUNT(pt_id), fill_na = 0) %>% rename(non_surgical = `Non-Surgical`, 
        surgical = Surgical) %>% arrange(provider_name) %>% adorn_totals() %>% 
        set_names("Provider", "Non-Surgical", "Surgical") %>% 
        knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12, 
        full_width = T)
    return(data)
}
division_case_type_count <-
function () 
{
    data <- df_tbl %>% pivot_table(.rows = division, .columns = ~case_type, 
        .values = ~COUNT(pt_id), fill_na = 0) %>% rename(division = division, 
        non_surgical = `Non-Surgical`, surgical = Surgical) %>% 
        arrange(division) %>% adorn_totals() %>% set_names("Division", 
        "Non-Surgical", "Surgical") %>% knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12, 
        full_width = T)
    return(data)
}
pyr_grp_count <-
function () 
{
    data <- df_tbl %>% pivot_table(.rows = pyr_group2, .columns = ~case_type, 
        .values = ~COUNT(pt_id), fill_na = 0) %>% mutate(tot_cases = `Non-Surgical` + 
        Surgical) %>% set_names("Payer Group", "Non-Surgical", 
        "Surgical", "Total") %>% arrange(`Payer Group`) %>% adorn_totals() %>% 
        knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12, 
        full_width = T)
    return(data)
}
chgs_pmts_by_provider <-
function () 
{
    data <- df_tbl %>% select(provider_name, tot_chg_amt, implant_chgs, 
        pymts_w_pip, tot_amt_due) %>% group_by(provider_name) %>% 
        summarise(tot_chgs = sum(tot_chg_amt, na.rm = TRUE), 
            implant_chgs = sum(implant_chgs, na.rm = TRUE), pip_pmts = sum(pymts_w_pip, 
                na.rm = TRUE), tot_due = sum(tot_amt_due, na.rm = TRUE)) %>% 
        ungroup() %>% arrange(provider_name) %>% adorn_totals() %>% 
        mutate(tot_chgs = scales::dollar(tot_chgs, accuracy = 1), 
            implant_chgs = scales::dollar(implant_chgs, accuracy = 1), 
            pip_pmts = scales::dollar(pip_pmts, accuracy = 1), 
            tot_due = scales::dollar(tot_due, accuracy = 1)) %>% 
        set_names("Provider", "Total Charges", "Implant Charges", 
            "Payments with PIP", "Total Due") %>% knitr::kable() %>% 
        kableExtra::kable_styling(bootstrap_options = c("striped", 
            "hover", "condensed", "responsive"), font_size = 12, 
            full_width = T)
    return(data)
}
chgs_pmts_by_division <-
function () 
{
    data <- df_tbl %>% select(division, tot_chg_amt, implant_chgs, 
        pymts_w_pip, tot_amt_due) %>% group_by(division) %>% 
        summarise(tot_chgs = sum(tot_chg_amt, na.rm = TRUE), 
            implant_chgs = sum(implant_chgs, na.rm = TRUE), pip_pmts = sum(pymts_w_pip, 
                na.rm = TRUE), tot_due = sum(tot_amt_due, na.rm = TRUE)) %>% 
        ungroup() %>% arrange(division) %>% adorn_totals() %>% 
        mutate(tot_chgs = scales::dollar(tot_chgs, accuracy = 1), 
            implant_chgs = scales::dollar(implant_chgs, accuracy = 1), 
            pip_pmts = scales::dollar(pip_pmts, accuracy = 1), 
            tot_due = scales::dollar(tot_due, accuracy = 1)) %>% 
        set_names("Division", "Total Charges", "Implant Charges", 
            "Payments with PIP", "Total Due") %>% knitr::kable() %>% 
        kableExtra::kable_styling(bootstrap_options = c("striped", 
            "hover", "condensed", "responsive"), font_size = 12, 
            full_width = T)
    return(data)
}
chgs_pmts_by_fc <-
function () 
{
    data <- df_tbl %>% select(pyr_group2, tot_chg_amt, implant_chgs, 
        pymts_w_pip, tot_amt_due) %>% group_by(pyr_group2) %>% 
        summarise(tot_chgs = sum(tot_chg_amt, na.rm = TRUE), 
            implant_chgs = sum(implant_chgs, na.rm = TRUE), pip_pmts = sum(pymts_w_pip, 
                na.rm = TRUE), tot_due = sum(tot_amt_due, na.rm = TRUE)) %>% 
        ungroup() %>% arrange(pyr_group2) %>% adorn_totals() %>% 
        mutate(tot_chgs = scales::dollar(tot_chgs, accuracy = 1), 
            implant_chgs = scales::dollar(implant_chgs, accuracy = 1), 
            pip_pmts = scales::dollar(pip_pmts, accuracy = 1), 
            tot_due = scales::dollar(tot_due, accuracy = 1)) %>% 
        set_names("Payer Group", "Total Charges", "Implant Charges", 
            "Payments with PIP", "Total Due") %>% knitr::kable() %>% 
        kableExtra::kable_styling(bootstrap_options = c("striped", 
            "hover", "condensed", "responsive"), font_size = 12, 
            full_width = T)
    return(data)
}
ip_op_counts_by_provider <-
function () 
{
    data <- df_tbl %>% pivot_table(.rows = provider_name, .columns = ~ip_op, 
        .values = ~COUNT(pt_id), fill_na = 0) %>% rename(provider_name = provider_name, 
        outpatient = O, inpatient = I) %>% arrange(provider_name) %>% 
        adorn_totals() %>% set_names("Provider", "Outpatient", 
        "Inpatient") %>% knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12, 
        full_width = T)
    return(data)
}
ip_op_counts_by_division <-
function () 
{
    data <- df_tbl %>% pivot_table(.rows = division, .columns = ~ip_op, 
        .values = ~COUNT(pt_id), fill_na = 0) %>% rename(division = division, 
        outpatient = O, inpatient = I) %>% arrange(division) %>% 
        adorn_totals() %>% set_names("Division", "Outpatient", 
        "Inpatient") %>% knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12, 
        full_width = T)
    return(data)
}
ip_op_counts_by_fc <-
function () 
{
    data <- df_tbl %>% pivot_table(.rows = pyr_group2, .columns = ~ip_op, 
        .values = ~COUNT(pt_id), fill_na = 0) %>% rename(pyr_group2 = pyr_group2, 
        outpatient = O, inpatient = I) %>% arrange(pyr_group2) %>% 
        adorn_totals() %>% set_names("Payer Group", "Outpatient", 
        "Inpatient") %>% knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12, 
        full_width = T)
    return(data)
}
myhealth_profile_by_provider <-
function () 
{
    visits_tbl <- df_tbl %>% pivot_table(.rows = c(pract_no, 
        ~(provider_name)), .columns = ~case_type, .values = ~COUNT(pt_id), 
        fill_na = 0) %>% set_names("pract_no", "provider_name", 
        "surgical", "non_surgical") %>% mutate(total_visits = (surgical + 
        non_surgical))
    dollars_tbl <- df_tbl %>% select(pract_no, tot_chg_amt, implant_chgs, 
        pymts_w_pip, tot_amt_due) %>% group_by(pract_no) %>% 
        summarise(tot_chgs = sum(tot_chg_amt, na.rm = TRUE), 
            implant_chgs = sum(implant_chgs, na.rm = TRUE), pip_pmts = sum(pymts_w_pip, 
                na.rm = TRUE), tot_due = sum(tot_amt_due, na.rm = TRUE)) %>% 
        ungroup() %>% mutate(chgs_net_imp_cost = (tot_chgs - 
        implant_chgs) * 0.18, implant_cost = (implant_chgs * 
        0.18), total_cost = (chgs_net_imp_cost + implant_cost), 
        net_rev = (((pip_pmts * -1) - total_cost) + (0.5 * tot_due)))
    final_tbl <- left_join(x = visits_tbl, y = dollars_tbl, by = c(pract_no = "pract_no")) %>% 
        select(provider_name, total_visits, tot_chgs, implant_chgs, 
            pip_pmts, tot_due, chgs_net_imp_cost, implant_cost, 
            total_cost, net_rev) %>% adorn_totals() %>% mutate(total_visits = scales::number(total_visits, 
        accuracy = 1, big.mark = ","), tot_chgs = scales::dollar(tot_chgs, 
        accuracy = 1), implant_chgs = scales::dollar(implant_chgs, 
        accuracy = 1), pip_pmts = scales::dollar(pip_pmts, accuracy = 1), 
        tot_due = scales::dollar(tot_due, accuracy = 1), chgs_net_imp_cost = scales::dollar(chgs_net_imp_cost, 
            accuracy = 1), implant_cost = scales::dollar(implant_cost, 
            accuracy = 1), total_cost = scales::dollar(total_cost, 
            accuracy = 1), net_rev = scales::dollar(net_rev, 
            accuracy = 1)) %>% set_names("Provider", "Visits", 
        "Charges", "Implant Charges", "Payments", "Total Due", 
        "Cost Net Implants", "Implant Cost", "Total Cost", "Net Revenue") %>% 
        knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12, 
        full_width = T)
    return(final_tbl)
}
myhealth_profile_by_division <-
function () 
{
    visits_tbl <- df_tbl %>% pivot_table(.rows = division, .values = ~COUNT(pt_id), 
        fill_na = 0) %>% set_names("division", "visits")
    dollars_tbl <- df_tbl %>% select(division, tot_chg_amt, implant_chgs, 
        pymts_w_pip, tot_amt_due) %>% group_by(division) %>% 
        summarise(tot_chgs = sum(tot_chg_amt, na.rm = TRUE), 
            implant_chgs = sum(implant_chgs, na.rm = TRUE), pip_pmts = sum(pymts_w_pip, 
                na.rm = TRUE), tot_due = sum(tot_amt_due, na.rm = TRUE)) %>% 
        ungroup() %>% mutate(chgs_net_imp_cost = (tot_chgs - 
        implant_chgs) * 0.18, implant_cost = (implant_chgs * 
        0.18), total_cost = (chgs_net_imp_cost + implant_cost), 
        net_rev = (((pip_pmts * -1) - total_cost) + (0.5 * tot_due)))
    final_tbl <- left_join(x = visits_tbl, y = dollars_tbl, by = c(division = "division")) %>% 
        adorn_totals() %>% mutate(visits = scales::number(visits, 
        accuracy = 1, big.mark = ","), tot_chgs = scales::dollar(tot_chgs, 
        accuracy = 1), implant_chgs = scales::dollar(implant_chgs, 
        accuracy = 1), pip_pmts = scales::dollar(pip_pmts, accuracy = 1), 
        tot_due = scales::dollar(tot_due, accuracy = 1), chgs_net_imp_cost = scales::dollar(chgs_net_imp_cost, 
            accuracy = 1), implant_cost = scales::dollar(implant_cost, 
            accuracy = 1), total_cost = scales::dollar(total_cost, 
            accuracy = 1), net_rev = scales::dollar(net_rev, 
            accuracy = 1)) %>% set_names("Division", "Visits", 
        "Charges", "Implant Charges", "Payments", "Total Due", 
        "Cost Net Implants", "Implant Cost", "Total Cost", "Net Revenue") %>% 
        knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12, 
        full_width = T)
    return(final_tbl)
}
myhealth_profile_by_fc <-
function () 
{
    visits_tbl <- df_tbl %>% pivot_table(.rows = pyr_group2, 
        .values = ~COUNT(pt_id), fill_na = 0) %>% set_names("fin_class", 
        "visits")
    dollars_tbl <- df_tbl %>% select(pyr_group2, tot_chg_amt, 
        implant_chgs, pymts_w_pip, tot_amt_due) %>% group_by(pyr_group2) %>% 
        summarise(tot_chgs = sum(tot_chg_amt, na.rm = TRUE), 
            implant_chgs = sum(implant_chgs, na.rm = TRUE), pip_pmts = sum(pymts_w_pip, 
                na.rm = TRUE), tot_due = sum(tot_amt_due, na.rm = TRUE)) %>% 
        ungroup() %>% mutate(chgs_net_imp_cost = (tot_chgs - 
        implant_chgs) * 0.18, implant_cost = (implant_chgs * 
        0.18), total_cost = (chgs_net_imp_cost + implant_cost), 
        net_rev = (((pip_pmts * -1) - total_cost) + (0.5 * tot_due)))
    final_tbl <- left_join(x = visits_tbl, y = dollars_tbl, by = c(fin_class = "pyr_group2")) %>% 
        select(fin_class, visits, tot_chgs, implant_chgs, pip_pmts, 
            tot_due, chgs_net_imp_cost, implant_cost, total_cost, 
            net_rev) %>% adorn_totals() %>% mutate(visits = scales::number(visits, 
        accuracy = 1, big.mark = ","), tot_chgs = scales::dollar(tot_chgs, 
        accuracy = 1), implant_chgs = scales::dollar(implant_chgs, 
        accuracy = 1), pip_pmts = scales::dollar(pip_pmts, accuracy = 1), 
        tot_due = scales::dollar(tot_due, accuracy = 1), chgs_net_imp_cost = scales::dollar(chgs_net_imp_cost, 
            accuracy = 1), implant_cost = scales::dollar(implant_cost, 
            accuracy = 1), total_cost = scales::dollar(total_cost, 
            accuracy = 1), net_rev = scales::dollar(net_rev, 
            accuracy = 1)) %>% set_names("Fin Class", "Visits", 
        "Charges", "Implant Charges", "Payments", "Total Due", 
        "Cost Net Implants", "Implant Cost", "Total Cost", "Net Revenue") %>% 
        knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12, 
        full_width = T)
    return(final_tbl)
}
myhealth_profile_year_provider <-
function () 
{
    data <- df_tbl %>% pivot_table(.rows = c(provider_name, ~(procedure_year)), 
        .values = c(~COUNT(pt_id), ~SUM(tot_chg_amt), ~SUM(implant_chgs), 
            ~SUM(pymts_w_pip), ~SUM(tot_amt_due))) %>% arrange(provider_name, 
        `(procedure_year)`) %>% set_names("Provider", "Year", 
        "Visits", "Charges", "Implant_Charges", "Pmts_w_Pip", 
        "Total_Due") %>% mutate(tot_cost = ((Charges - Implant_Charges) * 
        0.18) + (Implant_Charges * 0.18), net_rev = ((-1 * Pmts_w_Pip) - 
        tot_cost) + (0.5 * Total_Due)) %>% mutate(Year = as.character(Year)) %>% 
        adorn_totals() %>% mutate(Visits = scales::number(Visits, 
        big.mark = ","), Charges = scales::dollar(Charges, accuracy = 1), 
        Implant_Charges = scales::dollar(Implant_Charges, accuracy = 1), 
        Pmts_w_Pip = scales::dollar(Pmts_w_Pip, accuracy = 1), 
        Total_Due = scales::dollar(Total_Due, accuracy = 1), 
        tot_cost = scales::dollar(tot_cost, accuracy = 1), net_rev = scales::dollar(net_rev, 
            accuracy = 1)) %>% set_names("Provider", "Year", 
        "Visits", "Charges", "Implant Charges", "Payments W PIP", 
        "Total Due", "Total Cost", "Net Revenue") %>% knitr::kable() %>% 
        kableExtra::kable_styling(bootstrap_options = c("striped", 
            "hover", "condensed", "responsive"), font_size = 12, 
            full_width = T)
    return(data)
}
myhealth_profile_year_division <-
function () 
{
    data <- df_tbl %>% pivot_table(.rows = c(division, ~(procedure_year)), 
        .values = c(~COUNT(pt_id), ~SUM(tot_chg_amt), ~SUM(implant_chgs), 
            ~SUM(pymts_w_pip), ~SUM(tot_amt_due))) %>% arrange(division, 
        `(procedure_year)`) %>% set_names("Division", "Year", 
        "Visits", "Charges", "Implant_Charges", "Pmts_w_Pip", 
        "Total_Due") %>% mutate(tot_cost = ((Charges - Implant_Charges) * 
        0.18) + (Implant_Charges * 0.18), net_rev = ((-1 * Pmts_w_Pip) - 
        tot_cost) + (0.5 * Total_Due)) %>% mutate(Year = as.character(Year)) %>% 
        adorn_totals() %>% mutate(Visits = scales::number(Visits, 
        big.mark = ","), Charges = scales::dollar(Charges, accuracy = 1), 
        Implant_Charges = scales::dollar(Implant_Charges, accuracy = 1), 
        Pmts_w_Pip = scales::dollar(Pmts_w_Pip, accuracy = 1), 
        Total_Due = scales::dollar(Total_Due, accuracy = 1), 
        tot_cost = scales::dollar(tot_cost, accuracy = 1), net_rev = scales::dollar(net_rev, 
            accuracy = 1)) %>% set_names("Division", "Year", 
        "Visits", "Charges", "Implant Charges", "Payments W PIP", 
        "Total Due", "Total Cost", "Net Revenue") %>% knitr::kable() %>% 
        kableExtra::kable_styling(bootstrap_options = c("striped", 
            "hover", "condensed", "responsive"), font_size = 12, 
            full_width = T)
    return(data)
}
myhealth_profile_year_fc <-
function () 
{
    data <- df_tbl %>% pivot_table(.rows = c(pyr_group2, ~(procedure_year)), 
        .values = c(~COUNT(pt_id), ~SUM(tot_chg_amt), ~SUM(implant_chgs), 
            ~SUM(pymts_w_pip), ~SUM(tot_amt_due))) %>% arrange(pyr_group2, 
        `(procedure_year)`) %>% set_names("Payer Group", "Year", 
        "Visits", "Charges", "Implant_Charges", "Pmts_w_Pip", 
        "Total_Due") %>% mutate(tot_cost = ((Charges - Implant_Charges) * 
        0.18) + (Implant_Charges * 0.18), net_rev = ((-1 * Pmts_w_Pip) - 
        tot_cost) + (0.5 * Total_Due)) %>% mutate(Year = as.character(Year)) %>% 
        adorn_totals() %>% mutate(Visits = scales::number(Visits, 
        big.mark = ","), Charges = scales::dollar(Charges, accuracy = 1), 
        Implant_Charges = scales::dollar(Implant_Charges, accuracy = 1), 
        Pmts_w_Pip = scales::dollar(Pmts_w_Pip, accuracy = 1), 
        Total_Due = scales::dollar(Total_Due, accuracy = 1), 
        tot_cost = scales::dollar(tot_cost, accuracy = 1), net_rev = scales::dollar(net_rev, 
            accuracy = 1)) %>% set_names("Payer Group", "Year", 
        "Visits", "Charges", "Implant Charges", "Payments W PIP", 
        "Total Due", "Total Cost", "Net Revenue") %>% knitr::kable() %>% 
        kableExtra::kable_styling(bootstrap_options = c("striped", 
            "hover", "condensed", "responsive"), font_size = 12, 
            full_width = T)
    return(data)
}
myhealth_profile_year <-
function () 
{
    data <- df_tbl %>% pivot_table(.rows = procedure_year, .values = c(~COUNT(pt_id), 
        ~SUM(tot_chg_amt), ~SUM(implant_chgs), ~SUM(pymts_w_pip), 
        ~SUM(tot_amt_due))) %>% arrange(procedure_year) %>% set_names("Year", 
        "Visits", "Charges", "Implant_Charges", "Pmts_w_Pip", 
        "Total_Due") %>% mutate(tot_cost = ((Charges - Implant_Charges) * 
        0.18) + (Implant_Charges * 0.18), net_rev = ((-1 * Pmts_w_Pip) - 
        tot_cost) + (0.5 * Total_Due)) %>% mutate(Year = as.character(Year)) %>% 
        adorn_totals() %>% mutate(Visits = scales::number(Visits, 
        big.mark = ","), Charges = scales::dollar(Charges, accuracy = 1), 
        Implant_Charges = scales::dollar(Implant_Charges, accuracy = 1), 
        Pmts_w_Pip = scales::dollar(Pmts_w_Pip, accuracy = 1), 
        Total_Due = scales::dollar(Total_Due, accuracy = 1), 
        tot_cost = scales::dollar(tot_cost, accuracy = 1), net_rev = scales::dollar(net_rev, 
            accuracy = 1)) %>% set_names("Year", "Visits", "Charges", 
        "Implant Charges", "Payments W PIP", "Total Due", "Total Cost", 
        "Net Revenue") %>% knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12, 
        full_width = T)
    return(data)
}
consults_by_provider <-
function () 
{
    data <- coded_consults_tbl %>% count(provider_name) %>% arrange(provider_name) %>% 
        set_names("Provider", "Consults") %>% knitr::kable() %>% 
        kableExtra::kable_styling(bootstrap_options = c("striped", 
            "hover", "condensed", "responsive"), font_size = 12, 
            full_width = FALSE, position = "left")
    return(data)
}
consults_by_division <-
function () 
{
    data <- coded_consults_tbl %>% count(division) %>% arrange(division) %>% 
        set_names("Division", "Consults") %>% knitr::kable() %>% 
        kableExtra::kable_styling(bootstrap_options = c("striped", 
            "hover", "condensed", "responsive"), font_size = 12, 
            full_width = FALSE, position = "left")
    return(data)
}
consults_by_provider_year <-
function () 
{
    data <- coded_consults_tbl %>% mutate(dsch_yr = year(dsch_date)) %>% 
        arrange(provider_name, dsch_yr) %>% count(provider_name, 
        dsch_yr) %>% pivot_wider(values_from = n, names_from = dsch_yr, 
        id_cols = provider_name, values_fill = list(n = 0)) %>% 
        pivot_longer(cols = -provider_name, names_to = "year") %>% 
        pivot_table(.rows = provider_name, .columns = ~year, 
            .values = ~value) %>% rename(Provider = provider_name) %>% 
        knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12)
    return(data)
}
consults_by_division_year <-
function () 
{
    data <- coded_consults_tbl %>% mutate(dsch_yr = year(dsch_date)) %>% 
        arrange(division, dsch_yr) %>% count(division, dsch_yr) %>% 
        pivot_wider(values_from = n, names_from = dsch_yr, id_cols = division, 
            values_fill = list(n = 0)) %>% pivot_longer(cols = -division, 
        names_to = "year") %>% pivot_table(.rows = division, 
        .columns = ~year, .values = ~value) %>% rename(Division = division) %>% 
        knitr::kable() %>% kableExtra::kable_styling(bootstrap_options = c("striped", 
        "hover", "condensed", "responsive"), font_size = 12)
    return(data)
}
