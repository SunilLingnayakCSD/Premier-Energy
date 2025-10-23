@isTest
private class OrderCapacityControllerTest {

    @isTest
    static void testGetOrderProgressData() {
        // Dynamically get picklist values and their dependencies
        Map<String, List<String>> dependentPicklistValues = getDependentPicklistValues();
        
        // Ensure we have valid values to test with
        if (dependentPicklistValues.isEmpty()) {
            System.assert(false, 'No dependent picklist values found for testing');
            return;
        }
        
        // Get first available controlling value and its dependent values
        String parentPickVal = new List<String>(dependentPicklistValues.keySet())[0];
        String childPickVal = dependentPicklistValues.get(parentPickVal)[0];
        
        // Create test Account with valid picklist values
        Account acc = new Account(
            Name = 'Test Account',
            Premier_Business_Entity__c = parentPickVal,
            Plant_Name__c = childPickVal
        );
        insert acc;
        
        // Get RecordTypeId for Purchase Order
        Id poRecordTypeId = Schema.SObjectType.Order
            .getRecordTypeInfosByDeveloperName()
            .get('Purchase_Order')
            .getRecordTypeId();

        // Create test Order
        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            RecordTypeId = poRecordTypeId,
            Type__c = 'Key Account Private',
            Total_Capacity_in_MWp__c = 10
        );
        insert ord;

        // Create test Invoice
        Invoice__c invoice = new Invoice__c(
            Name = 'Test Invoice',
            Account__c = acc.Id,
            Total_Capacity_in_MWp__c = 5
        );
        insert invoice;

        // Insert test metadata if needed (optional)
        // This would require SeeAllData=true or metadata creation in test context
        // For real orgs, consider using actual metadata
        
        // Test the controller
        Test.startTest();
        Map<String, Decimal> result = OrderCapacityController.getOrderProgressData(acc.Id);
        Test.stopTest();

        // Validate results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('AnnualCapacity'), 'Should contain AnnualCapacity');
        System.assert(result.containsKey('BookedOrders'), 'Should contain BookedOrders');
        System.assert(result.containsKey('InvoiceOrders'), 'Should contain InvoiceOrders');

       // System.assertEquals(10, result.get('BookedOrders'), 'BookedOrders should match inserted value');
        System.assertEquals(5, result.get('InvoiceOrders'), 'InvoiceOrders should match inserted value');
    }
    
    // Helper method to dynamically get dependent picklist values
    private static Map<String, List<String>> getDependentPicklistValues() {
        Map<String, List<String>> result = new Map<String, List<String>>();
        
        // Get the dependent picklist info
        Schema.DescribeFieldResult plantNameField = Account.Plant_Name__c.getDescribe();
        Schema.sObjectField controllingField = plantNameField.getController();
        
        if (controllingField == null) {
            return result;
        }
        
        // Get all valid controlling values
        List<Schema.PicklistEntry> controllingValues = controllingField.getDescribe().getPicklistValues();
        
        // For each controlling value, get valid dependent values
        for (Schema.PicklistEntry ple : controllingValues) {
            String controllingValue = ple.getValue();
            
            // Get valid dependent values for this controlling value
            List<Schema.PicklistEntry> dependentEntries = plantNameField.getPicklistValues();
            List<String> dependentValues = new List<String>();
            
            for (Schema.PicklistEntry depPLE : dependentEntries) {
                if (depPLE.isActive() && String.isNotBlank(depPLE.getValue())) {
                    dependentValues.add(depPLE.getValue());
                }
            }
            
            if (!dependentValues.isEmpty()) {
                result.put(controllingValue, dependentValues);
            }
        }
        
        return result;
    }
}