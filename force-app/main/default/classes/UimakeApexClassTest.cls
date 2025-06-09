@isTest
private class UimakeApexClassTest {
    // Test data setup method
    @TestSetup
    static void makeData() {
        List<Raw_Materials__c> testMaterials = new List<Raw_Materials__c>();
        String[] materialNames = new String[]{'Steel Alloy', 'Aluminum Composite', 'Copper Wire Steel', 'Test Plastic'};
        
        // Create 4 test materials with different names
        for(Integer i = 0; i < materialNames.size(); i++) {
            testMaterials.add(new Raw_Materials__c(
                Name = materialNames[i],
                Sort__c = i,
                UOM__c = 'kg',
                Select_Raw_Material_Type__c='wafer'
               
            ));
        }
        insert testMaterials;
    }

    // Test exact match search
    @isTest
    static void testSearchExactMatch() {
        List<Raw_Materials__c> results = UimakeApexClass.RawMaterialsNamesQueryANdUom('Steel Alloy');
        System.assertEquals(1, results.size(), 'Should return exactly 1 record for exact match');
        System.assertEquals('Steel Alloy', results[0].Name, 'Returned record should match search key');
    }

    // Test partial match search
    @isTest
    static void testSearchPartialMatch() {
        List<Raw_Materials__c> results = UimakeApexClass.RawMaterialsNamesQueryANdUom('Steel');
        System.assertEquals(2, results.size(), 'Should return 2 records containing "Steel"');
    }

    // Test no results found
    @isTest
    static void testSearchNoResults() {
        List<Raw_Materials__c> results = UimakeApexClass.RawMaterialsNamesQueryANdUom('NonexistentMaterial');
        System.assertEquals(0, results.size(), 'Should return no records for non-matching search');
    }

    // Test empty search key
    @isTest
    static void testEmptySearch() {
        List<Raw_Materials__c> results = UimakeApexClass.RawMaterialsNamesQueryANdUom('');
        System.assertEquals(4, results.size(), 'Empty search should return all records');
    }

    // Test null search key
    @isTest
    static void testNullSearch() {
        List<Raw_Materials__c> results = UimakeApexClass.RawMaterialsNamesQueryANdUom(null);
       
    }

    // Test sorting order
    @isTest
    static void testSortOrder() {
        List<Raw_Materials__c> results = UimakeApexClass.RawMaterialsNamesQueryANdUom('');
        System.assertEquals(0, results[0].Sort__c, 'First record should have lowest sort value');
        System.assertEquals(1, results[1].Sort__c, 'Records should be ordered by Sort__c ASC');
        System.assertEquals(3, results[3].Sort__c, 'Last record should have highest sort value');
    }

    // Test field population
    @isTest
    static void testFieldValues() {
        List<Raw_Materials__c> results = UimakeApexClass.RawMaterialsNamesQueryANdUom('Steel Alloy');
        Raw_Materials__c material = results[0];
        
        
        System.assertEquals(0, material.China_Low_Price__c, 'China Low Price should match test data');
        System.assertEquals(0, material.India_Low_Price__c, 'India Low Price should match test data');
    }

    // Test with special characters
    @isTest
    static void testSpecialCharacters() {
        List<Raw_Materials__c> results = UimakeApexClass.RawMaterialsNamesQueryANdUom('*');
        System.assertEquals(0, results.size(), 'Should handle special characters safely');
    }

    // Test bulk data handling (200+ records)
    @isTest
    static void testBulkSearch() {
        // Create 200 additional test materials
        List<Raw_Materials__c> bulkMaterials = new List<Raw_Materials__c>();
        for(Integer i = 0; i < 200; i++) {
            bulkMaterials.add(new Raw_Materials__c(
                Name = 'BulkMaterial' + i,
                Sort__c = i + 10,
                UOM__c = 'set',
                Select_Raw_Material_Type__c='wafer'
            ));
        }
        insert bulkMaterials;

        Test.startTest();
        List<Raw_Materials__c> results = UimakeApexClass.RawMaterialsNamesQueryANdUom('BulkMaterial');
        Test.stopTest();

        System.assertEquals(200, results.size(), 'Should return all 200 bulk records');
    }
}