@IsTest
private class PurchaseOrderControllerTest {

    // Helper method to create test user with a specific role
    private static User createTestUser(String roleName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Make DeveloperName unique by adding timestamp
        String uniqueDeveloperName = ('R' + roleName.replaceAll('[^a-zA-Z0-9]', '_').replaceAll('_+', '_').replaceAll('_$', '')) + '_' + DateTime.now().getTime();
        UserRole r = new UserRole(Name = roleName, DeveloperName = uniqueDeveloperName);
        insert r;

        
        User testUser = new User(
            Alias = 'testusr',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com',
            UserRoleId = r.Id
        );
        insert testUser;
        return testUser;
    }

    // Setup test data for all test methods
    @TestSetup
    static void setupTestData() {
        // Create test Accounts with country information
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Account 1', BillingCountry = 'India', ShippingCountry = 'India'),
            new Account(Name = 'Test Account 2', BillingCountry = 'United States', ShippingCountry = 'United States'),
            new Account(Name = 'Test Account 3', BillingCountry = 'India', ShippingCountry = 'India')
        };
        insert accounts;

        // Get Purchase Order RecordTypeId
        Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
            .get('Purchase_Order').getRecordTypeId();

        // Create test Orders for different scenarios
        List<Order> orders = new List<Order>{
            // Key Account Private - India (National Head, Key Accounts Private)
            new Order(
                RecordTypeId = purchaseOrderRecordTypeId,
                AccountId = accounts[0].Id,
                Type__c = 'Key Account Private',
                Status = 'Draft',
                EffectiveDate = System.today(),
                Approval_Status__c = null,
                BillingCountry = 'India',
                ShippingCountry = 'India'
            ),
            // Key Account Private - International (Key Accounts International Head Private)
            new Order(
                RecordTypeId = purchaseOrderRecordTypeId,
                AccountId = accounts[1].Id,
                Type__c = 'Key Account Private',
                Status = 'Draft',
                EffectiveDate = System.today(),
                Approval_Status__c = null,
                BillingCountry = 'United States',
                ShippingCountry = 'United States'
            ),
            // Channel Sales - East Region (East Region Head, Channel Sales)
            new Order(
                RecordTypeId = purchaseOrderRecordTypeId,
                AccountId = accounts[2].Id,
                Type__c = 'Channel Sales',
                Region__c = 'East',
                Status = 'Draft',
                EffectiveDate = System.today(),
                Approval_Status__c = null,
                BillingCountry = 'India',
                ShippingCountry = 'India'
            ),
                
              new Order(
                RecordTypeId = purchaseOrderRecordTypeId,
                AccountId = accounts[0].Id,
                Type__c = 'Channel Sales',
                Region__c = 'North',
                Status = 'Draft',
                EffectiveDate = System.today(),
                Approval_Status__c = null,
                BillingCountry = 'India',
                ShippingCountry = 'India'
            ),
                
                new Order(
                RecordTypeId = purchaseOrderRecordTypeId,
                AccountId = accounts[1].Id,
                Type__c = 'Channel Sales',
                Region__c = 'South',
                Status = 'Draft',
                EffectiveDate = System.today(),
                Approval_Status__c = null,
                BillingCountry = 'India',
                ShippingCountry = 'India'
            ),
                
                new Order(
                RecordTypeId = purchaseOrderRecordTypeId,
                AccountId = accounts[2].Id,
                Type__c = 'Channel Sales',
                Region__c = 'West',
                Status = 'Draft',
                EffectiveDate = System.today(),
                Approval_Status__c = null,
                BillingCountry = 'India',
                ShippingCountry = 'India'
            ),
            // Key Account Government - EPC (Chief Strategy Officer)
            new Order(
                RecordTypeId = purchaseOrderRecordTypeId,
                AccountId = accounts[0].Id,
                Type__c = 'Key Account Government',
                Product_Type__c = 'EPC',
                Status = 'Draft',
                EffectiveDate = System.today(),
                Approval_Status__c = null,
                BillingCountry = 'India',
                ShippingCountry = 'India'
            ),
            // Key Account Government - Water Pump (Government Projects - Solar Pumps 1)
            new Order(
                RecordTypeId = purchaseOrderRecordTypeId,
                AccountId = accounts[1].Id,
                Type__c = 'Key Account Government',
                Product_Type__c = 'Water Pump',
                Status = 'Draft',
                EffectiveDate = System.today(),
                Approval_Status__c = null,
                BillingCountry = 'India',
                ShippingCountry = 'India'
            )
        };
        insert orders;
    }

    // Test getPurchaseOrders() for National Head, Key Accounts Private role
    @IsTest
    static void testGetPurchaseOrders_NationalHeadPrivate() {
        User testUser = createTestUser('National Head, Key Accounts Private');
        
        System.runAs(testUser) {
            Test.startTest();
            Map<String, Object> result = PurchaseOrderController.getPurchaseOrders();
            Test.stopTest();

            List<Order> orders = (List<Order>) result.get('orders');
            System.assertEquals('National Head, Key Accounts Private', result.get('userRoleName'), 'Incorrect user role');
            System.assertNotEquals(0, orders.size(), 'Should return orders for National Head');
        }
    }

    // Test getPurchaseOrders() for Key Accounts International Head Private role
    @IsTest
    static void testGetPurchaseOrders_InternationalHeadPrivate() {
        User testUser = createTestUser('Key Accounts International Head Private');
        
        System.runAs(testUser) {
            Test.startTest();
            Map<String, Object> result = PurchaseOrderController.getPurchaseOrders();
            Test.stopTest();

            List<Order> orders = (List<Order>) result.get('orders');
            System.assertEquals('Key Accounts International Head Private', result.get('userRoleName'));
            System.assertNotEquals(0, orders.size(), 'Should return international orders');
        }
    }

    // Test getPurchaseOrders() for East Region Head, Channel Sales role
    @IsTest
    static void testGetPurchaseOrders_EastRegionHead() {
        User testUser = createTestUser('East Region Head, Channel Sales');
        
        System.runAs(testUser) {
            Test.startTest();
            Map<String, Object> result = PurchaseOrderController.getPurchaseOrders();
            Test.stopTest();

            List<Order> orders = (List<Order>) result.get('orders');
            System.assertEquals('East Region Head, Channel Sales', result.get('userRoleName'));
            System.assertNotEquals(0, orders.size(), 'Should return East region orders');
        }
    }
    
    // Test getPurchaseOrders() for North Region Head, Channel Sales role
    @IsTest
    static void testGetPurchaseOrders_NorthRegionHead() {
        User testUser = createTestUser('North Region Head, Channel Sales');
        
        System.runAs(testUser) {
            Test.startTest();
            Map<String, Object> result = PurchaseOrderController.getPurchaseOrders();
            Test.stopTest();

            List<Order> orders = (List<Order>) result.get('orders');
            System.assertEquals('North Region Head, Channel Sales', result.get('userRoleName'));
            System.assertNotEquals(0, orders.size(), 'Should return North region orders');
        }
    }
    
    // Test getPurchaseOrders() for South Region Head, Channel Sales role
    @IsTest
    static void testGetPurchaseOrders_SouthRegionHead() {
        User testUser = createTestUser('South Region Head, Channel Sales');
        
        System.runAs(testUser) {
            Test.startTest();
            Map<String, Object> result = PurchaseOrderController.getPurchaseOrders();
            Test.stopTest();

            List<Order> orders = (List<Order>) result.get('orders');
            System.assertEquals('South Region Head, Channel Sales', result.get('userRoleName'));
            System.assertNotEquals(0, orders.size(), 'Should return South region orders');
        }
    }
    
    // Test getPurchaseOrders() for West Region Head, Channel Sales role
    @IsTest
    static void testGetPurchaseOrders_WestRegionHead() {
        User testUser = createTestUser('West Region Head, Channel Sales');
        
        System.runAs(testUser) {
            Test.startTest();
            Map<String, Object> result = PurchaseOrderController.getPurchaseOrders();
            Test.stopTest();

            List<Order> orders = (List<Order>) result.get('orders');
            System.assertEquals('West Region Head, Channel Sales', result.get('userRoleName'));
            System.assertNotEquals(0, orders.size(), 'Should return West region orders');
        }
    }

    // Test getPurchaseOrders() for Chief Strategy Officer role
    @IsTest
    static void testGetPurchaseOrders_ChiefStrategyOfficer() {
        User testUser = createTestUser('Chief Strategy Officer');
        
        System.runAs(testUser) {
            Test.startTest();
            Map<String, Object> result = PurchaseOrderController.getPurchaseOrders();
            Test.stopTest();

            List<Order> orders = (List<Order>) result.get('orders');
            System.assertEquals('Chief Strategy Officer', result.get('userRoleName'));
            System.assertNotEquals(0, orders.size(), 'Should return EPC orders');
        }
    }

    // Test getPurchaseOrders() for Government Projects - Solar Pumps 1 role
    @IsTest
    static void testGetPurchaseOrders_SolarPumps() {
        User testUser = createTestUser('Government Projects - Solar Pumps 1');
        
        System.runAs(testUser) {
            Test.startTest();
            Map<String, Object> result = PurchaseOrderController.getPurchaseOrders();
            Test.stopTest();

            List<Order> orders = (List<Order>) result.get('orders');
            System.assertEquals('Government Projects - Solar Pumps 1', result.get('userRoleName'));
            System.assertNotEquals(0, orders.size(), 'Should return Water Pump orders');
        }
    }

    // Test getPurchaseOrders() for unknown role
    @IsTest
    static void testGetPurchaseOrders_UnknownRole() {
        User testUser = createTestUser('Unknown Role');
        
        System.runAs(testUser) {
            Test.startTest();
            Map<String, Object> result = PurchaseOrderController.getPurchaseOrders();
            Test.stopTest();

            List<Order> orders = (List<Order>) result.get('orders');
            System.assertEquals(0, orders.size(), 'Should return empty list for unknown role');
        }
    }



    // Test updateApprovalStatus() - Reject
    @IsTest
    static void testUpdateApprovalStatus_Reject() {
        Order testOrder = [SELECT Id FROM Order WHERE Type__c = 'Key Account Private' LIMIT 1];
        String rejectionReason = 'Test rejection reason';
        
        Test.startTest();
        PurchaseOrderController.updateApprovalStatus(testOrder.Id, 'Rejected', rejectionReason);
        Test.stopTest();
        
        Order updatedOrder = [SELECT Approval_Status__c, Reason_For_Rejection__c FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals('Rejected', updatedOrder.Approval_Status__c, 'Status should be Rejected');
        System.assertEquals(rejectionReason, updatedOrder.Reason_For_Rejection__c, 'Rejection reason should be set');
    }

    // Test updateApprovalStatus() with invalid Order Id (negative test)
    @IsTest
    static void testUpdateApprovalStatus_InvalidOrder() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            PurchaseOrderController.updateApprovalStatus('001000000000000', 'Approved', null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw exception for invalid Order Id');
    }
}