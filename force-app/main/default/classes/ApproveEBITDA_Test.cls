@isTest
private class ApproveEBITDA_Test {
@TestSetup
static void setupTestData() {
    // 1. Fetch profiles and roles
    Profile regionalHeadProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

    Map<String, UserRole> existingRoles = new Map<String, UserRole>();
    for (UserRole ur : [
        SELECT Id, DeveloperName 
        FROM UserRole 
        WHERE DeveloperName IN (
            'North_Region_Head_Key_Account_Private',
            'South_Region_Head_Key_Account_Private',
            'East_Region_Head_Key_Account_Private',
            'West_Region_Head_Key_Account_Private',
            'Key_Account_International_Sales'
        )
    ]) {
        existingRoles.put(ur.DeveloperName, ur);
    }

    // 2. Insert test users (with roles)
    List<User> testUsers = new List<User>();
    for (UserRole role : existingRoles.values()) {
        testUsers.add(new User(
            FirstName = 'Test',
            LastName = role.DeveloperName.replace('_', ' '),
            Email = 'test.' + role.DeveloperName + '@example.com',
            Username = 'test.' + role.DeveloperName + System.currentTimeMillis() + '@example.com',
            Alias = 't' + role.DeveloperName.left(6),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = regionalHeadProfile.Id,
            UserRoleId = role.Id,
            IsActive = true
        ));
    }
    insert testUsers;

    // 3. Fetch a role for Account Owner and insert user (outside runAs)
    UserRole userRole = [SELECT Id FROM UserRole LIMIT 1];
    User accountOwnerUser = new User(
        Alias = 'aou',
        ProfileId = standardProfile.Id,
        Email = 'accowner@test.com',
        Username = 'accowner' + System.currentTimeMillis() + '@test.com',
        LastName = 'Owner',
        FirstName = 'Account',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        UserRoleId = userRole.Id,
        IsActive = true
    );
    insert accountOwnerUser;

    // 4. Use runAs to insert Opportunities (DML separation from Users)
    List<Opportunity> testOpps = new List<Opportunity>();
    System.runAs(accountOwnerUser) {
        Address__c addr = new Address__c(
        Name = 'Test Address'
    );
    insert addr;
        for (User u : [
            SELECT Id, UserRole.DeveloperName 
            FROM User 
            WHERE UserRole.DeveloperName LIKE '%Region_Head%' OR UserRole.DeveloperName = 'Key_Account_International_Sales'
        ]) {
            String productCategory = (u.UserRole.DeveloperName.contains('International')) ? 'Cell' : 'Module';
            String domesticExports = (u.UserRole.DeveloperName.contains('International')) ? 'Exports' : 'Domestic';

            testOpps.add(new Opportunity(
                Name = 'Test Opp - ' + u.UserRole.DeveloperName,
                StageName = 'Price Approval & Proposal Submission',
                CloseDate = System.today().addDays(30),
                Product_Category1__c = productCategory,
                Domestic_Exports__c = domesticExports,
                Discounted_Wp_Price__c = 1000,
                Final_Wp_price__c = 1200,
                Final_Wp_price_cents__c = '1400',
                OwnerId = u.Id,
                National_Head_Approval__c = 'Sent for Approval',
                MD_Approval__c = 'Sent for Approval'
            
                // Business fields
                /*transaction_modality__c = 'Others',
                type_of_project_finance1__c = 'Recourse',
                payment_terms1__c = 'Other',
                delivery_schedule_timeline__c = System.today().addDays(15),
                production_period__c = '2 weeks',
                delay_ld1__c = 'On undelivered portion; 0.5% per week up to 5% of the contract price.',
                pre_dispatch_inspection__c = 'Applicable',
                third_party_lab_testing_if_any__c = 'Applicable',
                material_dispatch_clearance_certificate__c = 'Applicable',
                delivery_location__c = 'Delhi',
                inline_inspection__c = 'Applicable',
                incoterms__c = 'CIF',
                Vehicle_Preference_if_any__c = 'Others',
                vehicle_preference_if_any1__c = 'Others',
                serial_defect_liability__c = '12 Months',
                transit_insurance_by__c = 'Buyer',
                vehicle_detention_holding_period__c = '12',
                Vehicle_Detention_Holding_Period_Hrs__c = '12',
                Transit_Damage_Report_Claim_Period_Days__c ='7',
                third_party_warranty_insurance__c = 'Applicable',
                warranty_terms__c = '12 Years Product Warranty & 25 Years Performance Warranty',
            
                Module_Degradation_FirstYear__c='1% (TOPCON)',
                Module_DegradationYoY__c= '0.40% (MonoPERC, Bifacial)',
                Payment_Terms__c = 30,
                Commercial_Deviations__c = 'Yes',
                vehicle_detention_holding_charges_inr__c = 1000.0,
                delay_in_repair_or_replacement_terms__c = 'Standard SLA',
                project_capacity_in_mwp_including_spare__c = 10.0,
                wattage_wp_cell_module__c = '550',
                ship_to__c = addr.Id,
                premier_business_entity__c = 'PEL',
                rfid_readers_qty__c = 2,
                lc_usance_period_in_days__c = '30',
                abg_issuance_date__c = System.today(),
                abg_expiry_date__c = System.today().addMonths(6),
                // abg_validity_days__c = 180.0,
                pbg_issuance_date__c = System.today(),
                pbg_expiry_date__c = System.today().addMonths(12),
                // pbg_validity_days__c = 365.0,
                segment__c = 'Others',
                dcr_non_dcr__c = 'DCR',
                product_details__c = 'Others',
                payment_term_balance__c = 'LC'*/
            ));
            
                    }
            insert testOpps;
     
    }
}

    
    @isTest
    static void testGetCurrentUserRole() {
        User testUser = [SELECT Id FROM User WHERE UserRole.DeveloperName = 'East_Region_Head_Key_Account_Private' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            String roleName = ApproveEBITDA.getCurrentUserRole();
            Test.stopTest();
            
           }
    }
    
