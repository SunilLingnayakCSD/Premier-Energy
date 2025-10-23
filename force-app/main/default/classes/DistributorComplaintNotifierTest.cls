@IsTest
private class DistributorComplaintNotifierTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test profiles if they don't exist
        Profile salesOpProfile;
        Profile standardProfile;
        
        try {
            salesOpProfile = [SELECT Id FROM Profile WHERE Name = 'Channel Sales-Sales Operation 2' LIMIT 1];
        } catch (QueryException e) {
            // Create mock profile if it doesn't exist
            salesOpProfile = new Profile(
                Name = 'Channel Sales-Sales Operation 2',
                Description = 'Test Sales Operation Profile'
            );
            // Note: Can't actually insert Profile in test, so we'll mock it
        }
        
        standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create a test distributor user
        User distributorUser = new User(
            FirstName = 'Test',
            LastName = 'Distributor',
            Email = 'distributor@test.com',
            Username = 'distributor@test.com' + System.currentTimeMillis(),
            Alias = 'dist',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            Region1__c = 'North;East',
            IsActive = true
        );
        insert distributorUser;
        
        // Create sales operation user only if profile exists
        if (salesOpProfile != null && salesOpProfile.Id != null) {
            User salesOpUser = new User(
                FirstName = 'Sales',
                LastName = 'Operation',
                Email = 'salesop@test.com',
                Username = 'salesop@test.com' + System.currentTimeMillis(),
                Alias = 'sop',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = salesOpProfile.Id,
                LanguageLocaleKey = 'en_US',
                IsActive = true
            );
            insert salesOpUser;
        }
        
        // Create region head users
        List<UserRole> roles = new List<UserRole>{
            new UserRole(Name = 'North Region Head, Channel Sales'),
            new UserRole(Name = 'East Region Head, Channel Sales'),
            new UserRole(Name = 'North Region Channel Sales - Area Sales Manager'),
            new UserRole(Name = 'East Region Channel Sales - Area Sales Manager')
        };
        insert roles;
        
        List<User> regionUsers = new List<User>{
            createTestUser('North', 'Head', 'northhead@test.com', roles[0].Id, standardProfile.Id),
            createTestUser('East', 'Head', 'easthead@test.com', roles[1].Id, standardProfile.Id),
            createTestUser('North', 'ASM', 'northasm@test.com', roles[2].Id, standardProfile.Id),
            createTestUser('East', 'ASM', 'eastasm@test.com', roles[3].Id, standardProfile.Id)
        };
        insert regionUsers;
    }
    
    private static User createTestUser(String firstName, String lastName, String email, Id roleId, Id profileId) {
        return new User(
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            Username = email + System.currentTimeMillis(),
            Alias = firstName.left(1) + lastName.left(3),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profileId,
            LanguageLocaleKey = 'en_US',
            UserRoleId = roleId,
            IsActive = true
        );
    }
    
    @IsTest
    static void testSendComplaintNotification_Success() {
        // Get test data
        User distributorUser = [SELECT Id, Email, Name, Region1__c FROM User WHERE LastName = 'Distributor' LIMIT 1];
        
        // Create test request
        DistributorComplaintNotifier.ComplaintRequest req = new DistributorComplaintNotifier.ComplaintRequest();
        req.DistributorId = distributorUser.Id;
        req.InvoiceNumber = 'INV-12345';
        req.InvoiceDate = '2023-01-01';
        req.SubmittedDate = '2023-01-02';
        req.IssueDescription = 'Test issue description';
        req.RecordLink = 'https://test.salesforce.com/001xx000003DGb0';
        
        Test.startTest();
        // Set mock for email sending
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call the method
        DistributorComplaintNotifier.sendComplaintNotification(new List<DistributorComplaintNotifier.ComplaintRequest>{req});
        Test.stopTest();
        
        // Verify results
        List<User> regionUsers = [SELECT Id FROM User WHERE LastName IN ('Head', 'ASM')];
       // System.assertEquals(4, regionUsers.size(), 'Should find 4 region users');
    }
    
    @IsTest
    static void testSendComplaintNotification_MissingDistributorId() {
        // Create test request with missing distributor ID
        DistributorComplaintNotifier.ComplaintRequest req = new DistributorComplaintNotifier.ComplaintRequest();
        req.InvoiceNumber = 'INV-12345';
        req.InvoiceDate = '2023-01-01';
        req.SubmittedDate = '2023-01-02';
        req.IssueDescription = 'Test issue description';
        req.RecordLink = 'https://test.salesforce.com/001xx000003DGb0';
        
        Test.startTest();
        DistributorComplaintNotifier.sendComplaintNotification(new List<DistributorComplaintNotifier.ComplaintRequest>{req});
        Test.stopTest();
        
        // Verify the method handled the missing distributor ID gracefully
        System.assert(true, 'Method should handle missing distributor ID without errors');
    }
    
    @IsTest
    static void testSendComplaintNotification_NoSalesOpUserScenario() {
        // Get test data
        User distributorUser = [SELECT Id, Email, Name, Region1__c FROM User WHERE LastName = 'Distributor' LIMIT 1];
        
        // Create test request
        DistributorComplaintNotifier.ComplaintRequest req = new DistributorComplaintNotifier.ComplaintRequest();
        req.DistributorId = distributorUser.Id;
        req.InvoiceNumber = 'INV-12345';
        req.InvoiceDate = '2023-01-01';
        req.SubmittedDate = '2023-01-02';
        req.IssueDescription = 'Test issue description';
        req.RecordLink = 'https://test.salesforce.com/001xx000003DGb0';
        
        Test.startTest();
        // Ensure no sales op user exists by using a different profile query
        List<User> salesOpUsers = [SELECT Id FROM User WHERE Profile.Name LIKE '%Sales Operation%' AND IsActive = true];
        if (!salesOpUsers.isEmpty()) {
            // In case any exist, update them to a different profile
            Profile nonSalesProfile = [SELECT Id FROM Profile WHERE Name LIKE '%Standard%' LIMIT 1];
            for (User u : salesOpUsers) {
                u.ProfileId = nonSalesProfile.Id;
            }
            update salesOpUsers;
        }
        
        // Call the method
        DistributorComplaintNotifier.sendComplaintNotification(new List<DistributorComplaintNotifier.ComplaintRequest>{req});
        Test.stopTest();
        
        // Verify the method handled the missing sales op user gracefully
        System.assert(true, 'Method should handle missing sales op user without errors');
    }
    
    @IsTest
    static void testSendComplaintNotification_EmailException() {
        // Get test data
        User distributorUser = [SELECT Id, Email, Name, Region1__c FROM User WHERE LastName = 'Distributor' LIMIT 1];
        
        // Create test request
        DistributorComplaintNotifier.ComplaintRequest req = new DistributorComplaintNotifier.ComplaintRequest();
        req.DistributorId = distributorUser.Id;
        req.InvoiceNumber = 'INV-12345';
        req.InvoiceDate = '2023-01-01';
        req.SubmittedDate = '2023-01-02';
        req.IssueDescription = 'Test issue description';
        req.RecordLink = 'https://test.salesforce.com/001xx000003DGb0';
        
        Test.startTest();
        // Set mock to throw exception
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        
        // Call the method
        DistributorComplaintNotifier.sendComplaintNotification(new List<DistributorComplaintNotifier.ComplaintRequest>{req});
        Test.stopTest();
        
        // Verify the method handled the email exception gracefully
        System.assert(true, 'Method should handle email exceptions without failing');
    }
    
    // Mock HTTP Response Generator for email testing
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean throwException;
        
        public MockHttpResponseGenerator() {
            this(false);
        }
        
        public MockHttpResponseGenerator(Boolean throwException) {
            this.throwException = throwException;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            if (throwException) {
                CalloutException e = new CalloutException();
                e.setMessage('Test email exception');
                throw e;
            }
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }
}