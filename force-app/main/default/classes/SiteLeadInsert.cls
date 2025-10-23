/*public class SiteLeadInsert {
    @AuraEnabled(cacheable=false)
    public static Map<String, String> insertLead(Lead obj) {
        System.debug('Received Lead: ' + obj);
        Map<String, String> response = new Map<String, String>();
 
        try {
            if (obj.Status == null) {
                obj.Status = 'New';
            }
 
            // Step 1: Get Record Type IDs dynamically
            Map<String, Id> recordTypeMap = new Map<String, Id>();
            for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Lead']) {
                recordTypeMap.put(rt.DeveloperName, rt.Id);
            }
            
             if (obj.Total_Capacity_in_MWp__c >= 1) {
                    obj.RecordTypeId = recordTypeMap.get('Key_Account_Private');
                } else if(obj.Project_Capacity__c < 1) {
                    obj.RecordTypeId = recordTypeMap.get('Channel_Sales');
                }
 
            // Step 3: Check for duplicate leads
            List<Lead> existingLeads = [
                SELECT Id FROM Lead 
                WHERE Email = :obj.Email OR Phone = :obj.Phone
                LIMIT 10
            ];
 
            if (!existingLeads.isEmpty()) {
                response.put('status', 'duplicate');
                response.put('message', 'Duplicate lead detected based on existing Salesforce duplicate rules.');
                return response;
            }
 
            // Step 4: Insert the lead if no duplicates are found
            insert obj;
            response.put('status', 'success');
            response.put('message', 'Lead inserted successfully with ID: ' + obj.Id);
        } 
        catch (DmlException e) {
            System.debug('DML Exception: ' + e.getMessage());
 
            if (e.getMessage().contains('DUPLICATES_DETECTED')) {
                response.put('status', 'duplicate');
                response.put('message', 'The phone or email you entered already exists in the system');
            } else {
                response.put('status', 'error');
                response.put('message', e.getMessage());
            }
        } 
        catch (Exception e) {
            System.debug('General Exception: ' + e.getMessage());
            response.put('status', 'error');
            response.put('message', e.getMessage());
        }
 
        return response;
    }
} */

public class SiteLeadInsert {
    @AuraEnabled(cacheable=false)
    public static Map<String, String> insertLead(Lead obj) {
        System.debug('Received Lead: ' + obj);
        Map<String, String> response = new Map<String, String>();

        try {
            // Default status
            if (obj.Status == null) {
                obj.Status = 'New';
            }

            // Get Record Type IDs dynamically
            Map<String, Id> recordTypeMap = new Map<String, Id>();
            for (RecordType rt : [
                SELECT Id, DeveloperName 
                FROM RecordType 
                WHERE SObjectType = 'Lead'
            ]) {
                recordTypeMap.put(rt.DeveloperName, rt.Id);
            }
            
            System.debug('obj.Total_Capacity_in_MWp__c '+obj.Total_Capacity_in_MWp__c );
            System.debug('obj.Project_Capacity__c '+obj.Project_Capacity__c );

            // Assign RecordType based on Total_Capacity_in_MWp__c or Project_Capacity__c
            if (obj.Project_Capacity__c != null && obj.Project_Capacity__c >= 1) {
                obj.RecordTypeId = recordTypeMap.get('Key_Account_Private');
            } else if (obj.Total_Capacity_in_MWp__c != null && obj.Total_Capacity_in_MWp__c < 1) {
                obj.RecordTypeId = recordTypeMap.get('Channel_Sales');
            }

            // Insert Lead
            System.debug('obj'+obj);
            insert obj;

            response.put('status', 'success');
            response.put('message', 'Lead inserted successfully with ID: ' + obj.Id);
        } 
        catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            response.put('status', 'error');
            response.put('message', e.getMessage());
        }

        return response;
    }
}