public without sharing class LeadApprovalController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getLeads() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            User currentUser = [
                SELECT UserRole.Name
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            String userRoleName = currentUser.UserRole != null ? currentUser.UserRole.Name : '';
            List<Lead> leads = new List<Lead>();
 
            switch on userRoleName {
                when 'Managing Director' {
                    leads = [
                        SELECT Id,OwnerId,Owner_Name__c, Lead_ID__c, Country,Email, Phone, Scheme_Name__c, State, Name, Company, Status, Reason__c, Government_Project__c, Managing_Director_Approved__c
                        FROM Lead
                        WHERE Status = 'Tender Participation Request' AND Country = 'India'
                          AND Managing_Director_Approved__c = true
                          AND (Government_Project__c = 'Modules' OR Government_Project__c = 'Water Pumps' OR Government_Project__c='EPC')
                    ];
                }
                when 'National Head, Key Accounts Private' {
                    leads = [
                        SELECT Id,OwnerId, Owner_Name__c, Lead_ID__c,Email, Phone, Country, Scheme_Name__c, Name, State, Company, Status, Reason__c, Government_Project__c,Reason_for_On_Hold__c,Lead_Capacity__c, Managing_Director_Approved__c
                        FROM Lead
                        WHERE (Status = 'Tender Participation Request' AND Government_Project__c = 'Modules' AND Managing_Director_Approved__c = false AND Country = 'India')
                           OR (Status IN ('Pre Qualification Request', 'Re Request') AND Country = 'India')
                    ];
                }
                when 'CEO' {
                    leads = [
                        SELECT Id,OwnerId, Owner_Name__c, Lead_ID__c, Country, Scheme_Name__c, State, Name, Company, Email, Phone, Status, Reason__c
                        FROM Lead WHERE Country = 'India'
                    ];
                }
                when 'Chief Strategy Officer' {
                    leads = [
                        SELECT Id, OwnerId, Owner_Name__c,Managing_Director_Approved__c, Name, Country, Company,Email, Phone, Scheme_Name__c, State, Status, Reason__c, Government_Project__c
                        FROM Lead
                        WHERE Status = 'Tender Participation Request'
                          AND Government_Project__c = 'EPC' AND Country = 'India'
                         AND Managing_Director_Approved__c = false
                    ];
                }
                when 'Government Projects - Solar Pumps 1' {
                    leads = [
                        SELECT Id, OwnerId, Owner_Name__c, Lead_ID__c, Country,Phone, Email, Scheme_Name__c, State, Name, Company, Status, Reason__c, Government_Project__c
                        FROM Lead
                        WHERE Status = 'Tender Participation Request'
                          AND Government_Project__c = 'Water Pumps'
                          AND Country = 'India'
                          AND Managing_Director_Approved__c = false
                    ];
                }
            }
 
            // Return both leads and user role name to the LWC
            result.put('leads', leads);
            result.put('userRoleName', userRoleName);
            return result;
 
        } catch (Exception e) {
            System.debug('Error fetching leads: ' + e.getMessage());
            return result;
        }
    }
 
    @AuraEnabled
public static void updateLeadStatus(Id leadId, String status, String reason , String otherReason) {
    try {
        Lead leadToUpdate = [SELECT Id,Owner_Name__c, Status, Reason_for_Rejection__c, Reason__c, Reason_for_On_Hold__c FROM Lead WHERE Id = :leadId LIMIT 1];
        leadToUpdate.Status = status;
 
        if (status == 'Rejected') {
            leadToUpdate.Reason_for_Rejection__c = reason;
            leadToUpdate.Reason__c = (reason == 'Others') ? otherReason : null;
            leadToUpdate.Reason_for_On_Hold__c = null;
        } else if (status == 'On Hold') {
            leadToUpdate.Reason_for_On_Hold__c = reason;
            leadToUpdate.Reason_for_Rejection__c = null;
            leadToUpdate.Reason__c = null;
        } else {
            leadToUpdate.Reason_for_Rejection__c = null;
            leadToUpdate.Reason__c = null;
            leadToUpdate.Reason_for_On_Hold__c = null;
        }
 
        update leadToUpdate;
    } catch (DmlException dmlEx) {
        throw new AuraHandledException('Error updating lead status: ' + dmlEx.getMessage());
    } catch (Exception e) {
        throw new AuraHandledException('Unexpected error updating lead status: ' + e.getMessage());
    }
}
 
 
    @AuraEnabled
    public static void updateMDApproval(Id leadId) {
        try {
            Lead leadToUpdate = [SELECT Id,Owner_Name__c, Managing_Director_Approved__c FROM Lead WHERE Id = :leadId LIMIT 1];
            if (!leadToUpdate.Managing_Director_Approved__c) {
                leadToUpdate.Managing_Director_Approved__c = true;
                update leadToUpdate;
            } else {
                throw new AuraHandledException('Lead is already approved by MD.');
            }
        } catch (DmlException dmlEx) {
            throw new AuraHandledException('Error updating MD Approval: ' + dmlEx.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected error updating MD Approval: ' + e.getMessage());
        }
    }
}