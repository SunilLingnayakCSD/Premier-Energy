@isTest
private class LeadAssignmentBasedOnRegionTest {

    @testSetup
    static void setupTestData() {
        // Fetch existing User Roles by DeveloperName
        Map<String, Id> roleMap = new Map<String, Id>();
        for (UserRole ur : [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN ('India_Lead_Manager', 'Key_Accounts_International_Head_Private')]) {
            roleMap.put(ur.DeveloperName, ur.Id);
        }

        // Create Users for those roles
        List<User> users = new List<User>();
        users.add(new User(
            Username = 'indiamanager@test.com',
            Alias = 'imgr',
            Email = 'imanager@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'India Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            UserRoleId = roleMap.get('India_Lead_Manager')
        ));

        users.add(new User(
            Username = 'intlprivate@test.com',
            Alias = 'iprvt',
            Email = 'iprivate@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Intl Private Head',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            UserRoleId = roleMap.get('Key_Accounts_International_Head_Private')
        ));

        insert users;
    }

    @isTest
    static void testAssignLeads() {
        // Query existing record types for Lead
        Map<String, RecordType> recordTypeMap = new Map<String, RecordType>();
        for (RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Lead']) {
            recordTypeMap.put(rt.DeveloperName, rt);
        }

        // Validate if required record types exist before proceeding
        System.assert(recordTypeMap.containsKey('Key_Account_Private'), 'Key_Account_Private record type missing');

        // Create test leads with valid address data and picklist values
        List<Lead> leadsToInsert = new List<Lead>();

        // Lead 1
        leadsToInsert.add(new Lead(
            LastName = 'Test Intl Lead 1',
            Company = 'Test Company',
            Street = '123 Main Street',
            City = 'Hyderabad',
            State = 'Andhra Pradesh',  // must match active picklist value in your org
            PostalCode = '500001',
            Country = 'India',
            Region_Picklist__c = 'East',
            RecordTypeId = recordTypeMap.get('Key_Account_Private').Id
        ));

        // Lead 2
        leadsToInsert.add(new Lead(
            LastName = 'Test Intl Lead 2',
            Company = 'Test Company',
            Street = '456 Market Street',
            City = 'Vijayawada',
            State = 'Andhra Pradesh',  // same known valid state
            PostalCode = '520001',
            Country = 'India',
            Region_Picklist__c = 'South',
            RecordTypeId = recordTypeMap.get('Key_Account_Private').Id
        ));
        // Lead 2
        leadsToInsert.add(new Lead(
            LastName = 'Test Intl Lead 2',
            Company = 'Test Company',
            Street = '456 Market Street',
            City = 'vgh',
            State = 'victoria',  // same known valid state
            PostalCode = '520001',
            Country = 'australia',
            Region_Picklist__c = 'South',
            RecordTypeId = recordTypeMap.get('Key_Account_Private').Id
        ));

        // Insert test leads
        insert leadsToInsert;

        // Prepare Map<Id, RecordType> for assignment method
        Map<Id, RecordType> recordTypeIdMap = new Map<Id, RecordType>();
        for (RecordType rt : recordTypeMap.values()) {
            recordTypeIdMap.put(rt.Id, rt);
        }

        // Execute the actual logic under test
        Test.startTest();
        LeadAssignmentBasedOnRegionAndRecordType.assignLeads(leadsToInsert, recordTypeIdMap);
        Test.stopTest();

        // Assert: verify leads got owners assigned
        List<Lead> updatedLeads = [
            SELECT Id, OwnerId, Owner.UserRole.DeveloperName 
            FROM Lead 
            WHERE Id IN :leadsToInsert
        ];

        for (Lead l : updatedLeads) {
            System.assert(l.OwnerId != null, 'Owner should be assigned for Lead Id: ' + l.Id);
        }
    }
}