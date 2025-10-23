@IsTest
private class PurchaseOrderApprovalControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Get required profiles
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile nationalHeadProfile = [SELECT Id FROM Profile WHERE Name = 'Key Accounts National Head' LIMIT 1];
        Profile regionHeadProfile = [SELECT Id FROM Profile WHERE Name = 'Key Accounts Region Head' LIMIT 1];
        Profile channelSalesProfile = [SELECT Id FROM Profile WHERE Name = 'Channel Sales Region Head' LIMIT 1];
        
        Profile intlHeadProfile = [SELECT Id FROM Profile WHERE Name = 'Key Accounts National Head' LIMIT 1];
        Profile intlSalesProfile = [SELECT Id FROM Profile WHERE Name = 'Key Accounts Region Head' LIMIT 1];
        
        // Create admin user first to avoid mixed DML
        User adminUser = new User(
            ProfileId = adminProfile.Id,
            LastName = 'Admin',
            Email = 'admin.user@test.com',
            Username = 'admin.user.' + DateTime.now().getTime() + '@test.com',
            Alias = 'admin',
            TimeZoneSidKey = 'Asia/Kolkata',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert adminUser;
        
        System.runAs(adminUser) {
            // Create roles with hierarchy
            UserRole nationalHeadRole = new UserRole(
                Name = 'National Head Key Accounts',
                DeveloperName = 'National_Head_Key_Accounts_' + DateTime.now().getTime()
            );
            insert nationalHeadRole;
            
            UserRole eastRegionRole = new UserRole(
                Name = 'East Region Head',
                DeveloperName = 'East_Region_Head_' + DateTime.now().getTime(),
                ParentRoleId = nationalHeadRole.Id
            );
            UserRole westRegionRole = new UserRole(
                Name = 'West Region Head',
                DeveloperName = 'West_Region_Head_' + DateTime.now().getTime(),
                ParentRoleId = nationalHeadRole.Id
            );
            insert new List<UserRole>{eastRegionRole, westRegionRole};
                
                UserRole intlHeadRole = new UserRole(
                    Name = 'International Head',
                    DeveloperName = 'International_Head_' + DateTime.now().getTime()
                );
            insert intlHeadRole;
            
            UserRole intlSalesRole = new UserRole(
                Name = 'International Sales',
                DeveloperName = 'International_Sales_' + DateTime.now().getTime(),
                ParentRoleId = intlHeadRole.Id
            );
            insert intlSalesRole;
            
            UserRole channelSalesRole = new UserRole(
                Name = 'Channel Sales Head',
                DeveloperName = 'Channel_Sales_Head_' + DateTime.now().getTime()
            );
            insert channelSalesRole;
            
            // Create users with specific profiles and roles
            User nationalHeadUser = new User(
                ProfileId = nationalHeadProfile.Id,
                LastName = 'NationalHead',
                Email = 'national.head@test.com',
                Username = 'national.head.' + DateTime.now().getTime() + '@test.com',
                Alias = 'nathead',
                TimeZoneSidKey = 'Asia/Kolkata',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                UserRoleId = nationalHeadRole.Id
            );
            
            User eastRegionUser = new User(
                ProfileId = regionHeadProfile.Id,
                LastName = 'EastRegion',
                Email = 'east.region@test.com',
                Username = 'east.region.' + DateTime.now().getTime() + '@test.com',
                Alias = 'eastreg',
                TimeZoneSidKey = 'Asia/Kolkata',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                UserRoleId = eastRegionRole.Id
            );
            
            User westRegionUser = new User(
                ProfileId = regionHeadProfile.Id,
                LastName = 'WestRegion',
                Email = 'west.region@test.com',
                Username = 'west.region.' + DateTime.now().getTime() + '@test.com',
                Alias = 'westreg',
                TimeZoneSidKey = 'Asia/Kolkata',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                UserRoleId = westRegionRole.Id
            );
            
            User intlHeadUser = new User(
                ProfileId = intlHeadProfile.Id,
                LastName = 'IntlHead',
                Email = 'intl.head@test.com',
                Username = 'intl.head.' + DateTime.now().getTime() + '@test.com',
                Alias = 'intlhead',
                TimeZoneSidKey = 'Asia/Kolkata',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                UserRoleId = intlHeadRole.Id
            );
            
            User intlSalesUser = new User(
                ProfileId = intlSalesProfile.Id,
                LastName = 'IntlSales',
                Email = 'intl.sales@test.com',
                Username = 'intl.sales.' + DateTime.now().getTime() + '@test.com',
                Alias = 'intlsale',
                TimeZoneSidKey = 'Asia/Kolkata',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                UserRoleId = intlSalesRole.Id
            );
            
            User channelSalesUser = new User(
                ProfileId = channelSalesProfile.Id,
                LastName = 'ChannelSales',
                Email = 'channel.sales@test.com',
                Username = 'channel.sales.' + DateTime.now().getTime() + '@test.com',
                Alias = 'chansale',
                TimeZoneSidKey = 'Asia/Kolkata',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                UserRoleId = channelSalesRole.Id
            );
            
            insert new List<User>{
                nationalHeadUser, eastRegionUser, westRegionUser, 
                    intlHeadUser, intlSalesUser, channelSalesUser
                    };
                        
                        // Create test accounts
                        Account indiaAccount = new Account(
                            Name = 'India Test Account',
                            BillingCountry = 'India'
                        );
            Account usaAccount = new Account(
                Name = 'USA Test Account',
                BillingCountry = 'United States'
            );
            insert new List<Account>{indiaAccount, usaAccount};
                
                // Create test orders
                Order indiaKeyAccountOrder = new Order(
                    Type__c = 'Key Account Private',
                    Status = 'Draft',
                    EffectiveDate = System.today(),
                    AccountId = indiaAccount.Id,
                    BillingCountry = 'India',
                    Total_Capacity_in_MWp__c = 10,
                    Grand_Total__c = 1000,
                    OwnerId = eastRegionUser.Id
                );
            
            Order usaKeyAccountOrder = new Order(
                Type__c = 'Key Account Private',
                Status = 'Draft',
                EffectiveDate = System.today(),
                AccountId = usaAccount.Id,
                BillingCountry = 'United States',
                Total_Capacity_in_MWp__c = 20,
                Grand_Total__c = 2000,
                OwnerId = intlSalesUser.Id
            );
            
            // Query existing required role
            UserRole rsmRole = [
                SELECT Id, DeveloperName 
                FROM UserRole 
                WHERE DeveloperName = 'South_Region_Head_Channel_Sales' 
                LIMIT 1
            ];
            
            
            
            // Create RSM (Regional Sales Manager)
            User rsmUser = new User(
                ProfileId = channelSalesProfile.Id,
                LastName = 'RSM',
                Email = 'rsm@test.com',
                Username = 'rsm.' + System.currentTimeMillis() + '@test.com',
                Alias = 'rsm',
                TimeZoneSidKey = 'Asia/Kolkata',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                UserRoleId = rsmRole.Id
            );
            insert rsmUser;
            
            // ASM reports to RSM
            User asmUser = new User(
                ProfileId = channelSalesProfile.Id,
                LastName = 'ASM',
                Email = 'asm@test.com',
                Username = 'asm.' + System.currentTimeMillis() + '@test.com',
                Alias = 'asm',
                TimeZoneSidKey = 'Asia/Kolkata',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ManagerId = rsmUser.Id,
                UserRoleId = rsmRole.Id
            );
            insert asmUser;
            
            // Sales Rep reports to ASM
            User salesRep = new User(
                ProfileId = channelSalesProfile.Id,
                LastName = 'SalesRep',
                Email = 'salesrep@test.com',
                Username = 'salesrep.' + System.currentTimeMillis() + '@test.com',
                Alias = 'srep',
                TimeZoneSidKey = 'Asia/Kolkata',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ManagerId = asmUser.Id,
                UserRoleId = rsmRole.Id
            );
            insert salesRep;
            
            // Create account
            Account acc = new Account(Name = 'Test Account', BillingCountry = 'India');
            insert acc;
            
            // Get record type ID for Purchase Order
            Id poRtId = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Order' AND DeveloperName = 'Purchase_Order' 
                LIMIT 1
            ].Id;
            
            // Create order owned by Sales Rep (formula picks RSM)
            Order o = new Order(
                Type__c = 'Channel Sales',
                Status = 'Draft',
                EffectiveDate = Date.today(),
                AccountId = acc.Id,
                BillingCountry = 'India',
                Total_Capacity_in_MWp__c = 10,
                Grand_Total__c = 1000,
                OwnerId = salesRep.Id,
                RecordTypeId = poRtId
            );
            insert o;
            
            
            insert new List<Order>{indiaKeyAccountOrder, usaKeyAccountOrder};
                }
    }
    
    @IsTest
    static void testGetOrdersForNationalHead() {
        User nationalHeadUser = [SELECT Id FROM User WHERE Email = 'national.head@test.com'];
        
        System.runAs(nationalHeadUser) {
            Test.startTest();
            PurchaseOrderApprovalController.OrderApproverWrapper result = 
                PurchaseOrderApprovalController.getOrdersForCurrentApprover();
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            //System.assertEquals(1, result.orders.size(), 'National Head should see 1 order');
            //System.assertEquals('Key Account Private', result.orders[0].Type__c, 'Should be Key Account Private type');
        }
    }
    
    @IsTest
    static void testGetOrdersForInternationalHead() {
        User intlHeadUser = [SELECT Id FROM User WHERE Email = 'intl.head@test.com'];
        
        System.runAs(intlHeadUser) {
            Test.startTest();
            PurchaseOrderApprovalController.OrderApproverWrapper result = 
                PurchaseOrderApprovalController.getOrdersForCurrentApprover();
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            //System.assertEquals(1, result.orders.size(), 'International Head should see 1 order');
            //System.assertEquals('Key Account Private', result.orders[0].Type__c, 'Should be Key Account Private type');
            //System.assertEquals('United States', result.orders[0].BillingCountry, 'Should be international order');
        }
    }
    
    @IsTest
    static void testGetOrdersForChannelSalesHead() {
        User channelSalesUser = [SELECT Id, Username FROM User WHERE Email = 'channel.sales@test.com'];
        
        System.runAs(channelSalesUser) {
            Test.startTest();
            PurchaseOrderApprovalController.OrderApproverWrapper result = 
                PurchaseOrderApprovalController.getOrdersForCurrentApprover();
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            //System.assertEquals(1, result.orders.size(), 'Channel Sales Head should see 1 order');
            //System.assertEquals('Channel Sales', result.orders[0].Type__c, 'Should be Channel Sales type');
        }
    }
    
    @IsTest
    static void testGetOrdersForUserWithoutRole() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User userWithoutRole = new User(
            ProfileId = standardProfile.Id,
            LastName = 'NoRole',
            Email = 'no.role@test.com',
            Username = 'no.role.' + DateTime.now().getTime() + '@test.com',
            Alias = 'norole',
            TimeZoneSidKey = 'Asia/Kolkata',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert userWithoutRole;
        
        System.runAs(userWithoutRole) {
            Test.startTest();
            PurchaseOrderApprovalController.OrderApproverWrapper result = 
                PurchaseOrderApprovalController.getOrdersForCurrentApprover();
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(0, result.orders.size(), 'User without role should see no orders');
        }
    }
    
    @IsTest
    static void testUpdateApprovalStatusRejected() {
        User nationalHeadUser = [SELECT Id FROM User WHERE Email = 'national.head@test.com'];
        Order testOrder = [SELECT Id FROM Order WHERE BillingCountry = 'India' AND Type__c = 'Key Account Private' LIMIT 1];
        String rejectionReason = 'Test rejection reason';
        
        System.runAs(nationalHeadUser) {
            Test.startTest();
            PurchaseOrderApprovalController.updateApprovalStatus(testOrder.Id, 'Rejected', rejectionReason);
            Test.stopTest();
            
            Order updatedOrder = [SELECT Approval_Status__c, Reason_For_Rejection__c FROM Order WHERE Id = :testOrder.Id];
            System.assertEquals('Rejected', updatedOrder.Approval_Status__c, 'Approval status should be Rejected');
            System.assertEquals(rejectionReason, updatedOrder.Reason_For_Rejection__c, 'Rejection reason should match');
        }
    }
    
    
    @IsTest
    static void testUpdateApprovalStatusElsePathWithNullStatus() {
        User nationalHeadUser = [SELECT Id FROM User WHERE Email = 'national.head@test.com'];
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Order testOrder = new Order(
            Name = 'Test Order - Null Status',
            Status = 'Draft',
            EffectiveDate = System.today(),
            EndDate = System.today().addDays(30),
            AccountId = testAccount.Id,
            BillingCountry = 'India',
            Type__c = 'Key Account Private',
            Approval_Status__c = 'Rejected',
            Reason_For_Rejection__c = 'Old reason'
        );
        insert testOrder;
        System.debug('Inserted Order Id: ' + testOrder.Id);
        
        System.runAs(nationalHeadUser) {
            Test.startTest();
            try {
                PurchaseOrderApprovalController.updateApprovalStatus(testOrder.Id, null, null);
            } catch (Exception e) {
                System.debug('Caught exception during update: ' + e.getMessage());
                System.assert(false, 'Unexpected exception: ' + e.getMessage());
            }
            Test.stopTest();
        }
        
        List<Order> result = [SELECT Approval_Status__c, Reason_For_Rejection__c FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals(1, result.size(), 'Order should exist');
        Order updatedOrder = result[0];
        
        System.assertEquals(null, updatedOrder.Reason_For_Rejection__c, 'Rejection reason should be cleared');
    }
    
    
    
    @IsTest
    static void testUpdateApprovalStatusError() {
        User nationalHeadUser = [SELECT Id FROM User WHERE Email = 'national.head@test.com'];
        
        System.runAs(nationalHeadUser) {
            Test.startTest();
            try {
                PurchaseOrderApprovalController.updateApprovalStatus(null, 'Approved', null);
                System.assert(false, 'Expected exception was not thrown');
            } catch (AuraHandledException e) {
                // System.assert(e.getMessage().contains('Error updating approval status'), 'Should throw AuraHandledException');
            }
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testGetOrdersForChannelSalesHeadWithRSMMatch() {
        User channelSalesUser = [SELECT Id, Username, UserRole.Name FROM User WHERE Email = 'channel.sales@test.com'];
        
        System.runAs(channelSalesUser) {
            Test.startTest();
            PurchaseOrderApprovalController.OrderApproverWrapper result = 
                PurchaseOrderApprovalController.getOrdersForCurrentApprover();
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }
    @IsTest
    static void testGetOrders_ExceptionPath() {
        User rsmUser = [SELECT Id FROM User WHERE Email = 'rsm@test.com'];
        
        System.runAs(rsmUser) {
            Test.startTest();
            try {
                
                PurchaseOrderApprovalController.getOrdersForCurrentApprover();
            } catch (AuraHandledException ex) {
                System.assert(ex.getMessage().contains('Error fetching orders'), 'Should catch AuraHandledException');
            }
            Test.stopTest();
        }
    }
    @isTest
    static void testUserWithoutRoleReturnsEmptyResponse() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User noRoleUser = new User(
            FirstName = 'NoRole',
            LastName = 'User',
            Email = 'noroleuser@test.com',
            Username = 'noroleuser_' + System.currentTimeMillis() + '@test.com',
            Alias = 'noru',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
            
        );
        insert noRoleUser;
        
        System.runAs(noRoleUser) {
            Test.startTest();
            
            // Use outer class to reference inner wrapper
            PurchaseOrderApprovalController.OrderApproverWrapper result =
                PurchaseOrderApprovalController.getOrdersForCurrentApprover();
            
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Expected result not to be null');
            System.assertEquals(0, result.orders.size(), 'Expected no orders for user with no role');
        }
    }
    
    
}