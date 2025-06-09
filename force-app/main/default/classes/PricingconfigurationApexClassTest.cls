@isTest
private class PricingconfigurationApexClassTest {
    // Test data setup
    @TestSetup
    static void createTestData() {
        List<Raw_Materials__c> testMaterials = new List<Raw_Materials__c>();
        
        // Create materials with different sort orders and quantities
        testMaterials.add(new Raw_Materials__c(
            Name = 'Material A',
            Sort__c = 3,
            Qty_20_Ft__c = 100,
            Qty_40_Ft__c = 200,
            UOM__c = 'Pcs',
            Select_Raw_Material_Type__c='wafer'
        ));
        
        testMaterials.add(new Raw_Materials__c(
            Name = 'Material B',
            Sort__c = 1,
            Qty_20_Ft__c = 50,
            Qty_40_Ft__c = 100,
            UOM__c = 'Pcs',
            Select_Raw_Material_Type__c='wafer'
        ));
        
        testMaterials.add(new Raw_Materials__c(
            Name = 'Material C',
            Sort__c = 2,
            Qty_20_Ft__c = 75,
            Qty_40_Ft__c = 150,
            UOM__c = 'Pcs',
            Select_Raw_Material_Type__c='wafer'
        ));
        
        insert testMaterials;
    }

    // Test basic functionality - record retrieval and ordering
    @isTest
    static void testGet20FtAnd40FtBasic() {
        Test.startTest();
        List<Raw_Materials__c> results = pricingconfigurationApexClass.get20FtAnd40Ft();
        Test.stopTest();

        // Verify correct number of records
        System.assertEquals(3, results.size(), 'Should return all test records');
        
        // Verify correct sort order (ascending by Sort__c)
        System.assertEquals('Material B', results[0].Name, 'First record should have lowest Sort__c');
        System.assertEquals('Material C', results[1].Name, 'Second record should have middle Sort__c');
        System.assertEquals('Material A', results[2].Name, 'Last record should have highest Sort__c');
    }

    // Test field values are correctly populated
    @isTest
    static void testFieldValues() {
        List<Raw_Materials__c> results = pricingconfigurationApexClass.get20FtAnd40Ft();
        
        // Find Material B (should be first due to sort order)
        Raw_Materials__c materialB;
        for(Raw_Materials__c rm : results) {
            if(rm.Name == 'Material B') {
                materialB = rm;
                break;
            }
        }
        
        // Verify field values
        System.assertNotEquals(null, materialB, 'Material B should be present');
        System.assertEquals(50, materialB.Qty_20_Ft__c, 'Qty_20_Ft__c should match');
        System.assertEquals(100, materialB.Qty_40_Ft__c, 'Qty_40_Ft__c should match');
        System.assertEquals('Pcs', materialB.UOM__c, 'UOM__c should match');
    }

    // Test empty table scenario
    @isTest
    static void testNoRecordsReturned() {
        // Delete all test data
        delete [SELECT Id FROM Raw_Materials__c];
        
        Test.startTest();
        List<Raw_Materials__c> results = pricingconfigurationApexClass.get20FtAnd40Ft();
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list when no records exist');
    }

    // Test bulk data handling (200+ records)
    @isTest
    static void testBulkDataHandling() {
        // Create additional 200 records
        List<Raw_Materials__c> bulkMaterials = new List<Raw_Materials__c>();
        for(Integer i = 0; i < 200; i++) {
            bulkMaterials.add(new Raw_Materials__c(
                Name = 'Bulk Material ' + i,
                Sort__c = 10 + i,
                Qty_20_Ft__c = i * 10,
                Qty_40_Ft__c = i * 20,
                Select_Raw_Material_Type__c='wafer'
            ));
        }
        insert bulkMaterials;
        
        Test.startTest();
        List<Raw_Materials__c> results = pricingconfigurationApexClass.get20FtAnd40Ft();
        Test.stopTest();
        
        System.assertEquals(203, results.size(), 'Should return all 203 records (3 from setup + 200 new)');
        System.assertEquals('Material B', results[0].Name, 'First record should still be Material B with lowest sort value');
    }

    

    
    
}