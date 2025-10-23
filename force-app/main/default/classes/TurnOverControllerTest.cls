@IsTest
public class TurnOverControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create Account
        Account distributor = new Account(
            Name = 'Test Distributor',
            Customer_GST_Number__c = 'GST123'
        );
        insert distributor;
        
        // Create Contact
        Contact distributorContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = distributor.Id
        );
        insert distributorContact;
        
        // Create User
        Profile p = [SELECT Id,Name FROM Profile WHERE Name = 'Partner Distributor Access' LIMIT 1];
        User distributorUser = new User(
            Alias = 'dist',
            Email = 'testuser@example.com',
            LastName = 'Distributor',
            Username = 'distributor' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = distributorContact.Id
        );
        insert distributorUser;
        
        // Create Products
        Product2 dcrProduct = new Product2(
            Name = 'DCR Product',
           // DCR_NonDCR__c = 'DCR',
            Wp__c = 100,
            IsActive = true
        );
        Product2 ndcrProduct = new Product2(
            Name = 'NDCR Product',
           // DCR_NonDCR__c = 'NDCR',
            Wp__c = 150,
            IsActive = true
        );
        insert new List<Product2>{dcrProduct, ndcrProduct};
        
        // Create Pricebook Entries
        
        Pricebook2 stdPb = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update stdPb;
        PricebookEntry dcrPbe = new PricebookEntry(
            Pricebook2Id = stdPb.Id,
            Product2Id = dcrProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        PricebookEntry ndcrPbe = new PricebookEntry(
            Pricebook2Id = stdPb.Id,
            Product2Id = ndcrProduct.Id,
            UnitPrice = 150,
            IsActive = true
        );
        insert new List<PricebookEntry>{dcrPbe, ndcrPbe};
        
        // Create Turnover Discounts
        Date today = Date.today();
        List<TurnOver_Discounts__c> discounts = new List<TurnOver_Discounts__c>();
        
        // Monthly discount
        discounts.add(new TurnOver_Discounts__c(
            Distributor__c = distributor.Id,
            Period__c = 'Month',
            Valid_From__c = today.toStartOfMonth(),
            Valid_To__c = today.toStartOfMonth().addMonths(1).addDays(-1),
            Target_Unit__c = 20,
            To_Target__c = 1,
            Payout__c = 0.05,
            Payout_NDCR__c = 0.03
        ));
        
        // Quarterly discount
        discounts.add(new TurnOver_Discounts__c(
            Distributor__c = distributor.Id,
            Period__c = 'Quarter',
            Valid_From__c = today.toStartOfMonth(),
            Valid_To__c = today.toStartOfMonth().addMonths(3).addDays(-1),
            Target_Unit__c = 30,
            To_Target__c = 5,
            Payout__c = 0.07,
            Payout_NDCR__c = 0.05
        ));
        
        // Yearly discount
        discounts.add(new TurnOver_Discounts__c(
            Distributor__c = distributor.Id,
            Period__c = 'Year',
            Valid_From__c = Date.newInstance(today.year(), 4, 1),
            Valid_To__c = Date.newInstance(today.year() + 1, 3, 31),
            Target_Unit__c = 90,
            To_Target__c = 20,
            Payout__c = 0.10,
            Payout_NDCR__c = 0.08
        ));
        insert discounts;
        
        // Create Invoices
        List<Invoice__c> invoices = new List<Invoice__c>();
        for (Integer i = 0; i < 3; i++) {
            invoices.add(new Invoice__c(
                Account__c = distributor.Id,
                Invoice_Date__c = today,
                Status__c = 'Request'
            ));
        }
        insert invoices;
        
        // Create Invoice Line Items
        List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>();
        for (Invoice__c inv : invoices) {
            lineItems.add(new Invoice_Line_Item__c(
                Invoice__c = inv.Id,
                Product__c = dcrProduct.Id,
                Quantity__c = 1000  // 1000 * 100W = 100,000W = 0.1 MWp
            ));
            lineItems.add(new Invoice_Line_Item__c(
                Invoice__c = inv.Id,
                Product__c = ndcrProduct.Id,
                Quantity__c = 1000  // 1000 * 150W = 150,000W = 0.15 MWp
            ));
        }
        insert lineItems;
    }
    
  //1
  
    @IsTest
    static void testGetFilteredTurnoverYearly() {
        User distributorUser = [SELECT Id FROM User WHERE LastName = 'Distributor' LIMIT 1];
        
        Test.startTest();
        System.runAs(distributorUser) {
            // Use fiscal year dates (Apr 1 - Mar 31)
            Date startDate = Date.newInstance(Date.today().year(), 4, 1);
            Date endDate = Date.newInstance(Date.today().year() + 1, 3, 31);
            
            Map<String, List<TurnOverController.AggregatePayoutResult>> results = 
                TurnOverController.getFilteredTurnover(startDate, endDate);
            
            System.assert(results.containsKey('Year'), 'Should have yearly results');
            System.assert(!results.get('Year').isEmpty(), 'Yearly results should not be empty');
        }
        Test.stopTest();
    }
    
   
   //2
    @IsTest
    static void testGetProductsByMonthYearNoDates() {
        Test.startTest();
        List<TurnOverController.ProductWrapper> products = 
            TurnOverController.getProductsByMonthYear(null, null, null, null);
        
        System.assert(!products.isEmpty(), 'Should return products without date filters');
        Test.stopTest();
    }
    
   
    //3
    @IsTest
    static void testGetProductsByMonthYearNoResults() {
        Test.startTest();
        List<TurnOverController.ProductWrapper> products = 
            TurnOverController.getProductsByMonthYear(2000, 1, 2000, 1);
        
        System.assert(products.isEmpty(), 'Should return no products for old date range');
        Test.stopTest();
    }


}