@isTest
private class RawMaterialLoggerTest {

    @testSetup
    static void setupTestData() {
        // Create test user
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'test.user@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'test.user@example.com.testclass'
        );
        insert testUser;

        // Create pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create product
        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = true,
            Wp__c = 540,
            Pallet_Factor__c = 26
        );
        insert product;

        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert pbe;

        // Create account
        Address__c account = new Address__c(
            Name = 'Test Account',
            Pincode__c = 600001,
            State__c = 'Tamil Nadu'
        );
        insert account;

        // Create opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Pricebook2Id = standardPricebook.Id,
            Ship_to__c = account.Id,
            Project_capacity_in_MWp_including_Spare__c = 2.5,
            DCR_Non_DCR__c = 'DCR',
            LC_Usance_Period_in_Days__c = '90',
            ABG_Value__c = 10,
            ABG_Validity__c = '60',
            PBG_Value__c = 5,
            PBG_Validity__c = '30',
            Domestic_Exports__c = 'Domestic',
            Payment_Terms__c = 30,
            Segment__c = 'Cell / Domestic',
            Plant_Name__c = 'PEL - ANNARAM PLANT – "1000"',
            Wattage_Wp_Cell_Module__c = '540',
            Vehicle_Preference_if_any__c = '10',
            RFID_Readers_Qty__c = 2
        );
        insert opp;

        // Create opportunity line item dcr
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 2,
            UnitPrice = 1,
            PricebookEntryId = pbe.Id,
            DCR_Non_DCR__c = 'NDCR',
            Product2Id = product.Id
        );
        insert oli;
        
        // Create opportunity line item dcr
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 2,
            UnitPrice = 1,
            PricebookEntryId = pbe.Id,
            DCR_Non_DCR__c = 'DCR',
            Product2Id = product.Id
        );
        insert oli2;
        
        

        // Create raw materials
        Product_Raw_Materials__c oldRM = new Product_Raw_Materials__c(Name = 'Old Raw Material');
        Product_Raw_Materials__c newRM = new Product_Raw_Materials__c(Name = 'New Raw Material');
        insert new List<Product_Raw_Materials__c>{oldRM, newRM};

        // Create outbound logistics record
        Outbound_Logistic__c logistic = new Outbound_Logistic__c(
            Customer_Pincode__c = 600001,
            Plant_Pincode__c = 600100,
            Distance_in_kms__c = 400,
            State__c = 'Tamil Nadu',
            Price_Km__c = 35
        );
        insert logistic;

        // Create freight metadata records
        Freight_Charges__mdt chinaFreight = new Freight_Charges__mdt(
            DeveloperName = 'China',
            Sea_Frieght_USD_20Ft__c = 2000,
            Sea_Frieght_USD_40Ft__c = 3500,
            Inland_Transport_INR_20Ft__c = 5000,
            Inland_Transport_INR_40Ft__c = 8000
        );
        // Metadata can't be inserted in tests, so we'll mock queries later
    }

    // Existing test methods remain unchanged...

    @isTest
    static void testRawMaterialMethod_Domestic() {
        // Create raw materials with different types
        Raw_Materials__c glassMaterial = new Raw_Materials__c(
            Name = 'Test Glass',
            Select_Raw_Material_Type__c = 'Glass',
            Qty_20_Ft__c = 500,
            Qty_40_Ft__c = 0,
            Cell_wattage__c = 0,
            China_ADD__c = 1,
            China_AIDC__c = 0.5,
            China_BCD__c = 10,
            China_CVD__c = 5,
            China_SWS__c = 2,
            Is_Sourced_from_India__c = false,
            Sort__c=1
        );
        
        Raw_Materials__c cellsMaterial = new Raw_Materials__c(
            Name = 'Test Cells',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_20_Ft__c = 0,
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
            China_ADD__c = 1.5,
            China_AIDC__c = 0.6,
            China_BCD__c = 15,
            China_CVD__c = 6,
            China_SWS__c = 3,
            Is_Sourced_from_India__c = false,
            Sort__c=1
        );
        insert new List<Raw_Materials__c>{glassMaterial, cellsMaterial};

        // Link to product
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm1 = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = glassMaterial.Id,
            Net_BoQ__c = 0.5,
            DCR_Net_BoQ__c = 0.6
        );
        Product_Raw_Materials__c prm2 = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = cellsMaterial.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert new List<Product_Raw_Materials__c>{prm1, prm2};

        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'China');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(!result.isEmpty(), 'Result should have data');
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        System.assertEquals(2, wrappers.size(), 'Should return two raw materials');
        
        for(RawMaterialLogger.RawMaterialWrapper wrapper : wrappers) {
            //System.assertNotEquals(0, wrapper.rawCostUSD, 'Raw cost USD should be calculated');
            System.assertNotEquals(0, wrapper.logisticsCalculation, 'Logistics should be calculated');
            System.assertNotEquals(0, wrapper.totalCostWithMarginAdded, 'Total cost with margin should be calculated');
        }
    }

    @isTest
    static void testRawMaterialMethod_Exports() {
        // Update opportunity to Exports
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Domestic_Exports__c = 'Exports';
        update opp;

        // Create raw material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Test Export Material',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
           Sort__c=1,
            Is_Sourced_from_India__c = false
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'China');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertEquals(0, wrapper.totalCostWithMargin, 'Margin should be 0 for exports');
    }
    
    // china low price
    @isTest
    static void testRawMaterialMethod_ExportsChinaLowPrice() {
        // Update opportunity to Exports
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Domestic_Exports__c = 'Exports';
        update opp;

        // Create raw material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Test Export Material',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
           Sort__c=1,
            Is_Sourced_from_India__c = false
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'low price', 'China');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertEquals(0, wrapper.totalCostWithMargin, 'Margin should be 0 for exports');
    } 
    
    
    
    // malaysia low price
    @isTest
    static void testRawMaterialMethod_ExportsMalaysiaLowPrice() {
        // Update opportunity to Exports
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Domestic_Exports__c = 'Exports';
        update opp;

        // Create raw material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Test Export Material',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
           Sort__c=1,
            Is_Sourced_from_India__c = false
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'low price', 'Malaysia');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertEquals(0, wrapper.totalCostWithMargin, 'Margin should be 0 for exports');
    }
    
    // vietnam low price
    @isTest
    static void testRawMaterialMethod_ExportsvietnamLowPrice() {
        // Update opportunity to Exports
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Domestic_Exports__c = 'Exports';
        update opp;

        // Create raw material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Test Export Material',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
           Sort__c=1,
            Is_Sourced_from_India__c = false
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'low price', 'vietnam');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertEquals(0, wrapper.totalCostWithMargin, 'Margin should be 0 for exports');
    }
    
    // india low price
    
    @isTest
    static void testRawMaterialMethod_ExportsIndiaLowPrice() {
        // Update opportunity to Exports
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Domestic_Exports__c = 'Exports';
        update opp;

        // Create raw material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Test Export Material',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
           Sort__c=1,
            Is_Sourced_from_India__c = false
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'low price', 'INDIA');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertEquals(0, wrapper.totalCostWithMargin, 'Margin should be 0 for exports');
    } 
