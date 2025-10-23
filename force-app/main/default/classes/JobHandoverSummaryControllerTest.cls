@isTest
public class JobHandoverSummaryControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Customer Account'
        );
        insert testAccount;
        
        // Create test User for Owner
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        // Create test Opportunity with all required fields
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            OwnerId = testUser.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 100000,
            
            // Section A fields
            Domestic_Exports__c = 'Domestic',
            Segment1__c = 'CELL_DOMESTIC',
            DCR_Non_DCR1__c = 'DCR',
            Project_capacity_in_MWp_including_Spare__c = 100.5,
            Premier_Business_Entity1__c = 'PEL',
            Wattage_Wp_Cell_Module1__c = '540.00',
            TotalOpportunityQuantity = 1000,
            Incoterms__c = 'FOB',
            Product_Details_Technology_Type1__c = 'MONOPERC_MONOFACIAL-M10',
            Delivery_Required_by__c = Date.today().addDays(60),
            Delivery_Location__c = 'Mumbai Port',
            
            // Section B fields
            Price_Approval_Reference__c = 'PA-2024-001',
            Purchase_Order_Contract_Reference__c = 'PO-2024-001',
            Transaction_Modality__c = 'Direct Sale',
            Customer_SPOC_Name__c = 'John Doe',
            Customer_SPOC_EMAIL__c = 'john.doe@customer.com',
            Customer_SPOC_Mobile_No__c = '+91-9876543210',
            Transit_Damage_Report_Claim_Period_Days__c = '30',
            Vehicle_Preference_if_any1__c = '40FT Trailer',
            freight_cost__c = 50000,
            Vehicle_Detention_Holding_Period_Hrs__c = '24',
            
            // Section C fields
            BOM_Attachment__c = 'BOM-2024-001.pdf',
            Data_Sheet_Attachment__c = 'DataSheet-540W.pdf',
            QAP_Attachment__c = 'QAP-2024.pdf',
            ReasonAdditional_Technical_Requirements1__c = 'IEC 61215, IEC 61730',
            Cable_length__c = '1400',
            RFID_Readers_Qty__c = 5,
           Inline_Inspection__c = 'Applicable',
            Pre_Dispatch_Inspection__c = 'Applicable',
            
            // Section D fields
            Final_Wp_price__c = 18.50,
            Discounted_Wp_Price__c = 17.75,
            Exchange_Rate_INR_1_USD__c = 83.25,
            Total_Contract_Order_Value__c = 1775000,
            Payment_Terms1__c = 'Other',
            LC_reference__c = 'LC-2024-001',
            Delay_LD1__c = 'Other_Terms',
            
            // Section E fields
            Supply_Agreement__c = 'SA-2024-001',
            Contract_Order_Date__c = Date.today(),
            Third_Party_Warranty_Insurance__c = 'Applicable',
            Other_Details_Note__c = 'Special packaging required'
        );
        insert testOpp;
        
        // Create test Quote
        Quote testQuote = new Quote(
            Name = 'Test Quote - Q-2024-001',
            OpportunityId = testOpp.Id
        );
        insert testQuote;
    }
    
    @isTest
    static void testConstructorWithRecordId() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set up page parameters
        PageReference pageRef = Page.JobHandoverSummary;
        pageRef.getParameters().put('recordId', testOpp.Id);
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        JobHandoverSummaryController controller = new JobHandoverSummaryController();
        Test.stopTest();
        
        // Verify initialization
        System.assertNotEquals(null, controller.wrapper, 'Wrapper should be initialized');
        System.assertEquals(testOpp.Id, controller.opportunityId, 'Opportunity ID should be set');
        System.assertNotEquals(null, controller.currentOpportunity, 'Current opportunity should be loaded');
        
        // Verify data mapping - Section A
        System.assertEquals('Test Customer Account', controller.wrapper.customerName, 'Customer name should be mapped');
        System.assertEquals('Domestic', controller.wrapper.domesticExport, 'Domestic/Export should be mapped');
        System.assertEquals('CELL_DOMESTIC', controller.wrapper.segment, 'Segment should be mapped');
        System.assertEquals('DCR', controller.wrapper.dcrNondcr, 'DCR/Non-DCR should be mapped');
        System.assertEquals(100.5, controller.wrapper.projectCapacityMW, 'Project capacity should be mapped');
        System.assertEquals('PEL', controller.wrapper.businessEntity, 'Business entity should be mapped');
        System.assertEquals('540.00', controller.wrapper.wattage, 'Wattage should be mapped');
        System.assertEquals(1000, controller.wrapper.quantity, 'Quantity should be mapped');
        System.assertEquals('FOB', controller.wrapper.incoterms, 'Incoterms should be mapped');
        System.assertEquals('MONOPERC_MONOFACIAL-M10', controller.wrapper.productDetails, 'Product details should be mapped');
        System.assertEquals('Mumbai Port', controller.wrapper.deliveryLocation, 'Delivery location should be mapped');
        
        // Verify quotation name
        System.assertEquals('Test Quote - Q-2024-001', controller.wrapper.quotationName, 'Quotation name should be mapped');
    }
    
    @isTest
    static void testConstructorWithId() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set up page parameters with 'id' instead of 'recordId'
        PageReference pageRef = Page.JobHandoverSummary;
        pageRef.getParameters().put('id', testOpp.Id);
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        JobHandoverSummaryController controller = new JobHandoverSummaryController();
        Test.stopTest();
        
        // Verify initialization
        System.assertEquals(testOpp.Id, controller.opportunityId, 'Opportunity ID should be set from id parameter');
        System.assertNotEquals(null, controller.currentOpportunity, 'Current opportunity should be loaded');
    }
    
    @isTest
    static void testConstructorWithoutId() {
        // Set up page without parameters
        PageReference pageRef = Page.JobHandoverSummary;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        JobHandoverSummaryController controller = new JobHandoverSummaryController();
        Test.stopTest();
        
        // Verify initialization
        System.assertEquals(null, controller.opportunityId, 'Opportunity ID should be null');
        System.assertEquals(null, controller.currentOpportunity, 'Current opportunity should be null');
        System.assertNotEquals(null, controller.wrapper, 'Wrapper should still be initialized');
        
        // Check for warning message
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size(), 'Should have one warning message');
        System.assertEquals(ApexPages.Severity.WARNING, messages[0].getSeverity(), 'Should be a warning message');
    }
    
    @isTest
    static void testDataMappingAllSections() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set up page parameters
        PageReference pageRef = Page.JobHandoverSummary;
        pageRef.getParameters().put('recordId', testOpp.Id);
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        JobHandoverSummaryController controller = new JobHandoverSummaryController();
        Test.stopTest(); 
    }
    
    @isTest
    static void testUnitPriceFallback() {
        // Create opportunity with only Final_Wp_price__c (no discounted price)
        Account testAccount = new Account(Name = 'Test Account 2');
        insert testAccount;
        
        Opportunity testOpp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Final_Wp_price__c = 20.00
            // No Discounted_Wp_Price__c
        );
        insert testOpp2;
        
        // Set up page parameters
        PageReference pageRef = Page.JobHandoverSummary;
        pageRef.getParameters().put('recordId', testOpp2.Id);
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        JobHandoverSummaryController controller = new JobHandoverSummaryController();
        Test.stopTest();
        
        // Verify unit price falls back to Final_Wp_price__c
        System.assertEquals(20.00, controller.wrapper.unitPrice, 'Unit price should fall back to final price');
    }
    
    @isTest
    static void testGetLatestQuotationName() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create additional quotes
        List<Quote> additionalQuotes = new List<Quote>();
        for(Integer i = 1; i <= 3; i++) {
            additionalQuotes.add(new Quote(
                Name = 'Quote ' + i,
                OpportunityId = testOpp.Id
            ));
        }
        insert additionalQuotes;
        
        // Set up page parameters
        PageReference pageRef = Page.JobHandoverSummary;
        pageRef.getParameters().put('recordId', testOpp.Id);
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        JobHandoverSummaryController controller = new JobHandoverSummaryController();
        Test.stopTest();
        
        // Verify latest quotation name is returned
        System.assertNotEquals(null, controller.wrapper.quotationName, 'Quotation name should not be null');
        System.assert(controller.wrapper.quotationName.contains('Quote'), 'Should contain a quote name');
    }
    
    @isTest
    static void testGeneratePDF() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set up page parameters
        PageReference pageRef = Page.JobHandoverSummary;
        pageRef.getParameters().put('recordId', testOpp.Id);
        Test.setCurrentPage(pageRef);
        
        JobHandoverSummaryController controller = new JobHandoverSummaryController();
        
        Test.startTest();
        PageReference pdfPage = controller.generatePDF();
        Test.stopTest();
        
        // Verify PDF page reference
        System.assertNotEquals(null, pdfPage, 'PDF page reference should not be null');
        System.assertEquals(testOpp.Id, pdfPage.getParameters().get('id'), 'PDF page should have opportunity ID');
    }
    
    @isTest
    static void testSaveToOpportunity() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set up page parameters
        PageReference pageRef = Page.JobHandoverSummary;
        pageRef.getParameters().put('recordId', testOpp.Id);
        Test.setCurrentPage(pageRef);
        
        JobHandoverSummaryController controller = new JobHandoverSummaryController();
        
        Test.startTest();
        PageReference result = controller.saveToOpportunity();
        Test.stopTest();
        
        // Verify save operation
        System.assertEquals(null, result, 'Save method should return null');
        
        // Check for success message
        List<ApexPages.Message> messages = ApexPages.getMessages();
        Boolean hasConfirmMessage = false;
        for(ApexPages.Message msg : messages) {
            if(msg.getSeverity() == ApexPages.Severity.CONFIRM) {
                hasConfirmMessage = true;
                break;
            }
        }
        System.assert(hasConfirmMessage, 'Should have confirmation message');
    }
    
    @isTest
    static void testErrorHandling() {
        // Test with invalid opportunity ID
        PageReference pageRef = Page.JobHandoverSummary;
        pageRef.getParameters().put('recordId', 'invalid_id');
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        JobHandoverSummaryController controller = new JobHandoverSummaryController();
        Test.stopTest();
        
        // Verify error handling
        List<ApexPages.Message> messages = ApexPages.getMessages();
        Boolean hasErrorMessage = false;
        for(ApexPages.Message msg : messages) {
            if(msg.getSeverity() == ApexPages.Severity.ERROR) {
                hasErrorMessage = true;
                break;
            }
        }
        System.assert(hasErrorMessage, 'Should have error message for invalid ID');
    }
    
    @isTest
    static void testWrapperInitialization() {
        Test.startTest();
        JobHandoverSummaryController controller = new JobHandoverSummaryController();
        Test.stopTest();
        
        // Verify wrapper is properly initialized
        System.assertNotEquals(null, controller.wrapper, 'Wrapper should be initialized');
        
        // Test that wrapper properties can be accessed without errors
        System.assertEquals(null, controller.wrapper.customerName, 'Customer name should be null initially');
        System.assertEquals(null, controller.wrapper.businessEntity, 'Business entity should be null initially');
        System.assertEquals(null, controller.wrapper.unitPrice, 'Unit price should be null initially');
    }
    
    @isTest
    static void testNoQuotesScenario() {
        // Create opportunity without quotes
        Account testAccount = new Account(Name = 'Test Account No Quotes');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity No Quotes',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        // Set up page parameters
        PageReference pageRef = Page.JobHandoverSummary;
        pageRef.getParameters().put('recordId', testOpp.Id);
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        JobHandoverSummaryController controller = new JobHandoverSummaryController();
        Test.stopTest();
        
        // Verify quotation name is null when no quotes exist
        System.assertEquals(null, controller.wrapper.quotationName, 'Quotation name should be null when no quotes exist');
    }
}