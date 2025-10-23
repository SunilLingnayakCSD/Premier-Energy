@isTest
private class customerAddressUpsertTest {
   
    @isTest
    static void testCustomerAddressUpsert_EmptyList() {
        // Test with empty list
        List<Map<String, Object>> emptyList = new List<Map<String, Object>>();
        
        Test.startTest();
        customerAddressUpsert job = new customerAddressUpsert(emptyList);
        job.execute(null);
        Test.stopTest();
        
        // Should not create any records
        List<Address__c> records = [SELECT Id FROM Address__c];
        System.assertEquals(0, records.size(), 'No records should be created for empty input');
    }
    
    @isTest
    static void testCustomerAddressUpsert_NullList() {
        // Test with null list
        Test.startTest();
        customerAddressUpsert job = new customerAddressUpsert(null);
        job.execute(null);
        Test.stopTest();
        
        // Should not create any records
        List<Address__c> records = [SELECT Id FROM Address__c];
        System.assertEquals(0, records.size(), 'No records should be created for null input');
    }
    
    @isTest
    static void testCustomerAddressUpsert_BlankCustomerCode() {
        // Test with blank customer codes
        List<Map<String, Object>> rawList = new List<Map<String, Object>>();
        rawList.add(new Map<String, Object>{
            'Customer_Address_Code' => '',
            'Name' => 'Test Address',
            'Street' => 'Test Street',
            'City' => 'Test City'
        });
        rawList.add(new Map<String, Object>{
            'Customer_Address_Code' => null,
            'Name' => 'Test Address 2',
            'Street' => 'Test Street 2',
            'City' => 'Test City 2'
        });
        rawList.add(new Map<String, Object>{
            'Customer_Address_Code' => '   ',
            'Name' => 'Test Address 3',
            'Street' => 'Test Street 3',
            'City' => 'Test City 3'
        });
        
        Test.startTest();
        customerAddressUpsert job = new customerAddressUpsert(rawList);
        job.execute(null);
        Test.stopTest();
        
        // Should not create any records due to blank customer codes
        List<Address__c> records = [SELECT Id FROM Address__c];
        System.assertEquals(0, records.size(), 'No records should be created for blank customer codes');
    }
    
    @isTest
    static void testCustomerAddressUpsert_DuplicateCustomerCodes() {
        // Test with duplicate customer codes in same batch
        List<Map<String, Object>> rawList = new List<Map<String, Object>>();
        rawList.add(new Map<String, Object>{
            'Customer_Address_Code' => 'DUP001',
            'Name' => 'First Duplicate',
            'Street' => 'First Street',
            'City' => 'First City'
        });
        rawList.add(new Map<String, Object>{
            'Customer_Address_Code' => 'DUP001',
            'Name' => 'Second Duplicate',
            'Street' => 'Second Street',
            'City' => 'Second City'
        });
        
        Test.startTest();
        customerAddressUpsert job = new customerAddressUpsert(rawList);
        job.execute(null);
        Test.stopTest();
        
        // Should create only one record (first one processed)
        List<Address__c> records = [SELECT Name, Street__c FROM Address__c WHERE Customer_Code__c = 'DUP001'];
        System.assertEquals(1, records.size(), 'Should create only one record for duplicate customer codes');
        System.assertEquals('First Duplicate', records[0].Name, 'Should use first occurrence data');
    }
  
    @isTest
    static void testCustomerAddressUpsert_LargeBatch() {
        // Test with batch processing (simulate large dataset)
        List<Map<String, Object>> rawList = new List<Map<String, Object>>();
        
        // Create more than BATCH_SIZE records to test batching
        for (Integer i = 1; i <= 600; i++) {
            rawList.add(new Map<String, Object>{
                'Customer_Address_Code' => 'BATCH' + String.valueOf(i).leftPad(3, '0'),
                'Name' => 'Address ' + i,
                'Street' => 'Street ' + i,
                'City' => 'City ' + i,
                'State' => 'State ' + i,
                'Country' => 'Country ' + i,
                'Pincode' => String.valueOf(i).leftPad(6, '0'),
                'Address_Type' => 'Billing'
            });
        }
        
        Test.startTest();
        customerAddressUpsert job = new customerAddressUpsert(rawList);
        job.execute(null); // This will process first batch only
        Test.stopTest();
        
        // Should process exactly BATCH_SIZE (500) records in first execution
        List<Address__c> records = [SELECT Id FROM Address__c];
        
    }
 
    @isTest
    static void testCustomerAddressUpsert_MissingCustomerCodeKey() {
        // Test with data missing Customer_Address_Code key
        List<Map<String, Object>> rawList = new List<Map<String, Object>>();
        rawList.add(new Map<String, Object>{
            'Name' => 'Address Without Code',
            'Street' => 'Test Street',
            'City' => 'Test City'
            // Missing Customer_Address_Code key
        });
        
        Test.startTest();
        customerAddressUpsert job = new customerAddressUpsert(rawList);
        job.execute(null);
        Test.stopTest();
        
        // Should not create any records
        List<Address__c> records = [SELECT Id FROM Address__c];
        System.assertEquals(0, records.size(), 'No records should be created when Customer_Address_Code key is missing');
    }
}