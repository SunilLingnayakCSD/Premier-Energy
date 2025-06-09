@isTest
private class LeadCountApexTest {

    // Generate a unique username to avoid duplicate username errors in test runs
    private static String generateUniqueUsername() {
        return 'testuser.' + System.currentTimeMillis() + '.' + Crypto.getRandomInteger() + '@example.com';
    }

    // Get a community or standard user profile ID
    private static Id getCommunityProfileId() {
        Profile prof = [
            SELECT Id FROM Profile 
            WHERE UserType IN ('PowerCustomerSuccess', 'PowerPartner') 
            LIMIT 1
        ];
        if(prof != null) return prof.Id;

        return [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
    }

    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Lead Distributor Account');
        insert acc;

        // Create Contact with required mailing address fields to pass validation
        Contact con = new Contact(
            LastName = 'LeadTestContact',
            AccountId = acc.Id,
            MailingStreet = '123 Test St',
            MailingCity = 'Test City',
            MailingState = 'Karnataka',
            MailingPostalCode = '12345',
            MailingCountry = 'India'
        );
        insert con;

        // Create User linked to Contact
        User testUser = new User(
            Username = generateUniqueUsername(),
            Alias = 'tuser',
            Email = 'testuser123@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'LeadTestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = getCommunityProfileId(),
            ContactId = con.Id
        );
        insert testUser;

        // Create leads related to the user
        List<Lead> leads = new List<Lead>();

        leads.add(new Lead(
            LastName = 'OpenLead',
            Company = 'Test Company',
            Status = 'New',
            Distributor__c = testUser.Id,
            state='karnaraka',
            country='India'
        ));

        leads.add(new Lead(
            LastName = 'RejectedLead',
            Company = 'Test Company',
            Status = 'Rejected',
            Distributor__c = testUser.Id
        ));

        leads.add(new Lead(
            LastName = 'ConvertedLead',
            Company = 'Test Company',
            Status = 'Closed - Converted',
            Distributor__c = testUser.Id,
            Purchased_Premier_Module__c = 'Yes'
        ));

        leads.add(new Lead(
            LastName = 'ConvertedRejectedLead',
            Company = 'Test Company',
            Status = 'Rejected',
            Distributor__c = testUser.Id,
            Purchased_Premier_Module__c = 'Yes',
            state='Andhra Pradesh',
            country='India'
        ));

        insert leads;
    }

    @isTest
    static void testLeadMethodCounts() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'LeadTestUser' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            Date startDate = System.today().addDays(-5);
            Date endDate = System.today();
            Map<String, Integer> counts = LeadCountApex.LeadMethod(startDate, endDate);
            Test.stopTest();

            System.assertNotEquals(null, counts, 'Counts should not be null');

            System.assertEquals(4, counts.get('total'), 'Expected 4 total leads');
            System.assertEquals(1, counts.get('open'), 'Expected 1 open lead');
            System.assertEquals(2, counts.get('rejected'), 'Expected 2 rejected leads');
            System.assertEquals(2, counts.get('converted'), 'Expected 2 converted leads');
            System.assertEquals(0, counts.get('closed'), 'Expected 0 closed leads');
        }
    }
}