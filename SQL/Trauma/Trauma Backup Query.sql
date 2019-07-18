SELECT *
FROM 
(
 (
  (
   (
    (
     (
      (
       (
        (
         (
          (
           (
            (
             (
              (
               (
                (
                 (
                  (
                   (
                    (
                     (MasterDemographics AS MasterDemographics_1 
                    LEFT JOIN MasterSourceofInformation 
                    ON MasterDemographics_1.EncounterNumber = MasterSourceofInformation.EncounterNumber) 
                   LEFT JOIN ActionPlanAndLoopClousre 
                   ON MasterSourceofInformation.EncounterNumber = ActionPlanAndLoopClousre.EncounterNumber) 
                  LEFT JOIN TypeClinicalPerformance 
                  ON ActionPlanAndLoopClousre.EncounterNumber = TypeClinicalPerformance.EncounterNumber) 
                 LEFT JOIN ClinicalPerformanceInterventional 
                 ON TypeClinicalPerformance.EncounterNumber = ClinicalPerformanceInterventional.EncounterNumber) 
                LEFT JOIN ClinicalPerformancePostInterventional 
                ON ClinicalPerformanceInterventional.EncounterNumber = ClinicalPerformancePostInterventional.EncounterNumber) 
               LEFT JOIN DomainPhase 
               ON ClinicalPerformancePostInterventional.EncounterNumber = DomainPhase.EncounterNumber) 
              LEFT JOIN DomainTarget 
              ON DomainPhase.EncounterNumber = DomainTarget.EncounterNumber) 
             LEFT JOIN ImpactEmployment 
             ON DomainTarget.EncounterNumber = ImpactEmployment.EncounterNumber) 
            LEFT JOIN ImpactLegal 
            ON ImpactEmployment.EncounterNumber = ImpactLegal.EncounterNumber) 
           LEFT JOIN ImpactMonetary 
           ON ImpactLegal.EncounterNumber = ImpactMonetary.EncounterNumber) 
          LEFT JOIN ImpactPatientFamilySatisfaction 
          ON ImpactMonetary.EncounterNumber = ImpactPatientFamilySatisfaction.EncounterNumber) 
         LEFT JOIN (
				(ImpactPhysical 
				LEFT JOIN ImpactPsychological 
				ON ImpactPhysical.EncounterNumber = ImpactPsychological.EncounterNumber) 
				LEFT JOIN ImpactSocial 
				ON ImpactPsychological.EncounterNumber = ImpactSocial.EncounterNumber) 
		 ON ImpactPatientFamilySatisfaction.EncounterNumber = ImpactPhysical.EncounterNumber) 
          LEFT JOIN StaffNurses 
          ON ImpactSocial.EncounterNumber = StaffNurses.EncounterNumber) 
         LEFT JOIN StaffOther 
         ON StaffNurses.EncounterNumber = StaffOther.EncounterNumber) 
        LEFT JOIN StaffPhysicians 
        ON StaffOther.EncounterNumber = StaffPhysicians.EncounterNumber) 
       LEFT JOIN StaffTherapists 
       ON StaffPhysicians.EncounterNumber = StaffTherapists.EncounterNumber) 
      LEFT JOIN TypeCommunication 
      ON StaffTherapists.EncounterNumber = TypeCommunication.EncounterNumber) 
     LEFT JOIN TypePatientManagement 
     ON TypeCommunication.EncounterNumber = TypePatientManagement.EncounterNumber) 
    LEFT JOIN SettingHospital 
    ON TypePatientManagement.EncounterNumber = SettingHospital.EncounterNumber) 
   LEFT JOIN SettingNonHospital 
   ON SettingHospital.EncounterNumber = SettingNonHospital.EncounterNumber) 
  LEFT JOIN HumanFactors 
  ON SettingNonHospital.EncounterNumber = HumanFactors.EncounterNumber) 
 LEFT JOIN PreventionAndMitigationActivities 
 ON HumanFactors.EncounterNumber = PreventionAndMitigationActivities.EncounterNumber) 
LEFT JOIN SystemsFactors 
ON PreventionAndMitigationActivities.EncounterNumber = SystemsFactors.EncounterNumber;
