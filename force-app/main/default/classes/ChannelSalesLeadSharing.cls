public class ChannelSalesLeadSharing {

    // Cache the Channel Sales record type ID
    private static Id channelSalesRecordTypeId {
        get {
            if (channelSalesRecordTypeId == null) {
                channelSalesRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                                             .get('Channel_Sales').getRecordTypeId();
            }
            return channelSalesRecordTypeId;
        }
        set;
    }

    public static void handleLeadOwnershipAndSharing(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        List<Lead> leadsToUpdate = new List<Lead>();
        List<LeadShare> sharesToInsert = new List<LeadShare>();

        // Get all valid ASM users based on region and manager
        Set<Id> validAsmUsers = new Set<Id>();
        for (Lead newLead : newLeads) {
            if (newLead.ASM__c != null) {
                // Check if the ASM user is valid according to the lookup filter criteria
                List<User> validUsers = [SELECT Id FROM User WHERE Id = :newLead.ASM__c 
                                          AND Region__c = :newLead.Region_Picklist__c 
                                          AND ManagerId = :newLead.OwnerId];
                if (!validUsers.isEmpty()) {
                    validAsmUsers.add(newLead.ASM__c);
                }
            }
        }

        // Loop through the leads and update only if ASM__c is valid
        for (Lead newLead : newLeads) {
            if (newLead.RecordTypeId != channelSalesRecordTypeId) {
                continue;
            }

            Lead oldLead = oldMap != null ? oldMap.get(newLead.Id) : null;

            // Only proceed if ASM is valid based on the criteria
            if (validAsmUsers.contains(newLead.ASM__c)) {
                // ASM Assignment Logic: Update Owner to ASM if ASM has changed
                Boolean isAsmChanged = oldLead != null && newLead.ASM__c != null &&
                                       newLead.ASM__c != oldLead.ASM__c;

                if (isAsmChanged) {
                    // Update the Lead owner to ASM
                    leadsToUpdate.add(new Lead(
                        Id = newLead.Id,
                        OwnerId = newLead.ASM__c
                    ));

                    // Share with ASM
                    sharesToInsert.add(createLeadShare(newLead.Id, newLead.ASM__c));
                }
            } else {
                // Optionally, handle the case where ASM is invalid, maybe log an error or skip the update.
                System.debug('Invalid ASM user for Lead ID: ' + newLead.Id);
            }

            // Distributor sharing logic...
            Boolean isDistributorChanged = oldLead != null && newLead.Distributor__c != null &&
                                           newLead.Distributor__c != oldLead.Distributor__c;

            if (isDistributorChanged) {
                sharesToInsert.add(createLeadShare(newLead.Id, newLead.Distributor__c));
            }

            if (newLead.ASM__c != null && newLead.Distributor__c != null && newLead.ASM__c != oldLead.ASM__c) {
                sharesToInsert.add(createLeadShare(newLead.Id, newLead.Distributor__c));
            }

            if (newLead.ASM__c == null && newLead.Distributor__c != null) {
                sharesToInsert.add(createLeadShare(newLead.Id, newLead.Distributor__c));
            }
        }

        // Perform the updates and insert the share records
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }

        if (!sharesToInsert.isEmpty()) {
            insert sharesToInsert;
        }
    }

    private static LeadShare createLeadShare(Id leadId, Id userId) {
        return new LeadShare(
            LeadId = leadId,
            UserOrGroupId = userId,
            LeadAccessLevel = 'Edit',
            RowCause = Schema.LeadShare.RowCause.Manual
        );
    }
}