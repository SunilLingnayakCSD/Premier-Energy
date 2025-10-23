trigger OpportunityStageValidation on Opportunity (before update,before insert) {
    OpportunityClosedWonValidation.validate(Trigger.new, Trigger.oldMap);
    //OpportunityClosedWonValidationKAG.validate(Trigger.new, Trigger.oldMap);
}