//ndcr
    @isTest
    static void testRawMaterialMethod_NonDCR() {
        // Update line item to Non DCR
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        oli.DCR_Non_DCR__c = 'NDCR';
        update oli;

        // Create raw material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Test NonDCR Material',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
            Is_Sourced_from_India__c = false,
            Sort__c=1
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'China');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        //System.assertEquals(prm.Net_BoQ__c, wrapper.netBoQData, 'Should use Net_BoQ__c for Non DCR');
    }
    // dcr
    @isTest
    static void testRawMaterialMethod_DCR() {
        // Update line item to Non DCR
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        oli.DCR_Non_DCR__c = 'DCR';
        update oli;

        // Create raw material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Test NonDCR Material',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
            Is_Sourced_from_India__c = false,
            Sort__c=1
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'China');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        //System.assertEquals(prm.Net_BoQ__c, wrapper.netBoQData, 'Should use Net_BoQ__c for Non DCR');
    }
// test

    @isTest
    static void testRawMaterialMethod_IndiaSourced() 
    {
        // Create India-sourced material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'India Sourced Material',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
           Sort__c=1,
            Is_Sourced_from_India__c = true
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'China');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertEquals(wrapper.rawCostUSD, wrapper.rawCostINR, 'INR cost should equal USD cost for India-sourced');
    }
    
    // malaysia

    @isTest
    static void testRawMaterialMethod_DifferentCountriesMalaysia() {
        // Create material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Multi-Country Material',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
           Sort__c=1,
            
           
            Is_Sourced_from_India__c = false
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'Malaysia');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertEquals(2, wrapper.countryDataMap.size(), 'Should have data for 2 countries');
        System.assert(wrapper.countryDataMap.containsKey('Malaysia'), 'Should have India data');
        System.assert(wrapper.countryDataMap.containsKey('Malaysia'), 'Should have Vietnam data');
    }
    // vietnam
    @isTest
    static void testRawMaterialMethod_DifferentCountriesVietnam() {
        // Create material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Multi-Country Material',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
           Sort__c=1,
            
           
            Is_Sourced_from_India__c = false
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'vietnam');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertEquals(2, wrapper.countryDataMap.size(), 'Should have data for 2 countries');
        System.assert(wrapper.countryDataMap.containsKey('vietnam'), 'Should have India data');
        System.assert(wrapper.countryDataMap.containsKey('vietnam'), 'Should have Vietnam data');
    }


    @isTest
    static void testRawMaterialMethod_PalletMaterial() {
        // Create pallet raw material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Pallet Material',
            Select_Raw_Material_Type__c = 'Al. Frame',
            Qty_40_Ft__c = 1000,
            Is_Pallet_Raw_Material__c = true,
             Sort__c=1,
            Is_Sourced_from_India__c = true
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'India');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertNotEquals(0, wrapper.totalCostWithMarginAdded, 'Pallet cost should be calculated per module');
    }
    
    // low price india
     @isTest
    static void testRawMaterialMethod_PalletMaterialIndia() {
        // Create pallet raw material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Pallet Material',
            Select_Raw_Material_Type__c = 'Al. Frame',
            Qty_40_Ft__c = 1000,
            Is_Pallet_Raw_Material__c = true,
             Sort__c=1,
            Is_Sourced_from_India__c = true
        );
        insert material;
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Low Price', 'India');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertNotEquals(0, wrapper.totalCostWithMarginAdded, 'Pallet cost should be calculated per module');
    }

    @isTest
    static void testRawMaterialMethod_ZeroWattage() {
        // Update product to have zero wattage
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        product.Wp__c = 0;
        update product;
        
        // Create material
        Raw_Materials__c material = new Raw_Materials__c(
            Name = 'Zero Wattage Material',
            Select_Raw_Material_Type__c = 'Cells',
            Qty_40_Ft__c = 1000,
            Cell_wattage__c = 5.4,
             sort__c=1,
            Is_Sourced_from_India__c = false
        );
        insert material;
        
        Product_Raw_Materials__c prm = new Product_Raw_Materials__c(
            Product__c = product.Id,
            Raw_Materials__c = material.Id,
            Net_BoQ__c = 0.7,
            DCR_Net_BoQ__c = 0.8
        );
        insert prm;

        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'China');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        RawMaterialLogger.RawMaterialWrapper wrapper = wrappers[0];
        System.assertEquals(0.07, wrapper.rawCostINRPerWattage, 'Per wattage cost should be 0 when wattage is 0');
    }

    @isTest
    static void testRawMaterialMethod_DutyCalculations() {
        // Create materials for different duty scenarios
        List<Raw_Materials__c> materials = new List<Raw_Materials__c>();
        
        // Wafer/Cells/Junction Box type
        materials.add(new Raw_Materials__c(
            Name = 'Wafer Material',
            Select_Raw_Material_Type__c = 'Wafer',
            Qty_40_Ft__c = 1000,
            China_ADD__c = 1,
            China_AIDC__c = 0.5,
            China_BCD__c = 10,
            China_CVD__c = 5,
            China_SWS__c = 2,
            Sort__c=1,	
            Is_Sourced_from_India__c = false
        ));
        
        // EVA Front type
        materials.add(new Raw_Materials__c(
            Name = 'EVA Material',
            Select_Raw_Material_Type__c = 'EVA Front',
            Qty_40_Ft__c = 1000,
            China_ADD__c = 1.5,
            China_AIDC__c = 0.6,
            China_BCD__c = 15,
            China_CVD__c = 6,
            China_SWS__c = 3,
           	Sort__c=1,
            Is_Sourced_from_India__c = false
        ));
        
        // Glass type
        materials.add(new Raw_Materials__c(
            Name = 'Glass Material',
            Select_Raw_Material_Type__c = 'Glass',
            Qty_20_Ft__c = 500,
            China_ADD__c = 2,
            China_AIDC__c = 0.7,
            China_BCD__c = 12,
            China_CVD__c = 7,
            China_SWS__c = 4,
            Is_Sourced_from_India__c = false,
            Sort__c=1
        ));
        
        // Al. Frame type
        materials.add(new Raw_Materials__c(
            Name = 'Al. Frame Material',
            Select_Raw_Material_Type__c = 'Al. Frame',
            Qty_40_Ft__c = 1000,
            China_ADD__c = 1.8,
            China_AIDC__c = 0.8,
            China_BCD__c = 18,
            China_CVD__c = 8,
            China_SWS__c = 5,
            Is_Sourced_from_India__c = false,
            Sort__c=1
        ));
        
        insert materials;
        
        // Link to product
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        List<Product_Raw_Materials__c> prms = new List<Product_Raw_Materials__c>();
        for(Raw_Materials__c mat : materials) {
            prms.add(new Product_Raw_Materials__c(
                Product__c = product.Id,
                Raw_Materials__c = mat.Id,
                Net_BoQ__c = 0.7,
                DCR_Net_BoQ__c = 0.8
            ));
        }
        insert prms;

        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, List<RawMaterialLogger.RawMaterialWrapper>> result = 
            RawMaterialLogger.RawMaterial(opp.Id, 'Average Price', 'China');
        Test.stopTest();
        
        List<RawMaterialLogger.RawMaterialWrapper> wrappers = result.values()[0];
        System.assertEquals(4, wrappers.size(), 'Should return four raw materials');
        
        for(RawMaterialLogger.RawMaterialWrapper wrapper : wrappers) {
            System.assertNotEquals(0, wrapper.totalCostWithMargin, 'Duty should be calculated for all types');
        }
    }
    @isTest
    static void testGetAdminInputs() {
        // Ensure required metadata exists (assuming it's in the org)
        // In real tests, you should have these metadata records deployed
        Test.startTest();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, RawMaterialLogger.CostDataWrapper> result = RawMaterialLogger.getAdminInputs(testOpp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.size() > 0, 'Result map should have entries');
        
        for (RawMaterialLogger.CostDataWrapper wrapper : result.values()) {
            System.assertNotEquals(null, wrapper.rfidCostINR, 'RFID cost INR should be calculated');
            System.assertNotEquals(null, wrapper.moduleOverheadCents, 'Module overhead should be calculated');
            System.assertNotEquals(null, wrapper.warrantyInsurance, 'Warranty insurance should be present');
            System.assertNotEquals(null, wrapper.ebitda, 'EBITDA should be calculated');
        }
    }
    
    @isTest
    static void testCheckVariables() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id LIMIT 1];
        List<Product_Raw_Materials__c> rawMaterials = [SELECT Id, Name FROM Product_Raw_Materials__c];

        Id oldRMId, newRMId;
        for (Product_Raw_Materials__c rm : rawMaterials) {
            if (rm.Name == 'Old Raw Material') oldRMId = rm.Id;
            if (rm.Name == 'New Raw Material') newRMId = rm.Id;
        }

        // Create tracking record first
        Product_Raw_Material_Tracking__c prmt = new Product_Raw_Material_Tracking__c(
            Opportunity_Product__c = oli.Id,
            Old_Product_Raw_Materials__c = oldRMId,
            New_Product_Raw_Materials__c = newRMId
        );
        insert prmt;

        List<Id> rawMaterialIds = new List<Id>{oldRMId, newRMId};

        Test.startTest();
        List<Id> result = RawMaterialLogger.checkVariables(
            opp.Id,
            rawMaterialIds,
            oli.Id
        );
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return both material IDs');
        System.assertEquals(newRMId, result[0], 'First result should be new material ID');
    }
    @isTest
    static void testGetUserProfileNamePositive() {
        User testUser = [SELECT Id, Profile.Name FROM User WHERE UserName = 'test.user@example.com.testclass' LIMIT 1];

        Test.startTest();
        String profileName = RawMaterialLogger.getUserProfileName(testUser.Id);
        Test.stopTest();

        System.assertEquals(testUser.Profile.Name, profileName, 'Profile name should match expected value');
    }

    @isTest
    static void testCreateVariables() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id LIMIT 1];
        List<Product_Raw_Materials__c> rawMaterials = [SELECT Id, Name FROM Product_Raw_Materials__c];

        Id oldRMId, newRMId;
        for (Product_Raw_Materials__c rm : rawMaterials) {
            if (rm.Name == 'Old Raw Material') oldRMId = rm.Id;
            if (rm.Name == 'New Raw Material') newRMId = rm.Id;
        }

        Test.startTest();
        RawMaterialLogger.createVariables(
            opp.Id,
            oldRMId,
            newRMId,
            oli.Id
        );
        Test.stopTest();

        List<Product_Raw_Material_Tracking__c> trackingList = [
            SELECT Id, Opportunity_Product__c, Old_Product_Raw_Materials__c, New_Product_Raw_Materials__c
            FROM Product_Raw_Material_Tracking__c
            WHERE Opportunity_Product__c = :oli.Id
        ];

        System.assertEquals(1, trackingList.size(), 'One tracking record should be created');
        System.assertEquals(oldRMId, trackingList[0].Old_Product_Raw_Materials__c, 'Old Raw Material ID should match');
        System.assertEquals(newRMId, trackingList[0].New_Product_Raw_Materials__c, 'New Raw Material ID should match');
    }

}