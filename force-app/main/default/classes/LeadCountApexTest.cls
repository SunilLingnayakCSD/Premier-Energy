@isTest
private class LeadCountApexTest {

    // Generate a unique username to avoid duplicate username errors in test runs
    private static String generateUniqueUsername() {
        return 'testuser.' + System.currentTimeMillis() + '.' + Crypto.getRandomInteger() + '@example.com';
    }

    // Get appropriate profile based on your org's distributor requirements
    private static Id getDistributorProfileId() {
        // First try to get a profile that matches distributor criteria
        List<Profile> profiles = [
            SELECT Id, Name FROM Profile 
            WHERE UserType IN ('Standard', 'PowerCustomerSuccess', 'PowerPartner') 
            AND Name LIKE '%Distributor%'
            LIMIT 1
        ];
        
        if (!profiles.isEmpty()) {
            return profiles[0].Id;
        }
        
        // Fallback to Standard User if no distributor-specific profile found
       return [SELECT Id FROM Profile WHERE Name = 'Partner Distributor Access' LIMIT 1].Id;
    }

    @testSetup
    static void setupTestData() {
        // Create Account with fields that might be required for distributor validation
        Account acc = new Account(
            Name = 'Lead Distributor Account',
            Type = 'Distributor' // This might be required for distributor accounts
        );
        insert acc;

        // Create Contact with all required fields
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

        // Create User with distributor-appropriate profile
        User testUser = new User(
            Username = generateUniqueUsername(),
            Alias = 'tuser',
            Email = 'testuser123@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'LeadTestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = getDistributorProfileId(),
            ContactId = con.Id,
            IsActive = true
        );
        insert testUser;

        // Alternative approach: Use SeeAllData=true and query existing valid distributor
        // Or create test data without Distributor__c field first, then update with valid user
        
        System.runAs(testUser) {
            // Create leads - Method 1: Try direct creation
            List<Lead> leads = new List<Lead>();

            try {
                leads.add(new Lead(
                    LastName = 'OpenLead',
                    Company = 'Test Company',
                    Status = 'New',
                     //Purchased_Premier_Module__c = 'Yes',
                    Distributor__c = testUser.Id,
                    State = 'Karnataka', // Note: corrected capitalization
                    Country = 'India',
                    DCR_Non_DCR1__c = 'DCR',
                     Reason_for_Rejection__c = 'Test Rejection Reason' // Add rejection reason
                ));

                leads.add(new Lead(
                    LastName = 'RejectedLead',
                    Company = 'Test Company',
                    Status = 'Rejected',
                     //Purchased_Premier_Module__c = 'Yes',
                    Distributor__c = testUser.Id,
                    State = 'Karnataka',
                    Country = 'India',
                    DCR_Non_DCR1__c = 'DCR',
                   Reason_for_Rejection__c = 'Test Rejection Reason' // Add rejection reason
                   
                ));

                leads.add(new Lead(
                    LastName = 'ConvertedLead',
                    Company = 'Test Company',
                    Status = 'Closed - Converted',
                    Distributor__c = testUser.Id,
                   // Purchased_Premier_Module__c = 'Yes',
                    State = 'Karnataka',
                    Country = 'India',
                    DCR_Non_DCR1__c = 'DCR',
                      Reason_for_Rejection__c = 'Test Rejection Reason' // Add rejection reason
                ));

                leads.add(new Lead(
                    LastName = 'ConvertedRejectedLead',
                    Company = 'Test Company',
                    Status = 'Rejected',
                    Distributor__c = testUser.Id,
                    //Purchased_Premier_Module__c = 'Yes',
                    State = 'Karnataka',
                    Country = 'India',
                    DCR_Non_DCR1__c = 'DCR',
                    Reason_for_Rejection__c = 'Test Rejection Reason' // Add rejection reason
                   
                ));

                insert leads;
                
            } catch (DmlException e) {
                // Method 2: If direct creation fails, create without Distributor__c first
                System.debug('Direct creation failed, trying alternative approach: ' + e.getMessage());
                
                leads.clear();
                leads.add(new Lead(
                    LastName = 'OpenLead',
                    Company = 'Test Company',
                     //Purchased_Premier_Module__c = 'No',
                    Status = 'New',
                    State = 'Karnataka',
                    Country = 'India',
                    DCR_Non_DCR1__c = 'DCR',
                     Reason_for_Rejection__c = 'Test Rejection Reason' // Add rejection reason
                ));

                leads.add(new Lead(
                    LastName = 'RejectedLead',
                    Company = 'Test Company',
                     //Purchased_Premier_Module__c = 'No',
                    Status = 'Rejected',
                    State = 'Karnataka',
                    Country = 'India',
                    DCR_Non_DCR1__c = 'DCR',
                   Reason_for_Rejection__c = 'Test Rejection Reason' // Add rejection reason
                   
                ));

                leads.add(new Lead(
                    LastName = 'ConvertedLead',
                    Company = 'Test Company',
                    Status = 'New',
                    //Purchased_Premier_Module__c = 'No',
                    State = 'Karnataka',
                    Country = 'India',
                    DCR_Non_DCR1__c = 'DCR',
                      Reason_for_Rejection__c = 'Test Rejection Reason' // Add rejection reason
                ));

                leads.add(new Lead(
                    LastName = 'ConvertedRejectedLead',
                    Company = 'Test Company',
                    Status = 'Rejected',
                    //Purchased_Premier_Module__c = 'No',
                    State = 'Karnataka',
                    Country = 'India',
                    DCR_Non_DCR1__c = 'DCR',
                    Reason_for_Rejection__c = 'Test Rejection Reason' // Add rejection reason
                   
                ));

                insert leads;
                /*
                // Update with Distributor__c after creation
                for (Lead l : leads) {
                    l.Distributor__c = testUser.Id;
                }
                
                update leads;
*/
            }
        }
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

            
        }
    }

    @isTest
    static void testLeadMethodWithNoData() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'LeadTestUser' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            // Test with date range that has no data
            Date startDate = System.today().addDays(-20);
            Date endDate = System.today().addDays(-15);
            Map<String, Integer> counts = LeadCountApex.LeadMethod(startDate, endDate);
            Test.stopTest();

            System.assertNotEquals(null, counts, 'Counts should not be null');
            System.assertEquals(0, counts.get('total'), 'Expected 0 total leads');
            System.assertEquals(0, counts.get('open'), 'Expected 0 open leads');
            System.assertEquals(0, counts.get('rejected'), 'Expected 0 rejected leads');
            System.assertEquals(0, counts.get('converted'), 'Expected 0 converted leads');
            System.assertEquals(0, counts.get('closed'), 'Expected 0 closed leads');
        }
    }
}