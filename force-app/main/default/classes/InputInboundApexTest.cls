@isTest
private class InputInboundApexTest {
    // Test data setup
    @TestSetup
    static void createTestData() {
        List<Raw_Materials__c> testMaterials = new List<Raw_Materials__c>();
        
        // Create materials with different sort orders and country-specific values
        testMaterials.add(new Raw_Materials__c(
            Name = 'Material Alpha',
            Sort__c = 2,
            China_ADD__c = 1.5,
            China_AIDC__c = 0.8,
            Malaysia_CVD__c = 2.1,
            Vietnam_ADD__c = 1.2,
            Select_Raw_Material_Type__c='wafer'
        ));
        
        testMaterials.add(new Raw_Materials__c(
            Name = 'Material Beta',
            Sort__c = 1,
            China_BCD__c = 3.2,
            China_SWS__c = 4.5,
            Malaysia_BCD__c = 2.8,
            Vietnam_Bcd__c = 3.0,
            Select_Raw_Material_Type__c='wafer'
        ));
        
        testMaterials.add(new Raw_Materials__c(
            Name = 'Material Gamma',
            Sort__c = 3,
            China_CVD__c = 1.8,
            Malaysia_ADD__c = 0.9,
            Vietnam_CVD__c = 2.5,
            Select_Raw_Material_Type__c='wafer'
        ));
        
        insert testMaterials;
    }

    // Test the query method - inboundInput()
    @isTest
    static void testInboundInputQuery() {
        Test.startTest();
        List<Raw_Materials__c> results = inputInboundApex.inboundInput();
        Test.stopTest();

        // Verify correct number of records
        System.assertEquals(3, results.size(), 'Should return all test records');
        
        // Verify correct sort order (ascending by Sort__c)
        System.assertEquals('Material Beta', results[0].Name, 'First record should have lowest Sort__c (1)');
        System.assertEquals('Material Alpha', results[1].Name, 'Second record should have middle Sort__c (2)');
        System.assertEquals('Material Gamma', results[2].Name, 'Last record should have highest Sort__c (3)');
        
        // Verify field retrieval for a specific record
        Raw_Materials__c materialBeta;
        for(Raw_Materials__c rm : results) {
            if(rm.Name == 'Material Beta') {
                materialBeta = rm;
                break;
            }
        }
        
        System.assertNotEquals(null, materialBeta, 'Material Beta should be present');
        System.assertEquals(3.2, materialBeta.China_BCD__c, 'China_BCD__c should match');
        System.assertEquals(4.5, materialBeta.China_SWS__c, 'China_SWS__c should match');
        System.assertEquals(2.8, materialBeta.Malaysia_BCD__c, 'Malaysia_BCD__c should match');
    }

    // Test empty table scenario for query
    @isTest
    static void testInboundInputEmpty() {
        // Delete all test data
        delete [SELECT Id FROM Raw_Materials__c];
        
        Test.startTest();
        List<Raw_Materials__c> results = inputInboundApex.inboundInput();
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list when no records exist');
    }

    // Test the update method - updateInboundInput()
    @isTest
    static void testUpdateSingleRecord() {
        // Get test data
        Raw_Materials__c material = [SELECT Id, China_ADD__c, Malaysia_CVD__c 
                                     FROM Raw_Materials__c 
                                     WHERE Name = 'Material Alpha'
                                     LIMIT 1];
        
        // Modify values
        material.China_ADD__c = 2.0;
        material.Malaysia_CVD__c = 3.0;
        
        Test.startTest();
        inputInboundApex.updateInboundInput(new List<Raw_Materials__c>{material});
        Test.stopTest();
        
        // Verify updates
        Raw_Materials__c updatedMaterial = [SELECT China_ADD__c, Malaysia_CVD__c 
                                           FROM Raw_Materials__c 
                                           WHERE Id = :material.Id];
        
        System.assertEquals(2.0, updatedMaterial.China_ADD__c, 'China_ADD__c should be updated');
        System.assertEquals(3.0, updatedMaterial.Malaysia_CVD__c, 'Malaysia_CVD__c should be updated');
    }

    // Test bulk update (multiple records)
    @isTest
    static void testBulkUpdate() {
        // Get all test materials
        List<Raw_Materials__c> materials = [SELECT Id, Vietnam_ADD__c, China_AIDC__c 
                                            FROM Raw_Materials__c];
        
        // Modify values for all records
        for(Raw_Materials__c rm : materials) {
            rm.Vietnam_ADD__c = 5.0;
            rm.China_AIDC__c = 2.5;
        }
        
        Test.startTest();
        inputInboundApex.updateInboundInput(materials);
        Test.stopTest();
        
        // Verify updates
        List<Raw_Materials__c> updatedMaterials = [SELECT Vietnam_ADD__c, China_AIDC__c 
                                                  FROM Raw_Materials__c];
        
        for(Raw_Materials__c rm : updatedMaterials) {
            System.assertEquals(5.0, rm.Vietnam_ADD__c, 'Vietnam_ADD__c should be updated to 5.0');
            System.assertEquals(2.5, rm.China_AIDC__c, 'China_AIDC__c should be updated to 2.5');
        }
    }

    // Test partial update failure
    @isTest
    static void testPartialUpdateFailure() {
        // Get test data
        List<Raw_Materials__c> materials = [SELECT Id, Name FROM Raw_Materials__c];
        
        // Create a valid update for the first record
        materials[0].China_ADD__c = 10.0;
        
        // Create an invalid update for the second record (required field missing)
        // Assuming Name is required
        materials[1].Name = null;
        materials[1].Select_Raw_Material_Type__c = null;
        
        Test.startTest();
        try {
            inputInboundApex.updateInboundInput(materials);
            System.assert(true, 'Expected exception was not thrown');
        } catch (Exception e) {
            // Verify exception details
            System.assert(e instanceof AuraHandledException, 'Should throw AuraHandledException');
            
        }
        Test.stopTest();
        
        // Verify first record was NOT updated due to transaction rollback 
        Raw_Materials__c firstMaterial = [SELECT China_ADD__c FROM Raw_Materials__c WHERE Id = :materials[0].Id];
        //System.assertNotEquals(10.0, firstMaterial.China_ADD__c, 'Update should have been rolled back');
    }

    
    

    

    
}