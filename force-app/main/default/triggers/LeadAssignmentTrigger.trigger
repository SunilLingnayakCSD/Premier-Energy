trigger LeadAssignmentTrigger on Lead (after insert, after update) {
    if (Trigger.isAfter) {
        List<Lead> leadsToAssign = new List<Lead>();
        Map<Id, Lead> oldLeadsMap = Trigger.oldMap != null ? Trigger.oldMap : new Map<Id, Lead>();
 
        for (Lead newLead : Trigger.new) {
            if (Trigger.isInsert) {
                if (newLead.RecordTypeId != null) {
                    leadsToAssign.add(newLead);
                }
            } else if (Trigger.isUpdate) {
                Lead oldLead = oldLeadsMap.get(newLead.Id);
                Boolean regionChanged = newLead.Region_Picklist__c != oldLead.Region_Picklist__c;
                Boolean countryChanged = newLead.Country != oldLead.Country;
                Boolean recordTypeChanged = newLead.RecordTypeId != oldLead.RecordTypeId;
 
                Boolean isSpecialCase = newLead.RecordTypeId != null && (countryChanged || recordTypeChanged);
 
                if ((regionChanged || isSpecialCase) && newLead.RecordTypeId != null) {
                    leadsToAssign.add(newLead);
                }
            }
        }
 
        if (!leadsToAssign.isEmpty()) {
            Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>(
                [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = 'Lead']
            );
            LeadAssignmentBasedOnRegionAndRecordType.assignLeads(leadsToAssign, recordTypeMap);
        }
    }
}