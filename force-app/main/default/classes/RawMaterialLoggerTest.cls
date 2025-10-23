@IsTest
public class RawMaterialLoggerTest {
    
    // Test data setup method - Only non-setup objects
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create Address
        Address__c shipToAddress = new Address__c(
            Name = 'Test Ship To Address',
            Pincode__c = '123456',
            State__c = 'Karnataka'
        );
        insert shipToAddress;

        // Create Raw Materials
        List<Raw_Materials__c> rawMaterials = new List<Raw_Materials__c>();
        
        rawMaterials.add(new Raw_Materials__c(
            Name = 'Test Material 1400mm',
            UOM__c = 'kg',
            Sort__c = 1,
            Is_Pallet_Raw_Material__c = false,
            Is_Sourced_from_India__c = false,
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Qty_20_Ft__c = 500,
            Cell_wattage__c = 5,
            China_ADD__c = 0.5,
            China_AIDC__c = 0.2,
            China_BCD__c = 5,
            China_CVD__c = 3,
            China_SWS__c = 2
        ));

        rawMaterials.add(new Raw_Materials__c(
            Name = 'Glass Material',
            UOM__c = 'pcs',
            Sort__c = 2,
            Is_Pallet_Raw_Material__c = false,
            Is_Sourced_from_India__c = false,
            Select_Raw_Material_Type__c = 'Glass',
            Qty_40_Ft__c = 800,
            Qty_20_Ft__c = 400,
            Cell_wattage__c = 0,
            China_ADD__c = 1.0,
            China_AIDC__c = 0.3,
            China_BCD__c = 7,
            China_CVD__c = 4,
            China_SWS__c = 3
        ));

        rawMaterials.add(new Raw_Materials__c(
            Name = 'Pallet Material',
            UOM__c = 'kg',
            Sort__c = 3,
            Is_Pallet_Raw_Material__c = true,
            Is_Sourced_from_India__c = true,
            Select_Raw_Material_Type__c = 'Wafer',
            Qty_40_Ft__c = 1200,
            Qty_20_Ft__c = 600,
            Cell_wattage__c = 3,
            China_ADD__c = 0.3,
            China_AIDC__c = 0.1,
            China_BCD__c = 3,
            China_CVD__c = 2,
            China_SWS__c = 1.5
        ));

        rawMaterials.add(new Raw_Materials__c(
            Name = 'Copper Wire 400mm',
            UOM__c = 'kg',
            Sort__c = 4,
            Is_Pallet_Raw_Material__c = false,
            Is_Sourced_from_India__c = false,
            Select_Raw_Material_Type__c = 'Wafer',
            Qty_40_Ft__c = 700,
            Qty_20_Ft__c = 350,
            Cell_wattage__c = 4,
            China_ADD__c = 0.4,
            China_AIDC__c = 0.15,
            China_BCD__c = 4,
            China_CVD__c = 2.5,
            China_SWS__c = 1.8
        ));

        rawMaterials.add(new Raw_Materials__c(
            Name = 'India Sourced Material',
            UOM__c = 'kg',
            Sort__c = 5,
            Is_Pallet_Raw_Material__c = false,
            Is_Sourced_from_India__c = true,
            Select_Raw_Material_Type__c = 'Junction Box',
            Qty_40_Ft__c = 1000,
            Qty_20_Ft__c = 500,
            Cell_wattage__c = 0,
            China_ADD__c = 0.5,
            China_AIDC__c = 0.2,
            China_BCD__c = 5,
            China_CVD__c = 3,
            China_SWS__c = 2
        ));

        insert rawMaterials;

