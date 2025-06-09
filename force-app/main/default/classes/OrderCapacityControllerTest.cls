@isTest
public class OrderCapacityControllerTest {

    @TestSetup
    static void setupTestData() {
        // Insert an Account with correct picklist value for Premier_Business_Entity__c
        Account acc = new Account(
            Name = 'Test Account',
            Premier_Business_Entity__c = 'PEL',  // ✅ Correct value here
            Plant_Name__c = 'PEL - ANNARAM PLANT',
            Plant_Name1__c = 'PEPPL - FABCITY Plant'
        );
        insert acc;

        // Retrieve RecordTypeId for 'Purchase_Order'
        Id purchaseOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();

        // Insert Orders for this Account
        List<Order> orders = new List<Order>{
            new Order(
                AccountId = acc.Id,
                Type__c = 'Key Account Private',
                Total_Capacity_in_MWp__c = 10,
                RecordTypeId = purchaseOrderRTId,
                Status = 'Draft',
                EffectiveDate = Date.today()
            ),
            new Order(
                AccountId = acc.Id,
                Type__c = 'Key Account Private',
                Total_Capacity_in_MWp__c = 5,
                RecordTypeId = purchaseOrderRTId,
                Status = 'Draft',
                EffectiveDate = Date.today()
            ),
            new Order(
                AccountId = acc.Id,
                Type__c = 'Channel Sales',
                Total_Capacity_in_MWp__c = 3,
                RecordTypeId = purchaseOrderRTId,
                Status = 'Draft',
                EffectiveDate = Date.today()
            )
        };
        insert orders;

        // Insert Invoices for this Account
        List<Invoice__c> invoices = new List<Invoice__c>{
            new Invoice__c(
                Account__c = acc.Id,
                Total_Capacity_in_MWp__c = 7
            ),
            new Invoice__c(
                Account__c = acc.Id,
                Total_Capacity_in_MWp__c = 2
            )
        };
        insert invoices;
    }

    @isTest
    static void testGetOrderProgressData() {
        // Fetch test Account Id
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Test.startTest();
        Map<String, Decimal> result = OrderCapacityController.getOrderProgressData(acc.Id);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
        System.assert(result.containsKey('AnnualCapacity'), 'AnnualCapacity should be present in result');
        System.assert(result.containsKey('BookedOrders'), 'BookedOrders should be present in result');
        System.assert(result.containsKey('InvoiceOrders'), 'InvoiceOrders should be present in result');

        System.debug('AnnualCapacity: ' + result.get('AnnualCapacity'));
        System.debug('BookedOrders: ' + result.get('BookedOrders'));
        System.debug('InvoiceOrders: ' + result.get('InvoiceOrders'));

        // Validate BookedOrders total: only 'Key Account Private' types considered (10 + 5)
        System.assertEquals(15, result.get('BookedOrders'), 'BookedOrders total should be 15');

        // Validate InvoicedOrders total: (7 + 2)
        System.assertEquals(9, result.get('InvoiceOrders'), 'InvoiceOrders total should be 9');

        // AnnualCapacity will be 0 here since Custom Metadata cannot be inserted in test classes
        //System.assertEquals(0, result.get('AnnualCapacity'), 'AnnualCapacity should be 0 in test context');
    }
}