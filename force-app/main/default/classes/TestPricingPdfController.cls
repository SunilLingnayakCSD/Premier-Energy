@isTest
public class TestPricingPdfController {
    
    static testMethod void testControllerFullCoverage() {
        PricingPdfController.ProductWrapper product = new PricingPdfController.ProductWrapper();
        product.productName = 'Test Product';
        product.totalInrWp = 100;
        product.totalCentWp = 200;
        PricingPdfController.MaterialWrapper material = new PricingPdfController.MaterialWrapper();
        material.rawMaterialName = 'Steel';
        material.uom = 'Pcs';
        material.requiredQuantityPerUnit = '100';
        material.formattedRawCostUSD = '50';
        material.formattedRawCostINR = '4000';
        material.formattedLogistics = '100';
        material.formattedInsurance = '20';
        material.formattedDuty = '30';
        material.formattedDdp = '60';
        material.formattedInrWp = '4500';
        material.formattedCentsDp = '5500';
        
        product.materials = new List<PricingPdfController.MaterialWrapper>{ material };
            product.costBreakdown = new List<PricingPdfController.CostRow>();
        
        String rawJson = EncodingUtil.urlEncode(JSON.serialize(product), 'UTF-8');
        
        List<PricingPdfController.CostRow> costRows = new List<PricingPdfController.CostRow>();
        
        PricingPdfController.CostRow row = new PricingPdfController.CostRow();
        row.label = 'Cost A';
        row.col2 = '10';
        row.col3 = '20';
        
        costRows.add(row);
        
        String adminJson = EncodingUtil.urlEncode(JSON.serialize(costRows), 'UTF-8');
        
        List<Map<String, Object>> inboundList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Name' => 'Inbound 1',
                    'extraFields'=> new Map<String,Object>{
                        'China_BCD__c' => 1, 'China_ADD__c' => 1, 'Malaysia_BCD__c' => 1,
                            'Vietnam_Bcd__c' => 1}
            }
        };
            String inboundJson = EncodingUtil.urlEncode(JSON.serialize(inboundList), 'UTF-8');
        
        List<Map<String, Object>> freightList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'containerSize' => '20FT',
                    'formattedValues' => new Map<String, Object>{ 'Cost' => '100' }
            }
        };
            String seaFreightJson = EncodingUtil.urlEncode(JSON.serialize(freightList), 'UTF-8');
        
        List<Map<String, Object>> inlandList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'containerSize' => '40FT',
                    'formattedValues' => new Map<String, Object>{ 'Toll' => '50' }
            }
        };
            String inlandJson = EncodingUtil.urlEncode(JSON.serialize(inlandList), 'UTF-8');
        
        PricingPdfController.FinancialParam param = new PricingPdfController.FinancialParam();
        param.label = 'Interest';
        param.value = '5%';
        String financeJson = EncodingUtil.urlEncode(JSON.serialize(param), 'UTF-8');
        
        List<PricingPdfController.AopEbitdaRow> aopList = new List<PricingPdfController.AopEbitdaRow>();
        
        PricingPdfController.AopEbitdaRow aop = new PricingPdfController.AopEbitdaRow();
        aop.masterLabel = 'AOP 1';
        aop.dcr = 10;
        aop.ndcr = 20;
        
        aopList.add(aop);
        
        String aopJson = EncodingUtil.urlEncode(JSON.serialize(aopList), 'UTF-8');
        
        List<PricingPdfController.PreEbitdaRow> preList = new List<PricingPdfController.PreEbitdaRow>();
        
        PricingPdfController.PreEbitdaRow pre = new PricingPdfController.PreEbitdaRow();
        pre.masterLabel = 'PRE 1';
        pre.dcr = 15;
        pre.ndcr = 25;
        
        preList.add(pre);
        
        String preJson = EncodingUtil.urlEncode(JSON.serialize(preList), 'UTF-8');
        
        String indiaJson = EncodingUtil.urlEncode(JSON.serialize(
            new List<Map<String, Object>>{ new Map<String, Object>{ 'IndiaKey' => 'Value1' } }
        ), 'UTF-8');
        
        String cmvJson = JSON.serialize(
            new List<Map<String, Object>>{ new Map<String, Object>{ 'China_Cost' => '100' } }
        );
        
        
        String packageJson = JSON.serialize(
            new List<Map<String, Object>>{ new Map<String, Object>{ 'PackType' => 'Box' } }
        );
        
        String outboundJson = JSON.serialize(
            new List<Map<String, Object>>{ new Map<String, Object>{ 'Port' => 'Mundra' } }
        );
        
        RecordType r=[SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity' and DeveloperName = 'Key_Account_Private'];
		Account acc = new Account(
            Name = 'Test Acc'
        );
        insert acc;
        
        Address__c  a = new Address__c ();
        a.Name = 'Mysure';
        Insert a;
        // Insert Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Price Approval & Proposal Submission',
            CloseDate = Date.today(),
            Amount = 5000,
    RecordTypeId = r.Id,
            PricingRawJSON__c = rawJson,
            PricingAdminJSON__c = adminJson,
            PricingInboundJSON__c = inboundJson,
            PricingSeaFreightJSON__c = seaFreightJson,
            PricingInLandTranportJSON__c = inlandJson,
            PricingFinanceJSON__c = financeJson,
            PricingAOPJSON__c = aopJson,
            PricingPreEbitdaJSON__c = preJson,
            PricingIndiaProJSON__c = indiaJson,
            PricingCMVProJSON__c = cmvJson,
            PricingPackageJSON__c = packageJson,
            PricingOutboundJSON__c = outboundJson,
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
        
        PageReference pageRef = Page.PricingAttachmentVFPage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('recordId', opp.Id);
        ApexPages.currentPage().getParameters().put('finalPrice', '123.45');
        ApexPages.currentPage().getParameters().put('finalPriceinCent', '12345');
        ApexPages.currentPage().getParameters().put('countrySource', 'China');
        
        PricingPdfController ctrl = new PricingPdfController();
        
        System.assertNotEquals(null, ctrl.products);
        System.assertEquals('China', ctrl.countrySource);
        
        Test.stopTest();
    }
}