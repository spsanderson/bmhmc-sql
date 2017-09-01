SELECT Ucase("''" & [unique personal identifier] & "'';") AS unique_personal_identifier
, "''" & [patient control number] & "'';" AS patient_control_number
, "''" & [date of birth] & "'';" AS date_of_birth
, "''" & [gender] & "'';" AS _gender
, [race]
, "''" & [ethnicity] & "'';" AS _ethnicity
, "''" & [payer] & "'';" AS _payer
, Ucase("''" & [insurance number] & "'';") AS insurance_number
, "''" & [medical record number] & "'';" AS medical_record_number
, "''" & [facility identifier] & "'';" AS facility_identifier
, "''" & [admission datetime] & "'';" AS admission_datetime
, "''" & [source of admission] & "'';" AS source_of_admission
, "''" & [discharge datetime] & "'';" AS discharge_datetime
, "''" & [discharge status] & "'';" AS discharge_status
, "''" & [protocol initiated] & "'';" AS protocol_initiated
, "''" & [protocol initiated place] & "'';" AS protocol_initiated_place
, "''" & [protocol type] & "'';" AS protocol_type
, "''" & [excluded from protocol] & "'';" AS excluded_from_protocol
, "''" & [excluded reason] & "'';" AS excluded_reason
, "''" & [excluded datetime] & "'';" AS excluded_datetime
, [excluded explain]
, "''" & [earliest time] & "'';" AS earliest_time
, "''" & [triage datetime] & "'';" AS triage_datetime
, "''" & [protocol datetime] & "'';" AS protocol_datetime
, "''" & [vascular or intraosseous access datetime] & "'';" AS vascular_or_intraosseous_access_datetime
, "''" & [left ed datetime] & "'';" AS left_ed_datetime
, "''" & [destination after ed] & "'';" AS destination_after_ed
, "''" & [lactate reported] & "'';" AS lactate_reported
, "''" & [lactate reported datetime] & "'';" AS lactate_reported_datetime
, "''" & [lactate level] & "'';" AS lactate_level
, "''" & [lactate level unit] & "'';" AS lactate_level_unit
, "''" & [lactate re-ordered] & "'';" AS lactate_reordered
, "''" & [lactate re-ordered datetime] AS lactate_reordered_datetime
, "''" & [blood cultures obtained] & "'';" AS blood_cultures_obtained
, "''" & [BLOOD CULTURES OBTAINED DATETIME] & "'';" AS blood_cultures_obtained_datetime
, "''" & [blood cultures result] & "'';" AS blood_cultures_result
, "''" & [blood cultures pathogen] & "'';" AS blood_cultures_pathogen
, "''" & [antibiotics given] & "'';" AS antibiotics_given
, "''" & [antibiotics start datetime] & "'';" AS antibiotics_start_datetime
, "''" & [adult fluids] & "'';" AS adult_fluids
, "''" & [pediatric fluids] & "'';" AS pediatric_fluids
, "''" & [fluids completed datetime] & "'';" AS fluids_completed_datetime
, [fluids assessment]
, "''" & [hypotension] & "'';" AS _hypotension
, "''" & [vasopressors given] & "'';" AS vasopressors_gvien
, "''" & [vasopressors given datetime] & "'';" AS vasopressors_given_datetime
, "''" & [cvp measured] & "'';" AS cvp_measured
, "''" & [cvp measured datetime] & "'';" AS cvp_measured_datetime
, "''" & [scvo2 measured] & "'';" AS scvo2_measured
, "''" & [scvo2 measured datetime] & "'';" AS scvo2_measured_datetime
, "''" & [platelet count] & "'';" AS platelet_count
, "''" & [bandemia] & "'';" AS _bandemia
, "''" & [lower respiratory infection] & "'';" AS lower_respiratory_infection
, "''" & [altered mental status] & "'';" AS altered_mental_status
, "''" & [septic shock diagnosis] & "'';" AS septic_shock_diagnosis
, "''" & [infection etiology] & "'';" AS infection_etiology
, "''" & [site of infection] & "'';" AS site_of_infection
, "''" & [mechanical ventilation] & "'';" AS mechanical_ventilation
, "''" & [mechanical ventilation datetime] & "'';" AS mechanical_ventilation_datetime
, "''" & [icu] & "'';" AS _icu
, "''" & [icu admission datetime] & "'';" AS icu_admission_datetime
, "''" & [icu discharge datetime] & "'';" AS icu_discharge_datetime
, "''" & [chronic respiratory failure] & "'';" AS chronic_respiratory_failure
, "''" & [AIDS/HIV DISEASE] & "'';" AS aids_hiv_disease
, "''" & [metastatic cancer] & "'';" AS metastatic_cancer
, "''" & [lymphoma/leukemia/multiple myeloma] & "'';" AS lymphoma_leukemia_multiple_myeloma
, "''" & [immune modifying medications] & "'';" AS immunce_modifying_medications
, "''" & [congestive heart failure] & "'';" AS congestive_heart_failure
, "''" & [chronic renal failure] & "'';" AS chronic_renal_failure
, "''" & [chronic liver disease] & "'';" AS chronic_liver_disease
, "''" & [diabetes] & "'';" AS _diabetes
, "''" & [organ transplant] & "'';" AS organ_transplant

FROM sepsis;
