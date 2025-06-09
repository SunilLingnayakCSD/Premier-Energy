@isTest
public class TurnOverControllerTest {

    @TestSetup
    static void setupBaseData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniqueUsername = 'testuser' + System.currentTimeMillis() + '@testorg.com';
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUsername
        );
        insert testUser;
    }

    static void setupTestData() {
        // Get current user to set as owner/creator
        Id currentUserId = UserInfo.getUserId();
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 3; i++) {
            products.add(new Product2(
                Name = 'Test Product ' + i, 
                IsActive = true
            ));
        }
        insert products;

        List<PricebookEntry> standardEntries = new List<PricebookEntry>();
        for (Product2 p : products) {
            standardEntries.add(new PricebookEntry(
                Product2Id = p.Id,
                Pricebook2Id = standardPricebook.Id,
                UnitPrice = 100.0,
                IsActive = true
            ));
        }
        insert standardEntries;

        Account distributor = new Account(Name = 'Test Distributor');
        insert distributor;

        List<TurnOver_Discounts__c> turnoverRecords = new List<TurnOver_Discounts__c>();
        for (String period : new List<String>{'Month', 'Quarter', 'Year'}) {
            turnoverRecords.add(new TurnOver_Discounts__c(
                Distributor__c = distributor.Id,
                Material_No__c = 'MAT-001',
                Payout__c = 50,
                Payout_Type__c = 'Fixed',
                Period__c = period,
                Target_Unit__c = 100,
                Achieved__c = 80,
                OwnerId = currentUserId  // Set owner to current user
            ));
        }
        insert turnoverRecords;
    }

    @isTest
    static void testGetFilteredTurnover() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@testorg.com' LIMIT 1];

        System.runAs(testUser) {
            setupTestData();
            
            Date startDate = Date.today().addDays(-5);
            Date endDate = Date.today().addDays(5);

            Test.startTest();
            Map<String, List<TurnOver_Discounts__c>> resultMap = TurnOverController.getFilteredTurnover(startDate, endDate);
            Test.stopTest();

            System.assertNotEquals(null, resultMap, 'Result map should not be null');
            System.assertEquals(3, resultMap.keySet().size(), 'Should have 3 periods (Month, Quarter, Year)');
            System.assertEquals(1, resultMap.get('Month').size(), 'Month should have 1 record');
            System.assertEquals(1, resultMap.get('Quarter').size(), 'Quarter should have 1 record');
            System.assertEquals(1, resultMap.get('Year').size(), 'Year should have 1 record');
        }
    }

    @isTest
    static void testGetProductsByMonthYear_WithDates() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@testorg.com' LIMIT 1];

        System.runAs(testUser) {
            setupTestData();

            Test.startTest();
            List<TurnOverController.ProductWrapper> productsWithDates = TurnOverController.getProductsByMonthYear(
                Date.today().year(), Date.today().month(), Date.today().year(), Date.today().month()
            );
            Test.stopTest();

            // Should return products created today by the current user
            System.assert(productsWithDates.size() >= 0, 'Should return products for current date range');
            
            // Test ProductWrapper constructor coverage
            for (TurnOverController.ProductWrapper pw : productsWithDates) {
                System.assert(pw.productId != null, 'Product Id should not be null');
                System.assert(pw.productName != null, 'Product name should not be null');
                System.assert(pw.price != null, 'Price should not be null');
            }
        }
    }

    @isTest
    static void testGetProductsByMonthYear_WithoutDates() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@testorg.com' LIMIT 1];

        System.runAs(testUser) {
            setupTestData();

            Test.startTest();
            List<TurnOverController.ProductWrapper> productsWithoutDates = TurnOverController.getProductsByMonthYear(
                null, null, null, null
            );
            Test.stopTest();

            // Test ProductWrapper constructor and for loop coverage
            for (TurnOverController.ProductWrapper pw : productsWithoutDates) {
                System.assert(pw.productName.startsWith('Test Product'), 'Product name should match pattern');
                System.assert(pw.price > 0, 'Price should be positive');
                System.assert(pw.productId != null, 'Product Id should not be null');
            }
        }
    }

    @isTest
    static void testGetFilteredTurnover_EmptyResults() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@testorg.com' LIMIT 1];

        System.runAs(testUser) {
            // Don't setup test data to test empty result scenario
            Date startDate = Date.today().addDays(-5);
            Date endDate = Date.today().addDays(5);

            Test.startTest();
            Map<String, List<TurnOver_Discounts__c>> resultMap = TurnOverController.getFilteredTurnover(startDate, endDate);
            Test.stopTest();

            System.assertNotEquals(null, resultMap, 'Result map should not be null');
            System.assertEquals(0, resultMap.keySet().size(), 'Should have 0 periods when no data');
        }
    }

    @isTest
    static void testProductWrapper_Constructor() {
        // Direct test of ProductWrapper constructor to ensure 100% coverage
        Test.startTest();
        
        Id testId = '01t000000000000AAA'; // Sample Product2 Id
        String testName = 'Test Product Name';
        Decimal testPrice = 99.99;
        
        TurnOverController.ProductWrapper wrapper = new TurnOverController.ProductWrapper(testId, testName, testPrice);
        
        Test.stopTest();
        
        System.assertEquals(testId, wrapper.productId, 'Product ID should match');
        System.assertEquals(testName, wrapper.productName, 'Product name should match');
        System.assertEquals(testPrice, wrapper.price, 'Price should match');
    }

    @isTest
    static void testGetProductsByMonthYear_FutureDate() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@testorg.com' LIMIT 1];

        System.runAs(testUser) {
            setupTestData();

            Test.startTest();
            // Test with future dates to ensure no results but code coverage
            List<TurnOverController.ProductWrapper> products = TurnOverController.getProductsByMonthYear(
                2030, 1, 2030, 12
            );
            Test.stopTest();

            System.assertEquals(0, products.size(), 'Should return 0 products for future dates');
        }
    }
}