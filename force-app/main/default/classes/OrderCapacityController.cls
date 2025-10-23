public with sharing class OrderCapacityController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getOrderProgressData(Id accountId) {
        Map<String, Decimal> result = new Map<String, Decimal>{
            'AnnualCapacity' => 0,
            'BookedOrders' => 0,
            'InvoiceOrders' => 0
        };

        // Get Account Info
        Account acc = [
            SELECT Id, Premier_Business_Entity__c, Plant_Name__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        // Step 1: Get Annual Capacity from Custom Metadata
        List<String> plantNames = new List<String>{
            acc.Plant_Name__c
        };

        Set<String> plantNameSet = new Set<String>();
        for (String name : plantNames) {
            if (String.isNotBlank(name)) {
                plantNameSet.add(name);
            }
        }

        for (Plant_with_Pincode__mdt meta : [
            SELECT Company__c, Plant_Name__c, Capacity__c
            FROM Plant_with_Pincode__mdt
            WHERE Company__c = :acc.Premier_Business_Entity__c
        ]) {
            if (plantNameSet.contains(meta.Plant_Name__c)) {
                Decimal currentCapacity = result.get('AnnualCapacity');
                Decimal newCapacity = 0;

                if (meta.Capacity__c != null && !String.isBlank(meta.Capacity__c)) {
                    try {
                        // Convert GWp to MWp
                        newCapacity = Decimal.valueOf(meta.Capacity__c) * 1000;
                    } catch (Exception e) {
                        newCapacity = 0;
                    }
                }

                result.put('AnnualCapacity', currentCapacity + newCapacity);
            }
        }

        Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
        System.debug('Retrieved RecordTypeId: ' + purchaseOrderRecordTypeId);


        // Step 3: Booked Orders
        List<Order> bookedOrders = [
            SELECT Id, Total_Capacity_in_MWp__c, Type__c
            FROM Order
            WHERE AccountId = :accountId
              AND RecordTypeId = :purchaseOrderRecordTypeId

        ];

        for (Order ord : bookedOrders) {
            if (ord.Type__c != null && ord.Type__c.toLowerCase() == 'key account private') {
                Decimal currentBooked = result.get('BookedOrders');
                Decimal orderCapacity = ord.Total_Capacity_in_MWp__c != null ? ord.Total_Capacity_in_MWp__c : 0;
                result.put('BookedOrders', currentBooked + orderCapacity);
            }
        }

        // Step 4: Invoiced Orders
        List<Invoice__c> invoices = [
            SELECT Id, Total_Capacity_in_MWp__c
            FROM Invoice__c
            WHERE Account__c = :accountId
        ];

        for (Invoice__c inv : invoices) {
            Decimal currentInvoiced = result.get('InvoiceOrders');
            Decimal invoiceCapacity = inv.Total_Capacity_in_MWp__c != null ? inv.Total_Capacity_in_MWp__c : 0;
            result.put('InvoiceOrders', currentInvoiced + invoiceCapacity);
        }

        return result;
    }
}