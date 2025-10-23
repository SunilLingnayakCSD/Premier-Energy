@isTest
private class InvoiceCountControllerTest {
    
    // Helper method to generate unique usernames
    private static String generateUniqueUsername() {
        return 'testuser.' + System.currentTimeMillis() + '.' + Crypto.getRandomInteger() + '@example.com';
    }

    // Helper method to get valid Community Profile ID
    private static Id getCommunityProfileId() {
        // Try to find a valid Community profile
        List<Profile> communityProfiles = [SELECT Id FROM Profile WHERE UserType IN ('PowerCustomerSuccess', 'PowerPartner') LIMIT 1];
        if(!communityProfiles.isEmpty()) {
            return communityProfiles[0].Id;
        }
        
        // Fallback to Standard User if no Community profile found
        return [SELECT Id FROM Profile WHERE Name = 'Partner Distributor Access' LIMIT 1].Id;
    }

    @testSetup
    static void setupTestData() {
        // Query existing Distributor RecordType for Account
        RecordType distributorRT = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Distributor' 
            AND SObjectType = 'Account'
            LIMIT 1
        ];

        // Create Account with Distributor RecordType
        Account acc = new Account(
            Name = 'Test Distributor Account',
            RecordTypeId = distributorRT.Id
        );
        insert acc;

        // Create Contact linked to Account
        Contact con = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert con;

        // Get valid profile ID - use Standard User profile to avoid community user issues
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Partner Distributor Access' LIMIT 1].Id;

        // Create User with the Contact linked
        User testUser = new User(
            Username = generateUniqueUsername(),
            Alias = 'testusr',
            Email = 'testuser123@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = profileId,
            ContactId = con.Id
        );
        insert testUser;

        // Create Invoice__c records
        List<Invoice__c> invoices = new List<Invoice__c>();
        for (Integer i = 0; i < 5; i++) {
            invoices.add(new Invoice__c(
                Name = 'Invoice ' + i,
                Account__c = acc.Id,
                POD_Status__c = 'pending',
                POD_Date__c = System.today().addDays(-i),
                Status__c = 'pending',
                FTR_Upload_Date__c = System.today().addDays(-i)
            ));
        }
        insert invoices;
    }

    @isTest
    static void testGetInvoiceCounts() {
        // Query user created in setup
        User testUser = [SELECT Id FROM User WHERE Contact.Account.Name = 'Test Distributor Account' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            Date startDate = System.today().addDays(-7);
            Date endDate = System.today();
            Map<String, Integer> counts = InvoiceCount.getInvoiceCounts(startDate, endDate);
            Test.stopTest();

            // Assertions
            System.assertNotEquals(null, counts, 'Counts should not be null');
            System.assert(counts.containsKey('totalInvoices'), 'Missing totalInvoices key');
            System.assert(counts.containsKey('totalPODInvoices'), 'Missing totalPODInvoices key');
            System.assert(counts.containsKey('totalFTRInvoices'), 'Missing totalFTRInvoices key');
            System.assertEquals(5, counts.get('totalInvoices'), 'Expected 5 total invoices');
            System.assertEquals(5, counts.get('totalPODInvoices'), 'Expected 5 POD invoices');
            System.assertEquals(5, counts.get('totalFTRInvoices'), 'Expected 5 FTR invoices');
        }
    }

   /* @isTest
    static void testNoContactUserScenario() {
        // Create a standard user without a contact
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Partner Distributor Access' LIMIT 1];
        User noContactUser = new User(
            Username = generateUniqueUsername(),
            Alias = 'nocusr',
            Email = 'nocontactuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NoContactUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = standardProfile.Id
        );
        insert noContactUser;

        System.runAs(noContactUser) {
            Test.startTest();
            try {
                InvoiceCount.getInvoiceCounts(System.today().addDays(-5), System.today());
                System.assert(false, 'Expected exception for missing Contact');
            } catch (AuraHandledException ex) {
                // Expected exception
                System.assert(ex.getMessage().contains('User is not associated with a Contact'), 
                    'Expected error about missing Contact association');
            }
            Test.stopTest();
        }
    } */

    @isTest
    static void testEmptyDateRange() {
        User testUser = [SELECT Id FROM User WHERE Contact.Account.Name = 'Test Distributor Account' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            Map<String, Integer> counts = InvoiceCount.getInvoiceCounts(null, null);
            Test.stopTest();

            // Assertions - should still return counts for all time
            System.assertNotEquals(null, counts, 'Counts should not be null');
            System.assertEquals(5, counts.get('totalInvoices'), 'Expected 5 total invoices');
        }
    }

    @isTest
    static void testInvalidDateRange() {
        User testUser = [SELECT Id FROM User WHERE Contact.Account.Name = 'Test Distributor Account' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            Map<String, Integer> counts = InvoiceCount.getInvoiceCounts(System.today(), System.today().addDays(-1));
            Test.stopTest();

            // Assertions - should return 0 counts for invalid range
            System.assertNotEquals(null, counts, 'Counts should not be null');
            System.assertEquals(0, counts.get('totalInvoices'), 'Expected 0 invoices for invalid date range');
        }
    }
}