    @isTest
    static void testGetDomesticOppforNH() {
        User testUser = [SELECT Id FROM User WHERE UserRole.DeveloperName = 'East_Region_Head_Key_Account_Private' LIMIT 1];
        
        Test.startTest();
        List<Opportunity> results = ApproveEBITDA.getDomesticOppforNH();
        Test.stopTest();
        
        //System.assertEquals('MODULE', results[0].Product_Category1__c, 'Should be module product');
        System.assertEquals('Domestic', results[0].Domestic_Exports__c, 'Should be domestic');
    }
    
    @isTest
    static void testGetCellDomesticOppforNH() {
        // Update one opp to be Cell domestic
        Opportunity cellOpp = [SELECT Id FROM Opportunity WHERE Product_Category1__c = 'MODULE' LIMIT 1];
        cellOpp.Product_Category1__c = 'CELL';
        update cellOpp;
        
        Test.startTest();
        List<Opportunity> results = ApproveEBITDA.getCellDomesticOppforNH();
        Test.stopTest();
    }
    
    @isTest
    static void testGetDomesticOppforMD() {
        // Update one opp to be escalated to MD
        Opportunity mdOpp = [SELECT Id FROM Opportunity LIMIT 1];
        mdOpp.National_Head_Approval__c = 'Escalated';
        mdOpp.MD_Approval__c = 'Sent for Approval';
        update mdOpp;
        
        Test.startTest();
        List<Opportunity> results = ApproveEBITDA.getDomesticOppforMD();
        Test.stopTest();
    }
    
    @isTest
    static void testGetModuleCellExportOppforMD() {
        // Update one opp to be exports and escalated to MD
        Opportunity exportOpp = [SELECT Id FROM Opportunity LIMIT 1];
        exportOpp.Domestic_Exports__c = 'Exports';
        
        exportOpp.National_Head_Approval__c = 'Escalated';
        exportOpp.MD_Approval__c = 'Sent for Approval';
        update exportOpp;
        
        Test.startTest();
        List<Opportunity> results = ApproveEBITDA.getModuleCellExportOppforMD();
        Test.stopTest();

    }
    
