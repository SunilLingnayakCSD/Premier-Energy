@isTest
private class OrderCountApexTest {

    private static String generateUniqueUsername() {
        return 'testuser.' + System.currentTimeMillis() + '.' + Crypto.getRandomInteger() + '@example.com';
    }

    private static Id getCommunityProfileId() {
        for (Profile p : [SELECT Id FROM Profile WHERE UserType IN ('PowerCustomerSuccess', 'PowerPartner') LIMIT 1]) {
            return p.Id;
        }
        return [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
    }

    @testSetup
    static void setupTestData() {
        // Get RecordType for Account
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

        // Get valid profile ID
        Id profileId = getCommunityProfileId();

        // Create Community User
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

        // Get RecordTypeId for 'Purchase Order'
        RecordType orderRT = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Order' AND Name = 'Purchase Order' LIMIT 1
        ];

        // Create Orders covering different cases
        List<Order> orders = new List<Order>();

        // 1. Cancelled (Rejected)
        orders.add(new Order(
            Name = 'Order Cancelled',
            AccountId = acc.Id,
            RecordTypeId = orderRT.Id,
            Type__c = 'Channel Sales',
            Approval_Status__c = 'Rejected',
            EffectiveDate = System.today(),
            Status = 'Draft'
        ));

        // 2. Closed (Invoice POD Uploaded)
        orders.add(new Order(
            Name = 'Order Closed',
            AccountId = acc.Id,
            RecordTypeId = orderRT.Id,
            Type__c = 'Channel Sales',
            Approval_Status__c = 'Approved',
            EffectiveDate = System.today(),
            Status = 'Draft'
        ));

        // 3. Intransit (Invoice POD Not Uploaded)
        orders.add(new Order(
            Name = 'Order Intransit',
            AccountId = acc.Id,
            RecordTypeId = orderRT.Id,
            Type__c = 'Channel Sales',
            Approval_Status__c = 'Approved',
            EffectiveDate = System.today(),
            Status = 'Draft'
        ));

        // 4. Inprogress (No Invoice)
        orders.add(new Order(
            Name = 'Order Inprogress',
            AccountId = acc.Id,
            RecordTypeId = orderRT.Id,
            Type__c = 'Channel Sales',
            Approval_Status__c = 'Approved',
            EffectiveDate = System.today(),
            Status = 'Draft'
        ));

        insert orders;

        // Create Invoices for relevant orders
        List<Invoice__c> invoices = new List<Invoice__c>();

        // Closed: POD_Status__c = 'Uploaded'
        invoices.add(new Invoice__c(
            Name = 'Invoice Closed',
            Order__c = orders[1].Id,
            Account__c = acc.Id,
            POD_Status__c = 'Uploaded',
            POD_Date__c = System.today(),
            Status__c = 'pending',
            FTR_Upload_Date__c = System.today()
        ));

        // Intransit: POD_Status__c = 'Not Uploaded'
        invoices.add(new Invoice__c(
            Name = 'Invoice Intransit',
            Order__c = orders[2].Id,
            Account__c = acc.Id,
            POD_Status__c = 'Not Uploaded',
            POD_Date__c = System.today(),
            Status__c = 'pending',
            FTR_Upload_Date__c = System.today()
        ));

        insert invoices;
    }

    @isTest
    static void testOrderMethodCounts() {
        // Query test user
        User testUser = [SELECT Id FROM User WHERE Contact.Account.Name = 'Test Distributor Account' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            Date startDate = System.today().addDays(-5);
            Date endDate = System.today();
            Map<String, Integer> counts = orderCountApex.orderMethod(startDate, endDate);
            Test.stopTest();

            // Validate result
            System.assertNotEquals(null, counts, 'Counts should not be null');
            System.assertEquals(4, counts.get('total'), 'Expected 4 total orders');

            System.assertEquals(1, counts.get('cancelled'), 'Expected 1 cancelled order');
            System.assertEquals(1, counts.get('closed'), 'Expected 1 closed order');
            System.assertEquals(1, counts.get('intransit'), 'Expected 1 intransit order');
            System.assertEquals(1, counts.get('inprogress'), 'Expected 1 inprogress order');
        }
    }
}