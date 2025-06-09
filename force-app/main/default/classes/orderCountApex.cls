/**
* @File Name : orderCountApex.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : April 15, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 15, 2025 |   | Initial Version
**/

/*public class orderCountApex {
    @AuraEnabled(cacheable=true)
    public static List<Order> orderMethod(Date startdate, Date enddate) {
        Id currentUserId = UserInfo.getUserId();
        Date adjustedEndDate = enddate.addDays(1);
        return [
            SELECT Id
            FROM Order
            WHERE OwnerId = :currentUserId
            AND CreatedDate >= :startdate
            AND CreatedDate <:adjustedEndDate
        ];
    }
}*/
public with sharing class orderCountApex {
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> orderMethod(Date startdate, Date enddate) {
        Id currentUserId = UserInfo.getUserId();
        System.debug('currentUserId'+currentUserId);
        Date adjustedEndDate = enddate.addDays(1);
        
        // Query the Contact record associated with the logged-in user
        Contact userContact = [SELECT AccountId FROM Contact WHERE Id = :[SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1].ContactId LIMIT 1];
        
        // Get the AccountId from the Contact record
        Id currentUserAccountId = userContact.AccountId;
        System.debug('currentUserAccountId: ' + currentUserAccountId);

        // Get the RecordTypeId for the specific Lead RecordType you need to consider
        // Replace 'Your RecordType Name' with the actual name of the record type you want
        Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND Name = 'Purchase Order' LIMIT 1].Id;
        System.debug('recordTypeId: ' + recordTypeId);


        Map<String, Integer> counts = new Map<String, Integer>{
            'total' => 0,
            'closed' => 0,
            'cancelled' => 0,
            'intransit' => 0,
            'inprogress' => 0
        };

        List<Order> orders = [
            SELECT Id, Approval_Status__c,
                (SELECT Id, POD_Status__c FROM Invoices__r)
            FROM Order
            WHERE AccountId = :currentUserAccountId
              AND RecordTypeId = :recordTypeId
              AND Type__c = 'Channel Sales'
              AND CreatedDate >= :startdate
              AND CreatedDate < :adjustedEndDate
        ];

        counts.put('total', orders.size());
        System.debug('orders'+orders);
        System.debug('Before loop');

        for (Order ord : orders) {
            System.debug('ord'+ord.Invoices__r);
            Boolean isClosed = false;
            Boolean isInTransit = false;

            // Check related Invoices
            if (ord.Invoices__r != null && !ord.Invoices__r.isEmpty()) {
            for (Invoice__c inv : ord.Invoices__r) {
                System.debug('inv'+inv);
                String pod = inv.POD_Status__c;
                System.debug('pod'+pod);

                if (pod == 'Uploaded') {
                    isClosed = true;
                    break;
                } else if (pod == null || pod == 'None' || pod == 'Not Uploaded') {
                    isInTransit = true;
                }
            }
            }
            System.debug('After  loop');

            if (ord.Approval_Status__c == 'Rejected') {
                counts.put('cancelled', counts.get('cancelled') + 1);
            } else if (isClosed) {
                counts.put('closed', counts.get('closed') + 1);
            } else if (isInTransit) {
                counts.put('intransit', counts.get('intransit') + 1);
            } else {
                counts.put('inprogress', counts.get('inprogress') + 1);
            }
        }
		System.debug('counts'+counts);
        return counts;
    }
}