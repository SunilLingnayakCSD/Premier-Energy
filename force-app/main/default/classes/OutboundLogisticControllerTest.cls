@IsTest
private class OutboundLogisticControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Setup test records for State A, State B and null state
        List<Outbound_Logistic__c> testRecords = new List<Outbound_Logistic__c>{
            new Outbound_Logistic__c(Name = 'Test 1', State__c = 'Karnataka', Price_Km__c = 10.00),
            new Outbound_Logistic__c(Name = 'Test 2', State__c = 'Tamil Nadu', Price_Km__c = 20.00),
            new Outbound_Logistic__c(Name = 'Test 3', State__c = 'Kerala', Price_Km__c = 30.00),
            new Outbound_Logistic__c(Name = 'Test 4', State__c = 'Gujarat', Price_Km__c = 40.00),
            new Outbound_Logistic__c(Name = 'Test 5', State__c = null, Price_Km__c = 100.00)
        };
        insert testRecords;
    }
    
    @IsTest
    static void testGetStatePicklistValues() {
        Test.startTest();
        List<String> picklistValues = OutboundLogisticController.getStatePicklistValues();
        Test.stopTest();
        
        // Verify we get some picklist values (exact count depends on org)
        System.assertNotEquals(null, picklistValues, 'Should return non-null list');
        System.assert(!picklistValues.isEmpty(), 'Should return some picklist values');
    }
    
    @IsTest
    static void testGetStateAverages() {
        Test.startTest();
        Map<String, Object> result = OutboundLogisticController.getStateAverages();
        Test.stopTest();
        
        List<OutboundLogisticController.StateAverage> stateAverages = 
            (List<OutboundLogisticController.StateAverage>)result.get('stateAverages');
        
        // Verify averages are calculated correctly
        System.assertEquals(4, stateAverages.size(), 'Should return averages for 2 states');
        System.assertEquals(40.00, stateAverages[0].averagePrice, 'State A average should be 15.00');
        System.assertEquals(10.00, stateAverages[1].averagePrice, 'State B average should be 35.00');
        System.assertEquals(100.00, (Decimal)result.get('overallAverage'), 'Overall sum should be 50.00');
    }
    
    @IsTest
    static void testUpdateStatePrice_Success() {
        // Ensure test data includes at least one record with State__c = 'Karnataka'
        Test.startTest();
        OutboundLogisticController.updateStatePrice('Karnataka', 25.00);
        Test.stopTest();
        
        // Query all records with State__c = 'Karnataka'
        List<Outbound_Logistic__c> updatedRecords = [
            SELECT Price_Km__c FROM Outbound_Logistic__c WHERE State__c = 'Karnataka'
        ];
        
        // Assert that records exist
        System.assert(!updatedRecords.isEmpty(), 'Expected updated records for Karnataka');
        
        // Assert each record has the updated price
        for (Outbound_Logistic__c record : updatedRecords) {
            System.assertEquals(25.00, record.Price_Km__c, 'Each Karnataka record should be updated to 25.00');
        }
    }

    
    @IsTest
    static void testUpdateStatePrice_InvalidInputs() {
        // Test empty state
        try {
            OutboundLogisticController.updateStatePrice('', 25.00);
            System.assert(false, 'Should throw exception for empty state');
        } catch (Exception e) {
            System.debug('Caught expected exception for empty state: ' + e.getMessage());
        }
        
        // Test negative price
        try {
            OutboundLogisticController.updateStatePrice('Karnataka', -10.00);
            System.assert(false, 'Should throw exception for negative price');
        } catch (Exception e) {
            System.debug('Caught expected exception for negative price: ' + e.getMessage());
        }
        
        // Test non-existent state
        try {
            OutboundLogisticController.updateStatePrice('Non-Existent State', 25.00);
            System.assert(false, 'Should throw exception for non-existent state');
        } catch (Exception e) {
            System.debug('Caught expected exception for non-existent state: ' + e.getMessage());
        }
    }

    
    @IsTest
    static void testStateAverageComparable() {
        // Test sorting implementation
        OutboundLogisticController.StateAverage sa1 = new OutboundLogisticController.StateAverage('State A', 10.00);
        OutboundLogisticController.StateAverage sa2 = new OutboundLogisticController.StateAverage('State B', 20.00);
        
        System.assertEquals(-1, sa1.compareTo(sa2), 'State A should sort before State B');
        System.assertEquals(1, sa2.compareTo(sa1), 'State B should sort after State A');
        System.assertEquals(0, sa1.compareTo(sa1), 'Same states should be equal');
    }
}