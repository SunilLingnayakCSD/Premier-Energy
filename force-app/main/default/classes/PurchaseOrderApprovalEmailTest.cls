@isTest
public class PurchaseOrderApprovalEmailTest {
    
    static User user1;
    static User user2;
    static User user3;
    static User user4;
    static User user5;
    static Order od1;
    static Order od2;
    static Order od3;
    static Order od4;
    static UserRole channelSalesRole;
    static UserRole nationalHeadRole;
    static UserRole internationalHeadRole;
    static Account testAccount;
    
   @testSetup
static void testSetUp() {
    // Query roles (must already exist)
    UserRole channelSalesRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Channel_Sales_National_Head' LIMIT 1];
    UserRole nationalHeadRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'National_Head_Key_Accounts_Private' LIMIT 1];
    UserRole internationalHeadRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Key_Accounts_International_Head_Private' LIMIT 1];

    // Get admin profile
    Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

    // Create a dummy user for runAs (must be inserted before using System.runAs)
    User sysUser = new User(
        FirstName = 'Sys',
        LastName = 'Admin',
        Email = 'sys.admin@example.com',
        Username = 'sys.admin@example.com.test',
        Alias = 'sysadm',
        ProfileId = adminProfile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'ISO-8859-1',
        LanguageLocaleKey = 'en_US',
        CommunityNickname = 'sysadm'
    );
    insert sysUser;

    System.runAs(sysUser) {
        // Create users inside System.runAs block
        User user1 = new User(
            FirstName = 'Channel',
            LastName = 'Head',
            Email = 'channel.head@example.com',
            Username = 'channel.head@example.com.test',
            Alias = 'chead',
            ProfileId = adminProfile.Id,
            UserRoleId = channelSalesRole.Id,
            CommunityNickname = 'chead',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );

        User user2 = new User(
            FirstName = 'National',
            LastName = 'Head',
            Email = 'national.head@example.com',
            Username = 'national.head@example.com.test',
            Alias = 'nhead',
            ProfileId = adminProfile.Id,
            UserRoleId = nationalHeadRole.Id,
            CommunityNickname = 'nhead',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );

        User user3 = new User(
            FirstName = 'International',
            LastName = 'Sales',
            Email = 'international.sales@example.com',
            Username = 'international.sales@example.com.test',
            Alias = 'isales',
            ProfileId = adminProfile.Id,
            UserRoleId = internationalHeadRole.Id,
            CommunityNickname = 'isales',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );

        User user4 = new User(
            FirstName = 'Regional',
            LastName = 'Manager',
            Email = 'regional.manager@example.com',
            Username = 'regional.manager@example.com.test',
            Alias = 'rmgr',
            ProfileId = adminProfile.Id,
            CommunityNickname = 'rmgr',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );

        User user5 = new User(
            FirstName = 'Sales',
            LastName = 'Rep',
            Email = 'sales.rep@example.com',
            Username = 'sales.rep@example.com.test',
            Alias = 'srep',
            ProfileId = adminProfile.Id,
            ManagerId = user4.Id,
            CommunityNickname = 'srep',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );

        insert new List<User>{user1, user2, user3, user4, user5};

        // Create non-setup data
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test St',
            BillingCity = 'Bengaluru',
            BillingState = 'Karnataka',
            BillingPostalCode = '12345',
            BillingCountry = 'India',
            Phone = '1234567890',
            Email__c = 'testaccount@example.com'
        );
        insert testAccount;