    @isTest
    static void testGetExportCellModuleInternational() {
        // Get international sales user's opp
        User intlUser = [SELECT Id FROM User WHERE UserRole.DeveloperName = 'Key_Account_International_Sales' LIMIT 1];
        Opportunity intlOpp = [SELECT Id FROM Opportunity WHERE OwnerId = :intlUser.Id LIMIT 1];
        intlOpp.Domestic_Exports__c = 'Exports';
        intlOpp.National_Head_Approval__c = 'Sent for Approval';
        update intlOpp;
        
        Test.startTest();
        List<Opportunity> results = ApproveEBITDA.getEportCellModuleInternational();
        Test.stopTest();
      }
    
    @isTest
    static void testApproveDomesticByNH() {
        Opportunity testOpp = [SELECT Id, National_Head_Approval__c FROM Opportunity WHERE National_Head_Approval__c = 'Sent for Approval' LIMIT 1];
        
        Test.startTest();
        ApproveEBITDA.approveDomesticByNH(testOpp.Id);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT National_Head_Approval__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Approved', updatedOpp.National_Head_Approval__c, 'Should be approved by NH');
    }
    
    @isTest
    static void testApproveDomesticByMD() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        testOpp.MD_Approval__c = 'Sent for Approval';
        testOpp.Final_Wp_price_cents__c = '1400';
        update testOpp;
        
        Test.startTest();
        ApproveEBITDA.approveDomesticByMD(testOpp.Id);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT MD_Approval__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Approved', updatedOpp.MD_Approval__c, 'Should be approved by MD');
    }
    
    @isTest
    static void testRejectOpportunity() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE National_Head_Approval__c = 'Sent for Approval' LIMIT 1];
        String testComment = 'Test rejection comment';
        
        Test.startTest();
        ApproveEBITDA.rejectOpportunity(testOpp.Id, testComment);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT National_Head_Approval__c, Price_Rejection_Reason__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Rejected', updatedOpp.National_Head_Approval__c, 'Should be rejected');
        System.assertEquals(testComment, updatedOpp.Price_Rejection_Reason__c, 'Should have rejection comment');
    }
    
    @isTest
    static void testRejectOpportunitybyMD() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        testOpp.MD_Approval__c = 'Sent for Approval';
        update testOpp;
        String testComment = 'Test MD rejection comment';
        
        Test.startTest();
        ApproveEBITDA.rejectOpportunitybyMD(testOpp.Id, testComment);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT MD_Approval__c, MD_Rejection_Reason__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Rejected', updatedOpp.MD_Approval__c, 'Should be rejected by MD');
        System.assertEquals(testComment, updatedOpp.MD_Rejection_Reason__c, 'Should have MD rejection comment');
    }
    
    @isTest
    static void testEscalateOpportunity() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE National_Head_Approval__c = 'Sent for Approval' LIMIT 1];
        String testComment = 'Test escalation comment';
        
        Test.startTest();
        ApproveEBITDA.escalateOpportunity(testOpp.Id, testComment);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT National_Head_Approval__c, MD_Approval__c, Escalation_Comments__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Escalated', updatedOpp.National_Head_Approval__c, 'Should be escalated');
        System.assertEquals('Sent for Approval', updatedOpp.MD_Approval__c, 'Should be sent to MD');
        System.assertEquals(testComment, updatedOpp.Escalation_Comments__c, 'Should have escalation comment');
    }
    
    @isTest
    static void testSaveManualEbita() {
        Opportunity testOpp = [SELECT Id, Manual_EBIDTA__c FROM Opportunity LIMIT 1];
        testOpp.Manual_EBIDTA__c = 15.5;
        
        Test.startTest();
        ApproveEBITDA.saveManualEbita(new List<Opportunity>{testOpp});
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Manual_EBIDTA__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(15.5, updatedOpp.Manual_EBIDTA__c, 'Manual EBITDA should be updated');
    }
    
    @isTest
    static void testSaveManualEbitaEmptyList() {
        Test.startTest();
        ApproveEBITDA.saveManualEbita(new List<Opportunity>());
        Test.stopTest();
        // Just verifying no exception is thrown
        System.assert(true);
    }
    
    @isTest
    static void testSaveManualEbitaException() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            ApproveEBITDA.saveManualEbita(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(!exceptionThrown, 'Method should handle null input gracefully');
    }
}