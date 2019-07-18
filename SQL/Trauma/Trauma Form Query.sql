SELECT MasterDemographics.EncounterNumber
, MasterDemographics.DateofReport
, MasterDemographics.AdmitDate
, MasterDemographics.NatureofEvent
, MasterDemographics.DateofEvent
, MasterDemographics.TimeofEvent
, MasterDemographics.Age
, MasterDemographics.Gender
, MasterDemographics.Diagnosis
, MasterDemographics.LevelofActivation
, MasterDemographics.otherPertinentInformation
, MasterDemographics.ReportCompletedBy
, MasterSourceofInformation.TraumaProgramManager
, MasterSourceofInformation.PICoordinator
, MasterSourceofInformation.TraumaRegisty
, MasterSourceofInformation.NursingStaff
, MasterSourceofInformation.AdministrativeStaff
, MasterSourceofInformation.Physician
, MasterSourceofInformation.TraumaMedicalDirector
, MasterSourceofInformation.Rounds
, MasterSourceofInformation.Registry
, MasterSourceofInformation.Patient
, MasterSourceofInformation.PatientFamily
, MasterSourceofInformation.PhysicalTherapy
, MasterSourceofInformation.Prehospital
, MasterSourceofInformation.Rehab
, MasterSourceofInformation.SocialServices
, MasterSourceofInformation.ChaplinServices
, MasterSourceofInformation.Other
, ImpactPhysical.NoHarm
, ImpactPhysical.NoDetectableHarm
, ImpactPhysical.MildTemporaryHarm
, ImpactPhysical.MildPermanentHarm
, ImpactPhysical.ModerateTemporaryHarm
, ImpactPhysical.ModeratePermanentHarm
, ImpactPhysical.SevereTemporaryHarm
, ImpactPhysical.SeverePermanentHarm
, ImpactPhysical.Death
, ImpactPsychological.NoHarmPsych
, ImpactPsychological.NoDetectableHarmPsych
, ImpactPsychological.MildTemporaryHarmPscyh
, ImpactPsychological.MildPermanentHarmPscyh
, ImpactPsychological.ModerateTemporaryHarmPsych
, ImpactPsychological.ModeratePermanentHarmPsych
, ImpactPsychological.SevereTemporaryHarmPsych
, ImpactPsychological.SeverePermanentHarmPsych
, ImpactPsychological.ProfoundMentalHarmPsych
, ImpactLegal.RiskManagementContacted
, ImpactLegal.ComplaintRegistered
, ImpactLegal.SuitFiled
, ImpactLegal.CaseDropped
, ImpactLegal.CaseDismissed
, ImpactLegal.Settled
, ImpactLegal.DefenseVerdict
, ImpactLegal.PlaintiffVerdict
, ImpactPatientFamilySatisfaction.ExtremelySatisfied
, ImpactPatientFamilySatisfaction.Satisfied
, ImpactPatientFamilySatisfaction.Neutral
, ImpactPatientFamilySatisfaction.Dissatisfied
, ImpactPatientFamilySatisfaction.ExtremelyDissatisfied
, ImpactSocial.UnabletoSocialize
, ImpactSocial.HomeboundAbleToSocialize
, ImpactSocial.NoSocialImpedimentsNotSociallyActive
, ImpactSocial.SociallyActive
, ImpactEmployment.Employed
, ImpactEmployment.SeekingEmployment
, ImpactEmployment.PartTimeEmployement
, ImpactEmployment.Unemployed
, ImpactEmployment.NotEmployable
, ImpactMonetary.BillableCostofCare
, ImpactMonetary.CostsofCare
, ImpactMonetary.TotalCollections
, TypeCommunication.InaccurateorIncompleteInformation
, TypeCommunication.QuestionableAdviceInterpretation
, TypeCommunication.QuestionableConsentProcess
, TypeCommunication.QuestionableDisclosureProcess
, TypeCommunication.QuestionableDocumentation
, TypePatientManagement.Airway
, TypePatientManagement.Breathing
, TypePatientManagement.Circulation
, TypePatientManagement.Neurologic
, TypePatientManagement.Gastrointestinal
, TypePatientManagement.Nutritional
, TypePatientManagement.Urologic
, TypePatientManagement.Orthopedic
, TypePatientManagement.DelegationofCareorTasks
, TypePatientManagement.PatientCareFlowTracking
, TypePatientManagement.PatientFollowup
, TypePatientManagement.ConsultationorReferral
, TypePatientManagement.ResourceUtilization
, TypePatientManagement.resuscitation
, TypePatientManagement.IntensiveCare
, TypePatientManagement.WoundCare
, ClinicalPerformancePreInterventional.EncounterNumber AS EncounterNumber_ClinicalPerformancePreInterventional
, ClinicalPerformancePreInterventional.CorrectDiagnosisQuestinableIntervention
, ClinicalPerformancePreInterventional.InaccurateDiagnosis
, ClinicalPerformancePreInterventional.IncompleteDiagnosis
, ClinicalPerformancePreInterventional.QuestionableDiagnosis
, ClinicalPerformanceInterventional.CorrectProcedureWithComplications
, ClinicalPerformanceInterventional.CorrectProdedureIncorrectlyPerformed
, ClinicalPerformanceInterventional.CorrectProcedurebutUntimely
, ClinicalPerformanceInterventional.OmissionofEssentialProcedure
, ClinicalPerformanceInterventional.ProcedureContraindicated
, ClinicalPerformanceInterventional.ProcedureNotIndicated
, ClinicalPerformanceInterventional.QuestinableProcedure
, ClinicalPerformanceInterventional.WrongPatient
, ClinicalPerformancePostInterventional.CorrectPrognosis
, ClinicalPerformancePostInterventional.InaccuratePrognosis
, ClinicalPerformancePostInterventional.IncompletePrognosis
, ClinicalPerformancePostInterventional.QuestionablePrognosis
, DomainPhase.Evaluation
, DomainPhase.ResuscitationDomainPhase
, DomainPhase.Operative
, DomainPhase.CriticalCare
, DomainPhase.Recovery
, DomainPhase.Rehabilitation
, DomainTarget.Cosmetic
, DomainTarget.Diagnostic
, DomainTarget.OtherDomainTarget
, DomainTarget.Palliative
, DomainTarget.Preventative
, DomainTarget.Reconstrutive
, DomainTarget.Rehabilitative
, DomainTarget.Research
, DomainTarget.Therapeutic
, TypeClinicalPerformance.PreInterventional
, SettingHospital.AmbulatoryCare
, SettingHospital.CatheterizationLaboratory
, SettingHospital.ClinicalWard
, SettingHospital.DiagnosticProcedures
, SettingHospital.EmergencyRoom
, SettingHospital.Hospice
, SettingHospital.InpatientMentalHealth
, SettingHospital.InpatientRehavilitation
, SettingHospital.IntensiveCareUnit
, SettingHospital.InterventionalRadioloy
, SettingHospital.OperatingRoom
, SettingHospital.OutpatientBehavioralHealth
, SettingHospital.Pharmacy
, SettingHospital.PhysicalTherapySettingHospital
, SettingHospital.PsychiatricUnitSettingHospital
, SettingHospital.RehabilitationSettingHospital
, SettingHospital.OtherSettingHospital
, SettingNonHospital.EMSAeromdicalTransportVehicleNonHospital
, SettingNonHospital.EMSGroundTransportVehicleNonHospital
, SettingNonHospital.HomeNonHospital
, SettingNonHospital.HospiceNonHospital
, SettingNonHospital.LongTermCareFacilityNonHospital
, SettingNonHospital.MentalHealthFacilityNonHospital
, SettingNonHospital.NursingHomeNonHospital
, SettingNonHospital.PractitionersOfficeNonHospital
, SettingNonHospital.PsychiatricHospitalNonHospital
, SettingNonHospital.RehabilitationFacilityNonHospital
, SettingNonHospital.OtherFacilityNonHospital
, SettingNonHospital.SceneNonHospital
, StaffPhysicians.Intern
, StaffPhysicians.Resident
, StaffPhysicians.Attending
, StaffPhysicians.dentist
, StaffPhysicians.Podiatrist
, StaffPhysicians.PhysicianAssistant
, StaffNurses.NursesAid
, StaffNurses.LicensedPracticalNurse
, StaffNurses.RegisteredNurse
, StaffNurses.NursePractitioner
, StaffTherapists.PhysicalTherapist
, StaffTherapists.OccupationalTherapist
, StaffTherapists.SpeechTherapist
, StaffOther.HealthProfessionalStudent
, StaffOther.Pharmacist
, StaffOther.PharmacyTechnician
, StaffOther.RadiationTechnician
, StaffOther.Optometrist
, StaffOther.OtherStaffOther
, ActionPlanAndLoopClousre.ActionPlanAndLoopClosure
, TypeClinicalPerformance.Interventional
, TypeClinicalPerformance.PostInterventional
, HumanFactors.[Patient factor]
, HumanFactors.[Practitioner skill-based]
, HumanFactors.[Practitioner rule-based]
, HumanFactors.[Practitioner knowledge-based]
, HumanFactors.[Practitioner unclassifiable]
, HumanFactors.External
, HumanFactors.Negligence
, HumanFactors.Recklessness
, HumanFactors.[Internal rule violations]
, HumanFactors.[Do not resuscitate order]
, HumanFactors.[Withdrawl of support]
, PreventionAndMitigationActivities.[Improve the accuracy of patient identification]
, PreventionAndMitigationActivities.[Improve the effectiveness of communication and caregivers]
, PreventionAndMitigationActivities.[Improve the effectiveness of clinical alarm systems]
, PreventionAndMitigationActivities.[Reduce the risk of healthcare-acquired infections]
, PreventionAndMitigationActivities.[Improve the safety of using high-alert medications]
, PreventionAndMitigationActivities.[Improve the safety of using infusion pumps]
, PreventionAndMitigationActivities.[Eliminate wrong-side, wrong site, wrong procedure surgery]
, SystemsFactors.ChainofCommand
, SystemsFactors.CommunicationChannels
, SystemsFactors.CulterofSafety
, SystemsFactors.Delegationofauthorityandresponsibility
, SystemsFactors.Documentation
, SystemsFactors.[Equipment or materials availability]
, SystemsFactors.[Equipment or materials design]
, SystemsFactors.[Equipment or materials malfunction]
, SystemsFactors.[Equpment or materials obsolesence]
, SystemsFactors.[Establishment and use of safety programs]
, SystemsFactors.[Formal accountability]
, SystemsFactors.[Incentive systems]
, SystemsFactors.[Instructions about procedure]
, SystemsFactors.[Monetary safety budgets]
, SystemsFactors.Objectives
, SystemsFactors.[Organizational failures beyond the control of the organization]
, SystemsFactors.[Performance standards]
, SystemsFactors.[Risk management]
, SystemsFactors.Schedules
, SystemsFactors.[Selection of organizational resources]
, SystemsFactors.[Staffing of organizational resources]
, SystemsFactors.Supervision
, SystemsFactors.[Technical failures beyond the control of the organization]
, SystemsFactors.[Time presures]
, SystemsFactors.Training
, SystemsFactors.[Training of oganizational resources]

