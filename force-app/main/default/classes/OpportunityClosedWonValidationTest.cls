@isTest
public class OpportunityClosedWonValidationTest {
    
    @TestSetup
    static void setupTestData() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert testUser;
        
        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = 'karnataka',
            BillingCity = 'Test City',
            BillingState = 'karnataka',
            BillingPostalCode = '12345',
            BillingCountry = 'India'
        );
        insert acc;
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 10000,
            OwnerId = testUser.Id
        );
        insert testOpp;
    }
    @isTest
    public static void testValidation(){
        RecordType r=[SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity' and DeveloperName = 'Key_Account_Private'];
        Account acc = new Account(
            Name = 'Test Acc'
        );
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Opp',
            AccountId = acc.Id,
            StageName = 'Price Approval & Proposal Submission',
            CloseDate = Date.today().addDays(30),
            Amount = 5000,
            recordTypeId = r.Id
        );
       
        
        Test.startTest();
        try {
             insert opp;
        } catch (DmlException e) {
            //System.assert(e.getMessage().contains('billing address'), 'Error message should mention billing address');
        }
        Test.stopTest();        
    }

    @isTest
    public static void testValidation1(){
        RecordType r=[SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity' and DeveloperName = 'Key_Account_Private'];
        Account acc = new Account(
            Name = 'Test Acc'
        );
        insert acc;
        
        Address__c  a = new Address__c ();
        a.Name = 'Mysure';
        Insert a;
        
       Opportunity opp = new Opportunity(
    Name = 'Opp',
    AccountId = acc.Id,
    StageName = 'Price Approval & Proposal Submission',
    CloseDate = Date.today().addDays(30),
    Amount = 5000,
    RecordTypeId = r.Id,

    Transaction_Modality__c = 'Others',
    Type_of_Project_Finance1__c = 'Other (to be mentioned in Text Box)',
    Payment_Terms__c = 100,
    Delivery_Schedule_Timeline__c = Date.today().addDays(60),
    Production_Period__c = '45 Days',
    Delay_LD1__c = 'Other_Terms',
    Pre_Dispatch_Inspection__c = 'Applicable',
    Third_Party_Lab_Testing_if_any__c = 'Not Applicable',
    Material_Dispatch_Clearance_Certificate__c = 'Applicable',
    Delivery_Location__c = 'Hyderabad',
    Inline_Inspection__c = 'Applicable',
    Incoterms__c = 'FOB',
    Vehicle_Preference_if_any1__c = 'Others',
    Serial_Defect_Liability__c = 'test',
    Transit_Insurance_by__c = 'Buyer',
    Vehicle_Detention_Holding_Period_Hrs__c = '12',
    Transit_Damage_Report_Claim_Period_Days__c = '7',
    Third_Party_Warranty_Insurance__c = 'Applicable',
    Warranty_Terms__c = 'Other Terms (to be mentioned in Text Box)',
    Module_Degradation_FirstYear__c = 'Others',
    Module_DegradationYoY__c = 'Other',
    Vehicle_Detention_Holding_Charges_INR__c = 5000,
    Delay_in_Repair_or_Replacement_Terms__c = '15 Days',
    Commercial_Proposal_Submission_Date__c = true,
    Project_capacity_in_MWp_including_Spare__c = 5.5,
    Wattage_Wp_Cell_Module1__c = '540.00',
    Ship_to__c = a.id,
    Premier_Business_Entity1__c = 'PEL',
    RFID_Readers_Qty__c = 5,
    LC_Usance_Period_in_Days__c = '60',
    ABG_Issuance_Date__c = Date.today(),
    ABG_Expiry_Date__c = Date.today().addMonths(6),
    PBG_Issuance_Date__c = Date.today(),
    PBG_Expiry_Date__c = Date.today().addYears(1),
    Domestic_Exports__c = 'Domestic',
    Segment1__c = 'CELL_DOMESTIC',
    DCR_Non_DCR1__c = 'DCR',
    Product_Details_Technology_Type1__c = 'MONOPERC_MONOFACIAL-M10',
    Payment_Term_Balance__c = 'LC',
    Commercial_Deviations__c = 'None'
);
insert opp;

       
        
        Test.startTest();
        try {
            opp.National_Head_Approval__c = 'Sent for Approval';
             update opp;
        } catch (DmlException e) {
            //System.assert(e.getMessage().contains('billing address'), 'Error message should mention billing address');
        }
        Test.stopTest();        
    } 
    @isTest
    public static void testValidation2(){
        RecordType r=[SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity' and DeveloperName = 'Key_Account_Private'];
        Account acc = new Account(
            Name = 'Test Acc'
        );
        insert acc;
        
        Address__c  a = new Address__c ();
        a.Name = 'Mysure';
        Insert a;
        
       Opportunity opp = new Opportunity(
    Name = 'Opp',
    AccountId = acc.Id,
    StageName = 'Price Approval & Proposal Submission',
    CloseDate = Date.today().addDays(30),
    Amount = 5000,
    RecordTypeId = r.Id,

    Transaction_Modality__c = 'Others',
    Type_of_Project_Finance1__c = 'Other (to be mentioned in Text Box)',
    Payment_Terms__c = 100,
    Delivery_Schedule_Timeline__c = Date.today().addDays(60),
    Production_Period__c = '45 Days',
    Delay_LD1__c = 'Other_Terms',
    Pre_Dispatch_Inspection__c = 'Applicable',
    Third_Party_Lab_Testing_if_any__c = 'Not Applicable',
    Material_Dispatch_Clearance_Certificate__c = 'Applicable',
    Delivery_Location__c = 'Hyderabad',
    Inline_Inspection__c = 'Applicable',
    Incoterms__c = 'FOB',
    Vehicle_Preference_if_any1__c = 'Others',
    Serial_Defect_Liability__c = 'test',
    Transit_Insurance_by__c = 'Buyer',
    Vehicle_Detention_Holding_Period_Hrs__c = '12',
    Transit_Damage_Report_Claim_Period_Days__c = '7',
    Third_Party_Warranty_Insurance__c = 'Applicable',
    Warranty_Terms__c = 'Other Terms (to be mentioned in Text Box)',
    Module_Degradation_FirstYear__c = 'Others',
    Module_DegradationYoY__c = 'Other',
    Vehicle_Detention_Holding_Charges_INR__c = 5000,
    Delay_in_Repair_or_Replacement_Terms__c = '15 Days',
    Commercial_Proposal_Submission_Date__c = true,
    Project_capacity_in_MWp_including_Spare__c = 5.5,
    Wattage_Wp_Cell_Module1__c = '540.00',
    Ship_to__c = a.id,
    Premier_Business_Entity1__c = 'PEL',
    RFID_Readers_Qty__c = 5,
    LC_Usance_Period_in_Days__c = '60',
    ABG_Issuance_Date__c = Date.today(),
    ABG_Expiry_Date__c = Date.today().addMonths(6),
    PBG_Issuance_Date__c = Date.today(),
    PBG_Expiry_Date__c = Date.today().addYears(1),
    Domestic_Exports__c = 'Domestic',
    Segment1__c = 'CELL_DOMESTIC',
    DCR_Non_DCR1__c = 'NON-DCR',
    Product_Details_Technology_Type1__c = 'MONOPERC_MONOFACIAL-M10',
    Payment_Term_Balance__c = 'LC',
    Commercial_Deviations__c = 'None'
);
insert opp;

       
        
        Test.startTest();
        try {
            opp.National_Head_Approval__c = 'Approved';
             update opp;
        } catch (DmlException e) {
            //System.assert(e.getMessage().contains('billing address'), 'Error message should mention billing address');
        }
        Test.stopTest();        
    } 
    @isTest
    public static void testValidation3(){
        RecordType r=[SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity' and DeveloperName = 'Key_Account_Private'];
        Account acc = new Account(
            Name = 'Test Acc'
        );
        insert acc;
        
        Address__c  a = new Address__c ();
        a.Name = 'Mysure';
        Insert a;
        
       Opportunity opp = new Opportunity(
    Name = 'Opp',
    AccountId = acc.Id,
    StageName = 'Contract Agreement',
    CloseDate = Date.today().addDays(30),
    Amount = 5000,
    RecordTypeId = r.Id,

    Transaction_Modality__c = 'Others',
    Type_of_Project_Finance1__c = 'Other (to be mentioned in Text Box)',
    Payment_Terms__c = 100,
    Delivery_Schedule_Timeline__c = Date.today().addDays(60),
    Production_Period__c = '45 Days',
    Delay_LD1__c = 'Other_Terms',
    Pre_Dispatch_Inspection__c = 'Applicable',
    Third_Party_Lab_Testing_if_any__c = 'Not Applicable',
    Material_Dispatch_Clearance_Certificate__c = 'Applicable',
    Delivery_Location__c = 'Hyderabad',
    Inline_Inspection__c = 'Applicable',
    Incoterms__c = 'FOB',
    Vehicle_Preference_if_any1__c = 'Others',
    Serial_Defect_Liability__c = 'test',
    Transit_Insurance_by__c = 'Buyer',
    Vehicle_Detention_Holding_Period_Hrs__c = '12',
    Transit_Damage_Report_Claim_Period_Days__c = '7',
    Third_Party_Warranty_Insurance__c = 'Applicable',
    Warranty_Terms__c = 'Other Terms (to be mentioned in Text Box)',
    Module_Degradation_FirstYear__c = 'Others',
    Module_DegradationYoY__c = 'Other',
    Vehicle_Detention_Holding_Charges_INR__c = 5000,
    Delay_in_Repair_or_Replacement_Terms__c = '15 Days',
    Commercial_Proposal_Submission_Date__c = true,
    Project_capacity_in_MWp_including_Spare__c = 5.5,
    Wattage_Wp_Cell_Module1__c = '540.00',
    Ship_to__c = a.id,
    Premier_Business_Entity1__c = 'PEL',
    RFID_Readers_Qty__c = 5,
    LC_Usance_Period_in_Days__c = '60',
    ABG_Issuance_Date__c = Date.today(),
    ABG_Expiry_Date__c = Date.today().addMonths(6),
    PBG_Issuance_Date__c = Date.today(),
    PBG_Expiry_Date__c = Date.today().addYears(1),
    Domestic_Exports__c = 'Domestic',
    Segment1__c = 'CELL_DOMESTIC',
    DCR_Non_DCR1__c = 'NON-DCR',
    Product_Details_Technology_Type1__c = 'MONOPERC_MONOFACIAL-M10',
    Payment_Term_Balance__c = 'LC',
    Commercial_Deviations__c = 'None'
);
insert opp;

       
        
        Test.startTest();
        try {
            opp.National_Head_Approval__c = 'Approved';
             update opp;
        } catch (DmlException e) {
            //System.assert(e.getMessage().contains('billing address'), 'Error message should mention billing address');
        }
        Test.stopTest();        
    } 
    @isTest
    static void testOpportunityClosedWonValidation_Success() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        Opportunity testOpp = [SELECT Id,Transaction_Modality__c FROM Opportunity WHERE Transaction_Modality__c = '' LIMIT 1];
        
        Test.startTest();
        testOpp.Transaction_Modality__c = 'Transaction Modality';
        update testOpp;
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Id, Transaction_Modality__c FROM Opportunity WHERE Id = :testOpp.Id];
    }
    
    @isTest
    static void testOpportunityClosedWonValidation_AccountWithoutBillingAddress() {
        Account accWithoutBilling = new Account(
            Name = 'Account Without Billing'
        );
        insert accWithoutBilling;
        
        Opportunity oppWithoutBilling = new Opportunity(
            Name = 'Opp Without Billing',
            AccountId = accWithoutBilling.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 5000
        );
        insert oppWithoutBilling;
        
        Test.startTest();
        try {
            oppWithoutBilling.StageName = 'Closed Won';
            update oppWithoutBilling;
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('billing address'), 'Error message should mention billing address');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testOpportunityClosedWonValidation_BulkUpdate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opportunities.add(new Opportunity(
                Name = 'Bulk Test Opportunity ' + i,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 1000 * (i + 1)
            ));
        }
        insert opportunities;
        
        Test.startTest();
        for (Opportunity opp : opportunities) {
            opp.StageName = 'Closed Won';
        }
        update opportunities;
        Test.stopTest();
        
        List<Opportunity> updatedOpps = [SELECT Id, StageName FROM Opportunity WHERE Id IN :opportunities];
        for (Opportunity opp : updatedOpps) {
            System.assertEquals('Closed Won', opp.StageName, 'All opportunities should be Closed Won');
        }
    }
    
    @isTest
    static void testOpportunityClosedWonValidation_NonClosedWonStage() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        testOpp.StageName = 'Qualification';
        update testOpp;
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Qualification', updatedOpp.StageName, 'Opportunity should be updated to Qualification');
    }
    
    @isTest
    static void testOpportunityClosedWonValidation_PartialBillingAddress() {
        Account accPartialBilling = new Account(
            Name = 'Account Partial Billing',
            BillingStreet = '456 Oak Ave',
            BillingCity = 'Partial City'
        );
        insert accPartialBilling;
        
        Opportunity oppPartialBilling = new Opportunity(
            Name = 'Opp Partial Billing',
            AccountId = accPartialBilling.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 7500
        );
        insert oppPartialBilling;
        
       
        Test.startTest();
        oppPartialBilling.StageName = 'Closed Won';

        try {
            update oppPartialBilling;

            Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppPartialBilling.Id];
            System.assertEquals('Closed Won', updatedOpp.StageName, 'Opportunity should be updated to Closed Won');
        } catch (DmlException e) {

            System.assert(e.getMessage().contains('billing'), 'Error should be related to billing address');
        }
        Test.stopTest();
    }

    
}