        // Create standard pricebook and activate it
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
    }

    // Helper method to create test user with role
    private static User createTestUserWithRole(String roleName, String profileName) {
        UserRole testRole = new UserRole(Name = roleName, DeveloperName = roleName);
        insert testRole;

        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        
        return new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'testu',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = testRole.Id
        );
    }

    // Test 1: getUserProfileName
    @IsTest
    static void testGetUserProfileName() {
        User testUser = createTestUserWithRole('TestRole', 'Standard User');
        insert testUser;

        Test.startTest();
        String profileName;
        System.runAs(testUser) {
            profileName = RawMaterialLogger.getUserProfileName(testUser.Id);
        }
        Test.stopTest();

        System.assertEquals('Standard User', profileName, 'Profile name should match Standard User');
    }

    // Test 2: getCountryPricing
    @IsTest
    static void testGetCountryPricing() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30),
            Country_Source__c = 'China',
            Pricing_Type__c = 'Average Price'
        );
        insert opp;

        Test.startTest();
        Map<String, String> pricingData = RawMaterialLogger.getCountryPricing(opp.Id);
        Test.stopTest();

        System.assertEquals('China', pricingData.get('countrySource'), 'Country source should be China');
        System.assertEquals('Average Price', pricingData.get('pricingType'), 'Pricing type should be Average Price');
    }

    // Test 3: updateCountry
    @IsTest
    static void testUpdateCountry() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity Update',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(15),
            Country_Source__c = 'China'
        );
        insert opp;

        Test.startTest();
        RawMaterialLogger.updateCountry('Vietnam', opp.Id);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Country_Source__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Vietnam', updatedOpp.Country_Source__c, 'Country should be updated to Vietnam');
    }

    // Test 4: updatePricingType
    @IsTest
    static void testUpdatePricingType() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity Pricing',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(10),
            Pricing_Type__c = 'Average Price'
        );
        insert opp;

        Test.startTest();
        RawMaterialLogger.updatePricingType('Low Price', opp.Id);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Pricing_Type__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Low Price', updatedOpp.Pricing_Type__c, 'Pricing type should be updated to Low Price');
    }

    // Test 5: updateFinalWP - New revision increment
    @IsTest
    static void testUpdateFinalWPRevisionIncrement() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity Revision',
            AccountId = acc.Id,
            StageName = 'Proposal/Price Quote',
            CloseDate = System.today().addDays(20),
            Final_Wp_price__c = 6000,
            Generated_Quote_with_Reference__c = '6000 R1'
        );
        insert opp;

        Test.startTest();
        RawMaterialLogger.updateFinalWP(opp.Id, 6500, 65, 1350, 800, 300);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Generated_Quote_with_Reference__c, Final_Wp_price__c, PricingUpdatedByKAM__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('6500 R2', updatedOpp.Generated_Quote_with_Reference__c, 'Quote reference should be incremented to R2');
        System.assertEquals(6500, updatedOpp.Final_Wp_price__c, 'Final WP price should be updated to 6500');
        System.assertEquals(true, updatedOpp.PricingUpdatedByKAM__c, 'PricingUpdatedByKAM should be set to true');
    }

    // Test 6: updateFinalWP - First time (null reference)
    @IsTest
    static void testUpdateFinalWPFirstTime() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity First',
            AccountId = acc.Id,
            StageName = 'Proposal/Price Quote',
            CloseDate = System.today().addDays(20),
            Generated_Quote_with_Reference__c = null
        );
        insert opp;

        Test.startTest();
        RawMaterialLogger.updateFinalWP(opp.Id, 5500, 55, 1200, 700, 250);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Generated_Quote_with_Reference__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('5500 R1', updatedOpp.Generated_Quote_with_Reference__c, 'Quote reference should be set to R1 for first time');
    }

    // Test 7: createVariables - 1400mm cable
    @IsTest
    static void testCreateVariables1400mm() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Raw_Materials__c rawMat = [SELECT Id FROM Raw_Materials__c WHERE Name = 'Test Material 1400mm' LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp Cable',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30),
            Cable_length__c = '400'
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100
        );
        insert oli;

        Product_Raw_Materials__c prmOld = new Product_Raw_Materials__c();
        insert prmOld;

        Product_Raw_Materials__c prmNew = new Product_Raw_Materials__c(Raw_Materials__c = rawMat.Id);
        insert prmNew;

        Test.startTest();
        RawMaterialLogger.createVariables(opp.Id, prmOld.Id, prmNew.Id, oli.Id);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Cable_length__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('1400', updatedOpp.Cable_length__c, 'Cable length should be updated to 1400mm');
    }

    // Test 8: createVariables - 400mm cable
    @IsTest
    static void testCreateVariables400mm() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Raw_Materials__c rawMat = [SELECT Id FROM Raw_Materials__c WHERE Name = 'Copper Wire 400mm' LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp Cable 400',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30)
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100
        );
        insert oli;

        Product_Raw_Materials__c prmOld = new Product_Raw_Materials__c();
        insert prmOld;

        Product_Raw_Materials__c prmNew = new Product_Raw_Materials__c(Raw_Materials__c = rawMat.Id);
        insert prmNew;

        Test.startTest();
        RawMaterialLogger.createVariables(opp.Id, prmOld.Id, prmNew.Id, oli.Id);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Cable_length__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('400', updatedOpp.Cable_length__c, 'Cable length should be set to 400mm');
    }

    // Test 9: checkVariables
    @IsTest
    static void testCheckVariables() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Raw_Materials__c rawMat = [SELECT Id FROM Raw_Materials__c LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp Variables',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30)
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100
        );
        insert oli;

        Product_Raw_Materials__c prm1 = new Product_Raw_Materials__c(Raw_Materials__c = rawMat.Id);
        Product_Raw_Materials__c prm2 = new Product_Raw_Materials__c(Raw_Materials__c = rawMat.Id);
        insert new List<Product_Raw_Materials__c>{prm1, prm2};

        Product_Raw_Material_Tracking__c tracking = new Product_Raw_Material_Tracking__c(
            Opportunity_Product__c = oli.Id,
            Old_Product_Raw_Materials__c = prm1.Id,
            New_Product_Raw_Materials__c = prm2.Id
        );
        insert tracking;

        Test.startTest();
        List<Id> result = RawMaterialLogger.checkVariables(opp.Id, new List<Id>{prm1.Id}, oli.Id);
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return tracking record IDs');
        System.assertEquals(1, result.size(), 'Should return exactly one tracking record ID');
    }

    // Test 10: Boolean methods
    @IsTest
    static void testBooleanMethods() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Boolean Methods',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30),
            PricingUpdatedByKAM__c = true,
            National_Head_Approval__c = 'Sent for Approval'
        );
        insert opp;

        Test.startTest();
        Boolean kamUpdated = RawMaterialLogger.alreadyUpdatedByKAM(opp.Id);
        Boolean grayOut = RawMaterialLogger.grayoutforNH(opp.Id);
        Boolean lockPrice = RawMaterialLogger.lockingprice(opp.Id);
        Test.stopTest();

        System.assertEquals(true, kamUpdated, 'KAM should have updated the price');
        System.assertEquals(true, grayOut, 'Should gray out for National Head');
        System.assertEquals(false, lockPrice, 'Price should not be locked');
    }

    // Test 11: updateFinalWPbyNH
    @IsTest
    static void testUpdateFinalWPbyNH() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test NH Update',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30)
        );
        insert opp;

        Test.startTest();
        RawMaterialLogger.updateFinalWPbyNH(opp.Id, 1500, 800);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT New_PBT_Value__c, New_Ebita_Value__c, NH_Updated_Price__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(1500, updatedOpp.New_PBT_Value__c, 'PBT value should be updated');
        System.assertEquals(800, updatedOpp.New_Ebita_Value__c, 'EBITA value should be updated');
        System.assertEquals(true, updatedOpp.NH_Updated_Price__c, 'NH Updated flag should be set');
    }

    // Test 12: getAdminInputs - Comprehensive test
    @IsTest
    static void testGetAdminInputsComprehensive() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Address__c shipTo = [SELECT Id FROM Address__c LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Test Admin Inputs',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30),
            Ship_to__c = shipTo.Id,
            Project_capacity_in_MWp_including_Spare__c = 100,
            RFID_Readers_Qty__c = 10,
            DCR_Non_DCR1__c= 'DCR',
            Third_Party_Warranty_Insurance__c = 'Applicable',
            ABG_Value__c = 50000,
            PBG_Value__c = 75000,
            Domestic_Exports__c = 'Domestic',
            Payment_Terms__c = 30,
            Segment1__c = 'CELL_DOMESTIC',
            Plant_Store_Name__c = 'PEL - ANNARAM PLANT',
            Product_Details_Technology_Type1__c = 'MONOPERC_MONOFACIAL-M10',
            Wattage_Wp_Cell_Module1__c = '540.00',
            Vehicle_Preference_if_any1__c = '40FT Trailer',
            PalletBasedOnVehicle__c = '30',
            Payment_Term_Balance__c = 'LC',
            Incoterms__c = 'DDP',
            LC_Usance_Period_in_Days__c = '90'
        );
        insert opp;

        Product2 prod = new Product2(
            Name = 'Test Module',
            IsActive = true,
            Wp__c = 540,
            Pallet_Factor__c = 30
        );
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1000,
            UnitPrice = 100,
            DCR_Non_DCR1__c= 'DCR'
        );
        insert oli;

        // Create outbound logistics
        Outbound_Logistic__c outboundLog = new Outbound_Logistic__c(
            Name = 'Test Logistics',
            Customer_Pincode__c = 123456,
            Plant_Pincode__c = 123456,
            Distance_in_kms__c = 500,
            State__c = 'Karnataka',
            Price_Km__c = 25
        );
        insert outboundLog;

        Test.startTest();
        Map<Id, RawMaterialLogger.CostDataWrapper> result = RawMaterialLogger.getAdminInputs(opp.Id);
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return admin input data');
        RawMaterialLogger.CostDataWrapper data = result.get(oli.Id);
        System.assertNotEquals(null, data, 'Cost data should not be null');
        System.assertNotEquals(null, data.rfidCostINR, 'RFID cost should be calculated');
    }

    // Test 13: getAdminInputs - National Head Approval scenario
    @IsTest
    static void testGetAdminInputsNHApproved() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Test NH Approved',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30),
            National_Head_Approval__c = 'Approved',
            PricingAdminJSON__c = '[{"field1": "value1", "field2": "value2"}]'
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test Module', IsActive = true, Wp__c = 540);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1000,
            UnitPrice = 100
        );
        insert oli;

        Test.startTest();
        Map<Id, RawMaterialLogger.CostDataWrapper> result = RawMaterialLogger.getAdminInputs(opp.Id);
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return admin input data for NH approved scenario');
        RawMaterialLogger.CostDataWrapper data = result.get(oli.Id);
        System.assertEquals(true, data.isFromNH, 'Should indicate data is from National Head');
        System.assertNotEquals(null, data.jsonRows, 'JSON rows should be parsed from PricingAdminJSON__c');
    }

    // Test 14: RawMaterial method - Comprehensive test
    @IsTest
    static void testRawMaterialComprehensive() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Raw_Materials__c rawMat = [SELECT Id FROM Raw_Materials__c WHERE Name = 'Test Material 1400mm' LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Test Raw Material',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30),
            Product_Details_Technology_Type1__c = 'MONOPERC_MONOFACIAL-M10',
            Wattage_Wp_Cell_Module1__c = '540.00',
            Domestic_Exports__c = 'Domestic'
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            DCR_Non_DCR1__c= 'DCR',
            Wattage_Wp_Cell_Module1__c = '540.00'
        );
        insert oli;

        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = prod.Id,
            Raw_Materials__c = rawMat.Id,
            Net_BoQ__c = 0.5,
            DCR_Net_BoQ__c = 0.6,
            Is_Variable__c = true,
            Skip_by_defualt__c = false
        );
        insert prm;

        Test.startTest();
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'China');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return raw material data');
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.get(oli.Id);
        System.assert(!wrappers.isEmpty(), 'Should have raw material wrappers');
        
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertEquals('Test Material 1400mm', wrapper.rawMaterialName, 'Raw material name should match');
        System.assertEquals(0.6, wrapper.netBoQData, 'Should use DCR Net BoQ for DCR scenario');
    }

    // Test 15: RawMaterial - Different material types
    @IsTest
    static void testRawMaterialDifferentTypes() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Raw_Materials__c> rawMats = [SELECT Id, Select_Raw_Material_Type__c FROM Raw_Materials__c];
        
        Opportunity opp = new Opportunity(
            Name = 'Test Different Materials',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30),
            Product_Details_Technology_Type1__c = 'MONOPERC_MONOFACIAL-M10',
            Wattage_Wp_Cell_Module1__c = '540.00',
            Domestic_Exports__c = 'Exports'
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test Product Types', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            DCR_Non_DCR1__c= 'NON-DCR',
            Wattage_Wp_Cell_Module1__c = '540.00'
        );
        insert oli;

        List<Product_Raw_Materials__c> prms = new List<Product_Raw_Materials__c>();
        for(Raw_Materials__c rm : rawMats) {
            prms.add(new Product_Raw_Materials__c(
                Product__c = prod.Id,
                Raw_Materials__c = rm.Id,
                Net_BoQ__c = 0.5,
                DCR_Net_BoQ__c = 0.6,
                Is_Variable__c = false,
                Skip_by_defualt__c = false
            ));
        }
        insert prms;

        Test.startTest();
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Low Price', 'Malaysia');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return raw material data for different types');
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.get(oli.Id);
        System.assert(!wrappers.isEmpty(), 'Should have wrappers for different material types');
        
        for(RawMaterialLogger.RawMaterialWrapper wrapper : wrappers) {
            System.assertEquals(0.5, wrapper.netBoQData, 'Should use Net BoQ for NON-DCR scenario');
            System.assertNotEquals(null, wrapper.countryDataMap, 'Country data map should not be null');
        }
    }

    // Test 16: RawMaterial - National Head Approval scenario
    @IsTest
    static void testRawMaterialNHApproved() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Test NH Raw Material',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30),
            National_Head_Approval__c = 'Escalated',
            PricingRawJSON__c = '{"rawMaterial1": {"price": 100}, "rawMaterial2": {"price": 150}}'
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test NH Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100
        );
        insert oli;

        Test.startTest();
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'China');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return raw material data for NH scenario');
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.get(oli.Id);
        System.assert(!wrappers.isEmpty(), 'Should have wrappers for NH scenario');
        
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertEquals(true, wrapper.isFromNH, 'Should indicate data is from National Head');
        System.assertNotEquals(null, wrapper.jsonRows, 'JSON rows should be parsed from PricingRawJSON__c');
    }

    // Test 17: RawMaterial - India sourced materials
    @IsTest
    static void testRawMaterialIndiaSourced() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Raw_Materials__c indiaRawMat = [SELECT Id FROM Raw_Materials__c WHERE Name = 'India Sourced Material' LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Test India Material',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30),
            Product_Details_Technology_Type1__c = 'MONOPERC_MONOFACIAL-M10',
            Wattage_Wp_Cell_Module1__c = '540.00',
            Domestic_Exports__c = 'Domestic'
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test India Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            DCR_Non_DCR1__c= 'DCR',
            Wattage_Wp_Cell_Module1__c = '540.00'
        );
        insert oli;

        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = prod.Id,
            Raw_Materials__c = indiaRawMat.Id,
            Net_BoQ__c = 0.5,
            DCR_Net_BoQ__c = 0.6,
            Is_Variable__c = true,
            Skip_by_defualt__c = false
        );
        insert prm;

        Test.startTest();
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'China');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return data for India sourced materials');
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.get(oli.Id);
        System.assert(!wrappers.isEmpty(), 'Should have wrappers for India sourced material');
    }

    // Test 18: Test calculateDuty for different material types
    @IsTest
    static void testCalculateDutyDifferentMaterials() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create materials for different duty calculations
        List<Raw_Materials__c> dutyMaterials = new List<Raw_Materials__c>();
        
        // Wafer material
        dutyMaterials.add(new Raw_Materials__c(
            Name = 'Wafer Material',
            UOM__c = 'pcs',
            Sort__c = 10,
            Select_Raw_Material_Type__c = 'Wafer',
            Qty_40_Ft__c = 1000,
            China_ADD__c = 0.5,
            China_BCD__c = 5,
            China_CVD__c = 3,
            China_SWS__c = 2,
            China_AIDC__c = 0.2
        ));
        
        // EVA Front material
        dutyMaterials.add(new Raw_Materials__c(
            Name = 'EVA Front Material',
            UOM__c = 'kg',
            Sort__c = 11,
            Select_Raw_Material_Type__c = 'EVA Front',
            Qty_40_Ft__c = 800,
            China_ADD__c = 1.0,
            China_BCD__c = 7,
            China_CVD__c = 4,
            China_SWS__c = 3,
            China_AIDC__c = 0.3
        ));
        
        // Al Frame material
        dutyMaterials.add(new Raw_Materials__c(
            Name = 'Al Frame Material',
            UOM__c = 'pcs',
            Sort__c = 12,
            Select_Raw_Material_Type__c = 'Al. Frame',
            Qty_40_Ft__c = 500,
            China_ADD__c = 2.0,
            China_BCD__c = 10,
            China_CVD__c = 6,
            China_SWS__c = 4,
            China_AIDC__c = 0.5
        ));
        
        insert dutyMaterials;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Duty Calculation',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30),
            Product_Details_Technology_Type1__c = 'MONOPERC_MONOFACIAL-M10',
            Wattage_Wp_Cell_Module1__c = '540.00',
            Domestic_Exports__c = 'Domestic'
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test Duty Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            DCR_Non_DCR1__c= 'DCR',
            Wattage_Wp_Cell_Module1__c = '540.00'
        );
        insert oli;

        List<Product_Raw_Materials__c> prms = new List<Product_Raw_Materials__c>();
        for(Raw_Materials__c rm : dutyMaterials) {
            prms.add(new Product_Raw_Materials__c(
                Product__c = prod.Id,
                Raw_Materials__c = rm.Id,
                Net_BoQ__c = 0.5,
                DCR_Net_BoQ__c = 0.6,
                Is_Variable__c = true,
                Skip_by_defualt__c = false
            ));
        }
        insert prms;

        Test.startTest();
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'China');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return data for duty calculation');
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.get(oli.Id);
        System.assertEquals(3, wrappers.size(), 'Should have wrappers for all three material types');
        
        for(RawMaterialLogger.RawMaterialWrapper wrapper : wrappers) {
            System.assertNotEquals(null, wrapper.totalCostWithMargin, 'Total cost with margin should be calculated');
        }
    }

    

    // Test 19: Test different country pricing
    @IsTest
    static void testDifferentCountryPricing() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Raw_Materials__c rawMat = [SELECT Id FROM Raw_Materials__c WHERE Name = 'Test Material 1400mm' LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Test Country Pricing',
            AccountId = acc.Id,
            StageName = 'RFQ/Enquiry',
            CloseDate = System.today().addDays(30),
            Product_Details_Technology_Type1__c = 'MONOPERC_MONOFACIAL-M10',
            Wattage_Wp_Cell_Module1__c = '540.00',
            Domestic_Exports__c = 'Exports'
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test Country Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            DCR_Non_DCR1__c= 'DCR',
            Wattage_Wp_Cell_Module1__c = '540.00'
        );
        insert oli;

        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = prod.Id,
            Raw_Materials__c = rawMat.Id,
            Net_BoQ__c = 0.5,
            DCR_Net_BoQ__c = 0.6,
            Is_Variable__c = true,
            Skip_by_defualt__c = false
        );
        insert prm;

        Test.startTest();
        // Test Vietnam pricing
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> resultVietnam = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Low Price', 'Vietnam');
        
        // Test Malaysia pricing
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> resultMalaysia = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'Malaysia');
        Test.stopTest();

        // Verify Vietnam results
        System.assert(!resultVietnam.isEmpty(), 'Should return data for Vietnam pricing');
        List<RawMaterialLogger.RawMaterialWrapper> wrappersVietnam = resultVietnam.get(oli.Id);
        System.assert(!wrappersVietnam.isEmpty(), 'Should have wrappers for Vietnam pricing');
        
        // Verify Malaysia results
        System.assert(!resultMalaysia.isEmpty(), 'Should return data for Malaysia pricing');
        List<RawMaterialLogger.RawMaterialWrapper> wrappersMalaysia = resultMalaysia.get(oli.Id);
        System.assert(!wrappersMalaysia.isEmpty(), 'Should have wrappers for Malaysia pricing');
    }
}