FROM SystemsFactors 
INNER JOIN (PreventionAndMitigationActivities 
 INNER JOIN (HumanFactors 
  INNER JOIN (ActionPlanAndLoopClousre 
   INNER JOIN (StaffOther 
    INNER JOIN (StaffNurses 
     INNER JOIN (StaffPhysicians 
      INNER JOIN (StaffTherapists 
       INNER JOIN (SettingNonHospital  
        INNER JOIN (SettingHospital 
         INNER JOIN (TypeClinicalPerformance 
          INNER JOIN (DomainTarget 
           INNER JOIN (DomainPhase 
            INNER JOIN (ClinicalPerformancePostInterventional 
             INNER JOIN (ClinicalPerformanceInterventional 
              INNER JOIN (ClinicalPerformancePreInterventional 
               INNER JOIN (TypePatientManagement 
                INNER JOIN (TypeCommunication 
                 INNER JOIN (ImpactMonetary 
                  INNER JOIN (ImpactEmployment 
                   INNER JOIN (ImpactSocial 
                    INNER JOIN (ImpactLegal 
                     INNER JOIN (ImpactPsychological 
                      INNER JOIN (ImpactPhysical 
                       INNER JOIN (ImpactPatientFamilySatisfaction 
                        INNER JOIN (MasterSourceofInformation 
                         INNER JOIN MasterDemographics 
                         ON MasterSourceofInformation.EncounterNumber = MasterDemographics.EncounterNumber) 
                        ON ImpactPatientFamilySatisfaction.EncounterNumber = MasterDemographics.EncounterNumber) 
                       ON ImpactPhysical.EncounterNumber = MasterDemographics.EncounterNumber) 
                      ON ImpactPsychological.EncounterNumber = MasterDemographics.EncounterNumber) 
                     ON ImpactLegal.EncounterNumber = MasterDemographics.EncounterNumber) 
                    ON ImpactSocial.EncounterNumber = MasterDemographics.EncounterNumber) 
                   ON ImpactEmployment.EncounterNumber = MasterDemographics.EncounterNumber) 
                  ON ImpactMonetary.EncounterNumber = MasterDemographics.EncounterNumber) 
                 ON TypeCommunication.EncounterNumber = MasterDemographics.EncounterNumber) 
                ON TypePatientManagement.EncounterNumber = MasterDemographics.EncounterNumber) 
               ON ClinicalPerformancePreInterventional.EncounterNumber = MasterDemographics.EncounterNumber) 
              ON ClinicalPerformanceInterventional.EncounterNumber = MasterDemographics.EncounterNumber) 
             ON ClinicalPerformancePostInterventional.EncounterNumber = MasterDemographics.EncounterNumber) 
            ON DomainPhase.EncounterNumber = MasterDemographics.EncounterNumber) 
           ON DomainTarget.EncounterNumber = MasterDemographics.EncounterNumber) 
          ON TypeClinicalPerformance.EncounterNumber = MasterDemographics.EncounterNumber) 
         ON SettingHospital.EncounterNumber = MasterDemographics.EncounterNumber) 
        ON SettingNonHospital.EncounterNumber = MasterDemographics.EncounterNumber) 
       ON StaffTherapists.EncounterNumber = MasterDemographics.EncounterNumber) 
      ON StaffPhysicians.EncounterNumber = MasterDemographics.EncounterNumber) 
     ON StaffNurses.EncounterNumber = MasterDemographics.EncounterNumber) 
    ON StaffOther.EncounterNumber = MasterDemographics.EncounterNumber) 
   ON ActionPlanAndLoopClousre.EncounterNumber = MasterDemographics.EncounterNumber) 
  ON HumanFactors.EncounterNumber = MasterDemographics.EncounterNumber) 
 ON PreventionAndMitigationActivities.EncounterNumber = MasterDemographics.EncounterNumber) 
ON SystemsFactors.EncounterNumber = MasterDemographics.EncounterNumber;