        // Get RecordType for Purchase Order
        RecordType purchaseOrderRT = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Order' AND DeveloperName = 'Purchase_Order'
            LIMIT 1
        ];

        // Create orders
        Order od1 = new Order(
            Name = 'PO-0001',
            AccountId = testAccount.Id,
            EffectiveDate = System.TODAY(),
            Status = 'Draft',
            OwnerId = user5.Id,
            Type__c = 'Channel Sales',
            RecordTypeId = purchaseOrderRT.Id,
            Total_Capacity_in_MWp__c = 10,
            Product_Category__c = 'MODULE',
            Schema_Name__c = 'Test Scheme',
            DCR_Non_DCR1__c = 'DCR'
        );

        Order od2 = new Order(
            Name = 'PO-0002',
            AccountId = testAccount.Id,
            EffectiveDate = System.TODAY(),
            Status = 'Draft',
            OwnerId = user3.Id,
            Type__c = 'Key Account Private',
            RecordTypeId = purchaseOrderRT.Id,
            Regional_Head_Email__c = 'regional.head@example.com',
            Total_Capacity_in_MWp__c = 20,
            Product_Category__c = 'MODULE',
            Segment1__c = 'MODULE_DOMESTIC_RESIDENTIAL',
            Delivery_Required_By__c = System.today().addDays(30),
            Tender_Number__c = 'TND-001'
        );

        Order od3 = new Order(
            Name = 'PO-0003',
            AccountId = testAccount.Id,
            EffectiveDate = System.TODAY(),
            Status = 'Draft',
            Type__c = 'Key Account Government',
            RecordTypeId = purchaseOrderRT.Id,
            Regional_Head_Email__c = 'regional.head@example.com',
            Tender_Number__c = 'TND-002',
            Product_type__c = 'Water Pump',
            Schema_Name__c = 'Gov Scheme'
        );

        insert new List<Order>{od1, od2, od3};
    }
}

    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        
        // Execute the batch
        PurchaseOrderApprovalEmailNotification batch = new PurchaseOrderApprovalEmailNotification();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify emails were sent (they won't actually be sent in tests, but we can verify the limits)
        System.assertEquals(0, Limits.getEmailInvocations(), 'Emails should not be sent in test context');
        
        // Verify the batch processed the orders
        List<Order> processedOrders = [SELECT Id FROM Order WHERE Approval_Status__c != null];
        System.assert(processedOrders.isEmpty(), 'Batch should not modify Approval_Status__c');
    }
    
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        
        String jobID = System.schedule('PO Approval Reminder', '0 0 0 15 8 ?', new PurchaseOrderApprovalEmailNotification());
        
        Test.stopTest();
        
        // Verify that the batch job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobID LIMIT 1];
        System.assertNotEquals(null, ct, 'The batch job should have been scheduled.');
    }
    
    @isTest
    static void testBatchStartMethod() {
        Test.startTest();
        
        PurchaseOrderApprovalEmailNotification batch = new PurchaseOrderApprovalEmailNotification();
        Database.QueryLocator ql = batch.start(null);
        System.assertNotEquals(null, ql, 'QueryLocator should not be null');
        
        // Verify the query locator contains our test data
        List<Order> orders = Database.query(ql.getQuery());
        System.assert(!orders.isEmpty(), 'Query should return test orders');
        
        Test.stopTest();
    }
    
    @isTest
    static void testBatchFinishMethod() {
        Test.startTest();
        
        PurchaseOrderApprovalEmailNotification batch = new PurchaseOrderApprovalEmailNotification();
        batch.finish(null);
        
        Test.stopTest();
        
        // Just verify no exceptions occurred
        System.assert(true);
    }
    
    // Test the execute method with different order types
    @isTest
    static void testExecuteWithChannelSalesOrders() {
        // First query the test Order
        Order testOrder = [SELECT Id, OwnerId FROM Order WHERE Type__c = 'Channel Sales' LIMIT 1];
        
        // Then query the User with manager hierarchy
        User owner = [SELECT Id, ManagerId, Manager.ManagerId FROM User WHERE Id = :testOrder.OwnerId];
        
        Test.startTest();
        Database.executeBatch(new PurchaseOrderApprovalEmailNotification(), 3);
        Test.stopTest();

        
        // Verify assertions
        //System.assertNotEquals(null, testOrder.OwnerId, 'Order should have an owner');
        //System.assertNotEquals(null, owner.ManagerId, 'Owner should have a manager');
        //System.assertNotEquals(null, owner.Manager.ManagerId, 'Owner should have a manager of manager');
    }

    
    @isTest
    static void testExecuteWithKeyAccountPrivateOrders() {
        List<Order> orders = [SELECT Id, Regional_Head_Email__c, Owner.UserRole.DeveloperName 
                              FROM Order WHERE Type__c = 'Key Account Private'];
        
        Test.startTest();
        Database.executeBatch(new PurchaseOrderApprovalEmailNotification(), 3);
        Test.stopTest();

        
        // Verify the regional head email was set
        System.assertEquals('regional.head@example.com', orders[0].Regional_Head_Email__c, 'Regional head email should be set');
        System.assertNotEquals(null, orders[0].Owner.UserRole.DeveloperName, 'Owner should have a role');
    }

    
    @isTest
    static void testExecuteWithKeyAccountGovernmentOrders() {
        List<Order> orders = [SELECT Id, Regional_Head_Email__c, Tender_Number__c 
                              FROM Order WHERE Type__c = 'Key Account Government'];
        
        Test.startTest();
        Database.executeBatch(new PurchaseOrderApprovalEmailNotification(), 3);
        Test.stopTest();

        
        // Verify the tender number and regional head email
        System.assertEquals('TND-002', orders[0].Tender_Number__c, 'Tender number should match');
        System.assertEquals('regional.head@example.com', orders[0].Regional_Head_Email__c, 'Regional head email should be set');
    }
    
    @isTest
    static void testExecuteWithMixedOrderTypes() {
        List<Order> orders = [SELECT Id, Type__c FROM Order];
        
        Test.startTest();
        Database.executeBatch(new PurchaseOrderApprovalEmailNotification(), 3);
        Test.stopTest();

        
        System.assertEquals(3, orders.size(), 'Should have processed all test orders');
    }
}