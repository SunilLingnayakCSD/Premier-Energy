// public without sharing class LeadApprovalInternationalController {

//     @AuraEnabled(cacheable=true)
//     public static Map<String, Object> getInternationalLeads() {
//         Map<String, Object> result = new Map<String, Object>();
//         try {
//             User currentUser = [
//                 SELECT Profile.Name, UserRole.Name 
//                 FROM User 
//                 WHERE Id = :UserInfo.getUserId() 
//                 LIMIT 1
//             ];
//             String userRoleName = currentUser.UserRole != null ? currentUser.UserRole.Name : '';
//             String profileName = currentUser.Profile != null ? currentUser.Profile.Name : '';
//             List<Lead> leads = new List<Lead>();

//             if (profileName == 'System Administrator' || userRoleName == 'Key Accounts International Head Private') {
//                 leads = [
//                     SELECT Id, Owner_Name__c, Lead_ID__c, Country, Email, Phone, Scheme_Name__c, State, Name, Company, Status, Reason__c, Reason_for_On_Hold__c, Lead_Capacity__c, Managing_Director_Approved__c, Government_Project__c, Reason_for_Rejection__c
//                     FROM Lead
//                     WHERE Status IN ('Pre Qualification Request', 'Re Request')
//                       AND Country != 'India'
//                     ORDER BY CreatedDate DESC
//                 ];
//             }
//             result.put('leads', leads);
//             result.put('userRoleName', userRoleName);
//             return result;
//         } catch (Exception e) {
//             System.debug('Error fetching international leads: ' + e.getMessage());
//             return result;
//         }
//     }

//     @AuraEnabled
//     public static void updateLeadStatus(Id leadId, String status, String reason, String otherReason) {
//         try {
//             Lead leadToUpdate = [SELECT Id, Status, Reason_for_Rejection__c, Reason__c, Reason_for_On_Hold__c FROM Lead WHERE Id = :leadId LIMIT 1];
//             leadToUpdate.Status = status;

//             if (status == 'Rejected') {
//                 leadToUpdate.Reason_for_Rejection__c = reason;
//                 leadToUpdate.Reason__c = (reason == 'Others') ? otherReason : null;
//                 leadToUpdate.Reason_for_On_Hold__c = null;
//             } else if (status == 'On Hold') {
//                 leadToUpdate.Reason_for_On_Hold__c = reason;
//                 leadToUpdate.Reason_for_Rejection__c = null;
//                 leadToUpdate.Reason__c = null;
//             } else if (status == 'Approved') {
                
//                 leadToUpdate.Reason_for_Rejection__c = null;
//                 leadToUpdate.Reason__c = null;
//                 leadToUpdate.Reason_for_On_Hold__c = null;
//             }

//             update leadToUpdate;
//         } catch (DmlException dmlEx) {
//             throw new AuraHandledException('Error updating lead status: ' + dmlEx.getMessage());
//         } catch (Exception e) {
//             throw new AuraHandledException('Unexpected error updating lead status: ' + e.getMessage());
//         }
//     }
// }






public without sharing class LeadApprovalInternationalController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getInternationalLeads() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            System.debug('Fetching current user details...');
            User currentUser = [
                SELECT Profile.Name, UserRole.Name 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
            String userRoleName = currentUser.UserRole != null ? currentUser.UserRole.Name : '';
            String profileName = currentUser.Profile != null ? currentUser.Profile.Name : '';
            System.debug('Current User Role: ' + userRoleName);
            System.debug('Current User Profile: ' + profileName);

            List<Lead> leads = new List<Lead>();

            if (profileName == 'System Administrator' || userRoleName == 'Key Accounts International Head Private') {
                System.debug('Fetching international leads for eligible user...');
                leads = [
                    SELECT Id, Owner_Name__c, Lead_ID__c, Country, Email, Phone, Scheme_Name__c, State, Name, Company, Status, Reason__c, Reason_for_On_Hold__c, Lead_Capacity__c, Managing_Director_Approved__c, Government_Project__c, Reason_for_Rejection__c
                    FROM Lead
                    WHERE Status IN ('Pre Qualification Request', 'Re Request')
                      AND Country != 'India'
                    ORDER BY CreatedDate DESC
                ];
                System.debug('Number of leads fetched: ' + leads.size());
            } else {
                System.debug('User is not authorized to fetch international leads.');
            }

            result.put('leads', leads);
            result.put('userRoleName', userRoleName);
            return result;
        } catch (Exception e) {
            System.debug('Error fetching international leads: ' + e.getMessage());
            return result;
        }
    }

    @AuraEnabled
    public static void updateLeadStatus(Id leadId, String status, String reason, String otherReason) {
        System.debug('Updating status for Lead ID: ' + leadId);
        System.debug('New Status: ' + status + ', Reason: ' + reason + ', Other Reason: ' + otherReason);

        try {
            Lead leadToUpdate = [
                SELECT Id, Status, Reason_for_Rejection__c, Reason__c, Reason_for_On_Hold__c 
                FROM Lead 
                WHERE Id = :leadId 
                LIMIT 1
            ];
            System.debug('Current Lead Status: ' + leadToUpdate.Status);

            leadToUpdate.Status = status;
            

            if (status == 'Rejected') {
                System.debug('Setting rejection reason...');
                leadToUpdate.Reason_for_Rejection__c = reason;
                leadToUpdate.Reason__c = (reason == 'Others') ? otherReason : null;
                leadToUpdate.Reason_for_On_Hold__c = null;
            } else if (status == 'On Hold') {
                System.debug('Setting on hold reason...');
                leadToUpdate.Reason_for_On_Hold__c = reason;
                leadToUpdate.Reason_for_Rejection__c = null;
                leadToUpdate.Reason__c = null;
            } else if (status == 'Approved') {
                System.debug('Clearing all reasons due to approval...');
                leadToUpdate.Reason_for_Rejection__c = null;
                leadToUpdate.Reason__c = null;
                leadToUpdate.Reason_for_On_Hold__c = null;
            }

            update leadToUpdate;
            System.debug('Lead status updated successfully.'+leadToUpdate);
        } catch (DmlException dmlEx) {
            System.debug('DML Exception: ' + dmlEx.getMessage());
            //throw new AuraHandledException('Error updating lead status: ' + dmlEx.getMessage());
        } catch (Exception e) {
            System.debug('Unexpected Exception: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error updating lead status: ' + e.getMessage());
        }
    }
}