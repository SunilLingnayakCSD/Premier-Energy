@isTest
private class AOPTargetsAchievementJobTest {
    
    @testSetup
    static void setupTestData() {
        // recordtype='Distributor'
        Id distributorRecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Account' 
            AND DeveloperName = 'Distributor' 
            LIMIT 1
        ].Id;

        // create a account with Distributor recordtype,
        Account testAccount = new Account(
    Name = 'Lead Distributor Account',
    Type = 'Distributor',
    RecordTypeId = distributorRecordTypeId
);
insert testAccount;

        // Create test Account
        
        
        // Create AOP Targets for the account
        AOP_Targets__c testTarget = new AOP_Targets__c(
            Distributor_Account__c = testAccount.Id,
            Name = 'Test Target 2023',  // Often required for custom objects
            April_Target__c = 1000,
            May_Target__c = 1000,
            June_Target__c = 1000,
            July_Target__c = 1000,
            August_Target__c = 1000,
            September_Target__c = 1000,
            October_Target__c = 1000,
            November_Target__c = 1000,
            December_Target__c = 1000,
            January_Target__c = 1000,
            February_Target__c = 1000,
            March_Target__c = 1000
        );
        insert testTarget;
        
        // Create test invoices for the current year
        List<Invoice__c> testInvoices = new List<Invoice__c>();
        Date today = Date.today();
        Integer currentYear = today.year();
        
        // Create invoices for different months
        testInvoices.add(new Invoice__c(
            Account__c = testAccount.Id,
            Invoice_Date__c = Date.newInstance(currentYear, 4, 15),
            Amount__c = 500
        ));
        testInvoices.add(new Invoice__c(
            Account__c = testAccount.Id,
            Invoice_Date__c = Date.newInstance(currentYear, 4, 25),
            Amount__c = 300
        ));
        testInvoices.add(new Invoice__c(
            Account__c = testAccount.Id,
            Invoice_Date__c = Date.newInstance(currentYear, 5, 10),
            Amount__c = 700
        ));
        testInvoices.add(new Invoice__c(
            Account__c = testAccount.Id,
            Invoice_Date__c = Date.newInstance(currentYear, 6, 5),
            Amount__c = 200
        ));
        // Add invoices for other months to test quarterly and annual calculations
        testInvoices.add(new Invoice__c(
            Account__c = testAccount.Id,
            Invoice_Date__c = Date.newInstance(currentYear, 7, 20),
            Amount__c = 400
        ));
        
        insert testInvoices;
    }
    
    @isTest
    static void testBatchJob() {
        // Query the test data
        AOP_Targets__c testTarget = [SELECT Id, Distributor_Account__c FROM AOP_Targets__c LIMIT 1];
        
        Test.startTest();
        // Instantiate and execute the batch
        AOPTargetsAchievementJob batch = new AOPTargetsAchievementJob();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify the results
        AOP_Targets__c updatedTarget = [
            SELECT April_Achieved__c, May_Achieved__c, June_Achieved__c, 
                   Q1_Achieved__c, Annual_Achieved__c
            FROM AOP_Targets__c 
            WHERE Id = :testTarget.Id
        ];
        
        // April: 500 + 300 = 800
        System.assertEquals(800, updatedTarget.April_Achieved__c, 'April achieved amount is incorrect');
        // May: 700
        System.assertEquals(700, updatedTarget.May_Achieved__c, 'May achieved amount is incorrect');
        // June: 200
        System.assertEquals(200, updatedTarget.June_Achieved__c, 'June achieved amount is incorrect');
        // Q1: 800 + 700 + 200 = 1700
        System.assertEquals(1700, updatedTarget.Q1_Achieved__c, 'Q1 achieved amount is incorrect');
        // Annual should include all months (we only created invoices up to July in setup)
        System.assertEquals(2100, updatedTarget.Annual_Achieved__c, 'Annual achieved amount is incorrect');
    }
    
    @isTest
    static void testSchedulable() {
        Test.startTest();
        // Schedule the job
        AOPTargetsAchievementJob job = new AOPTargetsAchievementJob();
        String cronExp = '0 0 0 15 3 ? *';
        System.schedule('Test AOP Targets Achievement Job', cronExp, job);
        Test.stopTest();
        
        // Verify the scheduled job
        List<CronTrigger> cronTriggers = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Test AOP Targets Achievement Job'];
        System.assertEquals(1, cronTriggers.size(), 'The job was not scheduled');
    }
    
    @isTest
    static void testEmptyInvoices() {
        // Delete all invoices to test scenario with no invoices
        delete [SELECT Id FROM Invoice__c];
        
        Test.startTest();
        AOPTargetsAchievementJob batch = new AOPTargetsAchievementJob();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify all achieved fields are zero
        AOP_Targets__c updatedTarget = [
            SELECT April_Achieved__c, May_Achieved__c, June_Achieved__c, 
                   Q1_Achieved__c, Annual_Achieved__c
            FROM AOP_Targets__c 
            LIMIT 1
        ];
        
       /* System.assertEquals(0, updatedTarget.April_Achieved__c, 'April achieved should be 0 when no invoices');
        System.assertEquals(0, updatedTarget.May_Achieved__c, 'May achieved should be 0 when no invoices');
        System.assertEquals(0, updatedTarget.Q1_Achieved__c, 'Q1 achieved should be 0 when no invoices');
        System.assertEquals(0, updatedTarget.Annual_Achieved__c, 'Annual achieved should be 0 when no invoices');*/
    }
    /*
    @isTest
    static void testMultipleAccounts() {
        // Create additional test data for multiple accounts
        Account testAccount2 = new Account(
            Name = 'Test Distributor Account 2'
            // Add other required fields for Account
        );
        insert testAccount2;
        
        AOP_Targets__c testTarget2 = new AOP_Targets__c(
            Distributor_Account__c = testAccount2.Id
            // Set other target fields as needed
        );
        insert testTarget2;
        
        // Create invoices for the second account
        Integer currentYear = Date.today().year();
        Invoice__c testInvoice = new Invoice__c(
            Account__c = testAccount2.Id,
            Invoice_Date__c = Date.newInstance(currentYear, 4, 10),
            Amount__c = 1000
        );
        insert testInvoice;
        
        Test.startTest();
        AOPTargetsAchievementJob batch = new AOPTargetsAchievementJob();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify both targets were processed
        List<AOP_Targets__c> updatedTargets = [
            SELECT Id, Distributor_Account__c, April_Achieved__c 
            FROM AOP_Targets__c 
            ORDER BY Distributor_Account__c
        ];
        
        System.assertEquals(2, updatedTargets.size(), 'Should process all targets');
        System.assertEquals(800, updatedTargets[0].April_Achieved__c, 'First account April achieved incorrect');
        System.assertEquals(1000, updatedTargets[1].April_Achieved__c, 'Second account April achieved incorrect');
    }/*/ 
}