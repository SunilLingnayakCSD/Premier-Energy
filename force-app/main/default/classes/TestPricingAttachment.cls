@isTest
public class TestPricingAttachment {

    @testSetup
    static void setupData() {
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

        Profile keyAccountProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; 
        Profile mdProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; 
        
        User u1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'testuser1@example.com',
            Username = 'testuser1@example.com.' + System.currentTimeMillis(),
            Alias = 'tuser1',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = keyAccountProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        User u2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Email = 'testuser2@example.com',
            Username = 'testuser2@example.com.' + System.currentTimeMillis(),
            Alias = 'tuser2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = mdProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert new List<User>{u1, u2};
    }

    @isTest
    static void testSavePricingData() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        PricingAttachment.savePricingData(
            testOpp.Id,
            '{"key": "value"}',
            '{"cost": "100"}',
            '{"log": "inbound"}',
            '{"sea": "data"}',
            '{"inland": "transport"}',
            '{"finance": "params"}',
            '{"aop": "ebitda"}',
            '{"pre": "ebitda"}',
            '{"india": "pro"}',
            '{"cmv": "pro"}',
            '{"package": "2040"}',
            '{"log": "outbound"}'
        );
        Test.stopTest();

        Opportunity updatedOpp = [SELECT PricingRawJSON__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('{"key": "value"}', updatedOpp.PricingRawJSON__c);
    }

    @isTest
    static void testGeneratePricingAttachment() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockPDFCallout());

        PricingAttachment.generatePricingAttachment(
            testOpp.Id,
            100.50,
            10050,
            'TestFile',
            'India'
        );
        Test.stopTest();

        List<ContentVersion> versions = [SELECT Id, Title FROM ContentVersion WHERE Title = 'TestFile'];
        System.assert(!versions.isEmpty(), 'ContentVersion should have been created');
    }
    
    @isTest
    static void testGeneratePricingAttachmentflow() {
       Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(10),
            National_Head_Approval__c = 'Approved',
            MD_Approval__c = 'Approved',
            Approved_Date_Time__c = System.now()
        );
        insert opp;
        
        PricingAttachment.Request req = new PricingAttachment.Request();
        req.recordId = opp.Id;
        req.finalPrice = 1000;
        req.finalPriceinCent = 100000;
        req.fileName = 'TestFile';
        req.countrySource = 'USA';

        Test.startTest();
        PricingAttachment.generatePricingAttachmentwhenApproved(new List<PricingAttachment.Request>{ req });
        Test.stopTest();

        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion WHERE Title = 'TestFile'];
        System.assertEquals(1, cvs.size());

        List<ContentDocumentLink> cdls = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id];
        System.assert(cdls.size() > 0, 'Expected document link on Opportunity');


    }

    public class MockPDFCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/pdf');
            res.setBodyAsBlob(Blob.valueOf('Fake PDF Content'));
            res.setStatusCode(200);
            return res;
        }
    }
}