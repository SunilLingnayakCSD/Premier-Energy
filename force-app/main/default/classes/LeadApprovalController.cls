public without sharing class LeadApprovalController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getLeads() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            String userProfileName = currentUser.Profile.Name;
            List<Lead> leads = new List<Lead>();

            switch on userProfileName {
                when 'Managing Director' {
                    leads = [SELECT Id,Lead_ID__c,Country,Scheme_Name__c ,State, Name, Company, Status, Reason__c, Government_Project__c, Managing_Director_Approved__c 
                             FROM Lead 
                             WHERE Status = 'Tender Participation Request' 
                             AND Government_Project__c = 'Modules'
                             AND Managing_Director_Approved__c = false];
                }
                when 'Government Projects Head -Modules' {
                    leads = [SELECT Id,Lead_ID__c,Country ,Scheme_Name__c , Name,State, Company, Status, Reason__c, Government_Project__c, Managing_Director_Approved__c 
                             FROM Lead 
                             WHERE Status = 'Tender Participation Request' 
                             AND Government_Project__c = 'Modules'
                             AND Managing_Director_Approved__c = true];
                }
                when 'System Administrator' {
                    leads = [SELECT Id,Lead_ID__c,Country ,Scheme_Name__c ,State, Name, Company, Email, Phone, Status, Reason__c FROM Lead ];
                }
                when 'Chief Strategy Officer' {
                    leads = [SELECT Id, Name,Country, Company,Scheme_Name__c ,State, Status, Reason__c, Government_Project__c 
                             FROM Lead 
                             WHERE Status = 'Tender Participation Request' 
                             AND Government_Project__c = 'EPC'];
                }
                when 'Government Projects - Solar Pumps 1' {
                    leads = [SELECT Id,Lead_ID__c,Country ,Scheme_Name__c ,State, Name, Company, Status, Reason__c, Government_Project__c 
                             FROM Lead 
                             WHERE Status = 'Tender Participation Request' 
                             AND Government_Project__c = 'Water Pumps'];
                }
                when 'Key Accounts National Head' {
                    leads = [SELECT Id,Lead_ID__c,Country , Name,Scheme_Name__c ,State, Company, Email, Phone, Status, Reason__c FROM Lead WHERE Status = 'Pre_Qualification_Request'];
                }
            }

            // Return both leads and user profile name to the LWC
            result.put('leads', leads);
            result.put('userProfileName', userProfileName);
            return result;
        } catch (Exception e) {
            System.debug('Error fetching leads: ' + e.getMessage());
            return result;
        }
    }
  @AuraEnabled
public static void updateLeadStatus(Id leadId, String status, String reason , String otherReason) {
    try {
        // Fetch lead record
        Lead leadToUpdate = [SELECT Id, Status, Reason_for_Rejection__c, Reason__c FROM Lead WHERE Id = :leadId LIMIT 1];

        // Update Status
        leadToUpdate.Status = status;
        System.debug('Reason ----------->: '+reason);

        // Handle rejection reason updates
        if (status == 'Rejected') {
    
            leadToUpdate.Reason_for_Rejection__c = reason;
        //    leadToUpdate.Reason__c = (reason == 'Others') ? reason : null;
            leadToUpdate.Reason__c = (reason == 'Others') ? otherReason : null;

        } else {
            // Clear rejection reason fields if status is not "Rejected"
            leadToUpdate.Reason_for_Rejection__c = null;
            leadToUpdate.Reason__c = null;
        }

        // Update the lead record
        update leadToUpdate;

    } catch (DmlException dmlEx) {
        System.debug('DML Error updating lead status: ' + dmlEx.getMessage());
        throw new AuraHandledException('Error updating lead status: ' + dmlEx.getMessage());
    } catch (Exception e) {
        System.debug('Unexpected error updating lead status: ' + e.getMessage());
        throw new AuraHandledException('Unexpected error updating lead status: ' + e.getMessage());
    }
}


    @AuraEnabled
    public static void updateMDApproval(Id leadId) {
        try {
            Lead leadToUpdate = [SELECT Id, Managing_Director_Approved__c FROM Lead WHERE Id = :leadId LIMIT 1];

            // Only update if not already approved
            if (!leadToUpdate.Managing_Director_Approved__c) {
                leadToUpdate.Managing_Director_Approved__c = true;
                update leadToUpdate;
            } else {
                throw new AuraHandledException('Lead is already approved by MD.');
            }

        } catch (DmlException dmlEx) {
            System.debug('DML Error updating MD Approval: ' + dmlEx.getMessage());
            throw new AuraHandledException('Error updating MD Approval: ' + dmlEx.getMessage());
        } catch (Exception e) {
            System.debug('Unexpected Error updating MD Approval: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error updating MD Approval: ' + e.getMessage());
        }
    }
}