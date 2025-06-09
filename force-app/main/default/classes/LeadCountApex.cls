/*public with sharing class LeadCountApex {
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> LeadMethod(Date startDate, Date endDate) {
         Date adjustedEndDate = enddate.addDays(1);
        Map<String, Integer> statusCounts = new Map<String, Integer>{
            'total' => 0,
            'Purchased Module' => 0,
            'New' => 0,
            'Rejected' => 0
        };

        List<AggregateResult> results = [
			SELECT Status__c, COUNT(Id) total
			FROM Lead
			 WHERE CreatedDate >= :startDate AND CreatedDate < :adjustedEndDate AND Status__c != null AND Status__c != 'Approved' 
			GROUP BY Status__c
        ];

        for (AggregateResult ar : results) {
            String status = (String) ar.get('Status__c');
            Integer count = (Integer) ar.get('total');

            if (statusCounts.containsKey(status)) {
                statusCounts.put(status, count);
            }
            statusCounts.put('total', statusCounts.get('total') + count);
        }

        return statusCounts;
    }
}*/

public with sharing class LeadCountApex {
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> LeadMethod(Date startDate, Date endDate) {
        Date adjustedEndDate = endDate.addDays(1);
        Id currentUserId = UserInfo.getUserId();

        // Final map to return
        Map<String, Integer> leadCounts = new Map<String, Integer>{
            'total' => 0,
            'open' => 0,
            'rejected' => 0,
            'converted' => 0,
            'closed' => 0
        };

        // Total count of leads for user
        leadCounts.put('total', [
            SELECT COUNT()
            FROM Lead
            WHERE CreatedDate >= :startDate
                AND CreatedDate < :adjustedEndDate
                AND Distributor__c = :currentUserId
        ]);

        // Count by Status__c (for Open and Rejected)
        List<AggregateResult> statusResults = [
            SELECT Status, COUNT(Id) total
            FROM Lead
            WHERE CreatedDate >= :startDate
                AND CreatedDate < :adjustedEndDate
                AND Distributor__c = :currentUserId
            GROUP BY Status
        ];

        for (AggregateResult ar : statusResults) {
            String status = (String) ar.get('Status');
            Integer count = (Integer) ar.get('total');

            if (status == 'New') {
                leadCounts.put('open', count);
            } else if (status == 'Rejected') {
                leadCounts.put('rejected', count);
            }
        }

        // Count of converted leads
        Integer converted = [
            SELECT COUNT()
            FROM Lead
            WHERE CreatedDate >= :startDate
                AND CreatedDate < :adjustedEndDate
                AND Distributor__c = :currentUserId
                AND Purchased_Premier_Module__c = 'Yes'
        ];
        leadCounts.put('converted', converted);

        // Closed = Converted - Rejected
        Integer closed = converted - leadCounts.get('rejected');
        leadCounts.put('closed', closed < 0 ? 0 : closed);

        return leadCounts;
    } 

/*public with sharing class LeadCountApex {
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> LeadMethod(Date startDate, Date endDate) {
        Date adjustedEndDate = endDate.addDays(1);
        Id currentUserId = UserInfo.getUserId();
        
        // Query the Contact record associated with the logged-in user
        Contact userContact = [SELECT AccountId FROM Contact WHERE Id = :[SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1].ContactId LIMIT 1];
        
        // Get the AccountId from the Contact record
        Id currentUserAccountId = userContact.AccountId;
        System.debug('currentUserAccountId: ' + currentUserAccountId);

        // Get the RecordTypeId for the specific Lead RecordType you need to consider
        // Replace 'Your RecordType Name' with the actual name of the record type you want
        Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND Name = 'Channel Sales' LIMIT 1].Id;
        System.debug('recordTypeId: ' + recordTypeId);

        // Final map to return
        Map<String, Integer> leadCounts = new Map<String, Integer>{
            'total' => 0,
            'open' => 0,
            'rejected' => 0,
            'converted' => 0,
            'closed' => 0
        };

        // Total count of leads for user where Assigned Distributor matches the user's Account and Record Type matches
        leadCounts.put('total', [
            SELECT COUNT()
            FROM Lead
            WHERE CreatedDate >= :startDate
                AND CreatedDate < :adjustedEndDate
                AND OwnerId = :currentUserId
                AND Assigned_Distributor__c = :currentUserAccountId // Filter by assigned distributor
                AND RecordTypeId = :recordTypeId // Filter by the specific record type
        ]);

        // Count by Status__c (for Open and Rejected) where Assigned Distributor matches the user's Account and Record Type matches
        List<AggregateResult> statusResults = [
            SELECT Status, COUNT(Id) total
            FROM Lead
            WHERE CreatedDate >= :startDate
                AND CreatedDate < :adjustedEndDate
                AND OwnerId = :currentUserId
                AND Assigned_Distributor__c = :currentUserAccountId // Filter by assigned distributor
                AND RecordTypeId = :recordTypeId // Filter by the specific record type
            GROUP BY Status
        ];

        for (AggregateResult ar : statusResults) {
            String status = (String) ar.get('Status');
            Integer count = (Integer) ar.get('total');

            if (status == 'New') {
                leadCounts.put('open', count);
            } else if (status == 'Rejected') {
                leadCounts.put('rejected', count);
            }
        }

        // Count of converted leads where Assigned Distributor matches the user's Account and Record Type matches
        Integer converted = [
            SELECT COUNT()
            FROM Lead
            WHERE CreatedDate >= :startDate
                AND CreatedDate < :adjustedEndDate
                AND OwnerId = :currentUserId
                AND Assigned_Distributor__c = :currentUserAccountId // Filter by assigned distributor
                AND RecordTypeId = :recordTypeId // Filter by the specific record type
                AND Purchased_Premier_Module__c = 'Yes'
        ];
        leadCounts.put('converted', converted);

        // Closed = Converted - Rejected
        Integer closed = converted - leadCounts.get('rejected');
        leadCounts.put('closed', closed < 0 ? 0 : closed);
        
        System.debug('leadCounts: ' + leadCounts);

        return leadCounts;
    }*/
}