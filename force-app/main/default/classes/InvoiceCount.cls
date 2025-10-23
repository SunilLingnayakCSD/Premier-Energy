public with sharing class InvoiceCount {

@AuraEnabled(cacheable=true)
public static Map<String, Integer> getInvoiceCounts(Date startDate, Date endDate) {
    Map<String, Integer> result = new Map<String, Integer>();
    try {
        Id currentUserId = UserInfo.getUserId();
        
        // Get User's Contact and Account
        User currentUser = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
        if (currentUser.ContactId == null) {
            throw new AuraHandledException('User not linked to a Contact.');
        }
        Contact userContact = [SELECT AccountId FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];
        if (userContact.AccountId == null) {
            throw new AuraHandledException('Contact not linked to an Account.');
        }
        Id currentUserAccountId = userContact.AccountId;
        
        // Get RecordTypeId by DeveloperName
        String recordTypeDevName = 'Distributor'; // Update this!
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(recordTypeDevName).getRecordTypeId();
        
        // Build Query
        String query = 
            'SELECT POD_Status__c, POD_Date__c, Status__c, FTR_Upload_Date__c ' +
            'FROM Invoice__c ' +
            'WHERE Account__c = :currentUserAccountId ';
            //+
           // 'AND RecordTypeId = :recordTypeId';
        
        // Add Date Filters
        if (startDate != null) {
            query += ' AND DAY_ONLY(CreatedDate) >= :startDate';
        }
        if (endDate != null) {
            query += ' AND DAY_ONLY(CreatedDate) <= :endDate';
        }
        
        System.debug('Final Query: ' + query);
        List<Invoice__c> invoices = Database.query(query);
        
        // Count Logic (unchanged)
        Integer totalPOD = 0, totalFTR = 0;
        for (Invoice__c inv : invoices) {
            if (inv.POD_Status__c != 'uploaded' && inv.POD_Date__c != null) totalPOD++;
            if (inv.Status__c != 'uploaded' && inv.FTR_Upload_Date__c != null) totalFTR++;
        }
        
        result.put('totalInvoices', invoices.size());
        result.put('totalPODInvoices', totalPOD);
        result.put('totalFTRInvoices', totalFTR);
        
    } catch (Exception e) {
        System.debug('Error: ' + e.getMessage() + ' at ' + e.getLineNumber());
        throw new AuraHandledException('Error: ' + e.getMessage());
    }
    return result;
}





















































































 /* @AuraEnabled(cacheable=true)
public static Map<String, Integer> getInvoiceCounts(Date startDate, Date endDate) {
    Map<String, Integer> result = new Map<String, Integer>();

    try {
        // 1. Get current user's Accounts
        Id userId = UserInfo.getUserId();
        List<Id> accountIds = new List<Id>();

        for (Account acc : [
            SELECT Id FROM Account WHERE OwnerId = :userId
        ]) {
            accountIds.add(acc.Id);
        }

        if (accountIds.isEmpty()) {
            result.put('totalInvoices', 0);
            result.put('totalPODInvoices', 0);
            result.put('totalFTRInvoices', 0);
            return result;
        }

        // 2. Build Invoice Query dynamically
        String query = 
            'SELECT POD_Status__c, POD_Date__c, Status__c, FTR_Upload_Date__c ' +
            'FROM Invoice__c WHERE Account__c IN :accountIds';

        if (startDate != null) {
            query += ' AND CreatedDate >= :startDate';
        }
        if (endDate != null) {
            query += ' AND CreatedDate <= :endDate';
        }

        // 3. Execute query
        List<Invoice__c> invoices = Database.query(query);

        // 4. Count totals
        Integer totalPOD = 0;
        Integer totalFTR = 0;

        for (Invoice__c inv : invoices) {
            if (inv.POD_Status__c == 'uploaded' && inv.POD_Date__c != null) {
                totalPOD++;
            }
            if (inv.Status__c == 'uploaded' && inv.FTR_Upload_Date__c != null) {
                totalFTR++;
            }
        }

        // 5. Return counts
        result.put('totalInvoices', invoices.size());
        result.put('totalPODInvoices', totalPOD);
        result.put('totalFTRInvoices', totalFTR);

    } catch (Exception e) {
        throw new AuraHandledException('Error: ' + e.getMessage());
    }
	System.debug('result'+result);
    return result;
}*/






}