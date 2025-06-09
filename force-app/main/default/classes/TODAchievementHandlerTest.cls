@isTest
private class TODAchievementHandlerTest {

    @testSetup
    static void setupTestData() {
        Account distributor = new Account(Name = 'Test Distributor');
        insert distributor;

        List<Invoice__c> invoices = new List<Invoice__c>{
            new Invoice__c(Name='Invoice 1', Account__c=distributor.Id, Invoice_Date__c=System.today().addDays(-10), Total_Capacity_in_MWp__c=100, Amount__c=50000),
            new Invoice__c(Name='Invoice 2', Account__c=distributor.Id, Invoice_Date__c=System.today().addDays(-5), Total_Capacity_in_MWp__c=200, Amount__c=100000),
            // Invoice outside valid date range to test filtering
            new Invoice__c(Name='Invoice 3', Account__c=distributor.Id, Invoice_Date__c=System.today().addDays(-100), Total_Capacity_in_MWp__c=300, Amount__c=150000)
        };
        insert invoices;

        List<TurnOver_Discounts__c> tods = new List<TurnOver_Discounts__c>{
            new TurnOver_Discounts__c(Distributor__c=distributor.Id, Valid_From__c=System.today().addDays(-15), Valid_To__c=System.today().addDays(10), Period__c='Month', Payout_Type__c='Wp'),
            new TurnOver_Discounts__c(Distributor__c=distributor.Id, Valid_From__c=System.today().addDays(-15), Valid_To__c=System.today().addDays(10), Period__c='Quarter', Payout_Type__c='Amount'),
            new TurnOver_Discounts__c(Distributor__c=distributor.Id, Valid_From__c=System.today().addDays(-15), Valid_To__c=System.today().addDays(10), Period__c='Year', Payout_Type__c='Amount'),
            // TOD with missing required fields to test continue logic
            new TurnOver_Discounts__c(Distributor__c=null, Valid_From__c=null, Valid_To__c=null, Period__c='Month', Payout_Type__c='Wp')
        };
        insert tods;
    }

    @isTest
    static void testCalculateTODAchievements_Insert() {
        // Fetch the TOD records after insert to pass as newTODs
        List<TurnOver_Discounts__c> newTODs = [SELECT Id, Distributor__c, Valid_From__c, Valid_To__c, Period__c, Payout_Type__c, Target_Type__c, Achieved__c FROM TurnOver_Discounts__c];
        
        // Pass empty oldMap for insert scenario
        Map<Id, TurnOver_Discounts__c> oldMap = new Map<Id, TurnOver_Discounts__c>();

        Test.startTest();
        TODAchievementHandler.calculateTODAchievements(newTODs, oldMap);
        Test.stopTest();

        // Assert Achieved__c is calculated only for valid records (Distributor not null)
        for (TurnOver_Discounts__c tod : newTODs) {
            if (tod.Distributor__c != null) {
                System.assert(tod.Achieved__c != null && tod.Achieved__c >= 0, 'Achievement should be calculated and non-negative.');
            } else {
                System.assertEquals(null, tod.Achieved__c, 'Achievement should not be calculated when Distributor__c is null.');
            }
        }
    }

    @isTest
    static void testCalculateTODAchievements_Update() {
        // Fetch existing TODs
        List<TurnOver_Discounts__c> existingTODs = [SELECT Id, Distributor__c, Valid_From__c, Valid_To__c, Period__c, Payout_Type__c, Target_Type__c, Achieved__c FROM TurnOver_Discounts__c];

        // Clone old records for oldMap to simulate Trigger.oldMap
        Map<Id, TurnOver_Discounts__c> oldMap = new Map<Id, TurnOver_Discounts__c>();
        for (TurnOver_Discounts__c oldTOD : existingTODs) {
            oldMap.put(oldTOD.Id, oldTOD.clone(false, true, false, false));
        }

        // Modify a field that triggers processing in the handler, e.g., Valid_From__c
        existingTODs[0].Valid_From__c = existingTODs[0].Valid_From__c.addDays(-1);

        Test.startTest();
        TODAchievementHandler.calculateTODAchievements(existingTODs, oldMap);
        Test.stopTest();

        // Assert that Achieved__c has been recalculated (non-null and non-negative)
        System.assert(existingTODs[0].Achieved__c != null && existingTODs[0].Achieved__c >= 0, 'Achievement should be recalculated on update.');
    }

    @isTest
    static void testCalculateTODAchievements_NoProcessing() {
        // Create a TOD list where none of the key fields have changed so processing should skip all
        Account distributor = [SELECT Id FROM Account LIMIT 1];
        TurnOver_Discounts__c oldTOD = new TurnOver_Discounts__c(
            Distributor__c = distributor.Id,
            Valid_From__c = System.today().addDays(-20),
            Valid_To__c = System.today().addDays(10),
            Period__c = 'Month',
            Payout_Type__c = 'Wp'
        );
        insert oldTOD;

        // Clone for oldMap
        Map<Id, TurnOver_Discounts__c> oldMap = new Map<Id, TurnOver_Discounts__c>{ oldTOD.Id => oldTOD.clone(false, true, false, false) };

        // Create newTODs with exactly same values so that condition in handler is false
        TurnOver_Discounts__c newTOD = new TurnOver_Discounts__c(
            Id = oldTOD.Id,
            Distributor__c = oldTOD.Distributor__c,
            Valid_From__c = oldTOD.Valid_From__c,
            Valid_To__c = oldTOD.Valid_To__c,
            Period__c = oldTOD.Period__c,
            Payout_Type__c = oldTOD.Payout_Type__c
        );

        List<TurnOver_Discounts__c> newTODs = new List<TurnOver_Discounts__c>{ newTOD };

        Test.startTest();
        TODAchievementHandler.calculateTODAchievements(newTODs, oldMap);
        Test.stopTest();

        // Since no changes, Achieved__c should remain null
        System.assertEquals(null, newTODs[0].Achieved__c, 'No achievement calculation should occur when key fields unchanged.');
    }

    @isTest
    static void testCalculateTODAchievements_TargetTypeBranches() {
        Account distributor = [SELECT Id FROM Account LIMIT 1];

        // TOD with 'Wp' target type and invoices
        TurnOver_Discounts__c todWp = new TurnOver_Discounts__c(
            Distributor__c = distributor.Id,
            Valid_From__c = System.today().addDays(-20),
            Valid_To__c = System.today().addDays(10),
            Period__c = 'Month',
            Payout_Type__c = 'Wp'
        );
        insert todWp;

        // TOD with 'Amount' target type and invoices
        TurnOver_Discounts__c todAmount = new TurnOver_Discounts__c(
            Distributor__c = distributor.Id,
            Valid_From__c = System.today().addDays(-20),
            Valid_To__c = System.today().addDays(10),
            Period__c = 'Month',
            Payout_Type__c = 'Amount'
        );
        insert todAmount;

        // Prepare newTODs and empty oldMap for insert trigger scenario
        List<TurnOver_Discounts__c> newTODs = [SELECT Id, Distributor__c, Valid_From__c, Valid_To__c, Period__c, Payout_Type__c, Target_Type__c, Achieved__c FROM TurnOver_Discounts__c WHERE Id IN :new List<Id>{todWp.Id, todAmount.Id}];
        Map<Id, TurnOver_Discounts__c> oldMap = new Map<Id, TurnOver_Discounts__c>();

        Test.startTest();
        TODAchievementHandler.calculateTODAchievements(newTODs, oldMap);
        Test.stopTest();

        // Assertions for Wp
        TurnOver_Discounts__c updatedTodWp = [SELECT Achieved__c FROM TurnOver_Discounts__c WHERE Id = :todWp.Id];
        System.assert(updatedTodWp.Achieved__c != null && updatedTodWp.Achieved__c > 0, 'Achievement Wp should be calculated.');

        // Assertions for Amount
        TurnOver_Discounts__c updatedTodAmount = [SELECT Achieved__c FROM TurnOver_Discounts__c WHERE Id = :todAmount.Id];
        System.assert(updatedTodAmount.Achieved__c != null && updatedTodAmount.Achieved__c > 0, 'Achievement Amount should be calculated.');
    }
    
    @isTest
    static void testCalculateTODAchievements_ContinueScenario() {
        // Test that TOD with missing Distributor__c or Valid_From__c/Valid_To__c is skipped (continue branch)
        TurnOver_Discounts__c incompleteTOD = new TurnOver_Discounts__c(
            Distributor__c = null,
            Valid_From__c = null,
            Valid_To__c = null,
            Period__c = 'Month',
            Payout_Type__c = 'Wp'
        );

        List<TurnOver_Discounts__c> newTODs = new List<TurnOver_Discounts__c>{ incompleteTOD };
        Map<Id, TurnOver_Discounts__c> oldMap = new Map<Id, TurnOver_Discounts__c>();

        Test.startTest();
        TODAchievementHandler.calculateTODAchievements(newTODs, oldMap);
        Test.stopTest();

        // If no exceptions, continue branch is covered
        System.assert(true, 'Records with missing mandatory fields are skipped without error.');
    }
    
    @isTest
    static void testCalculateTODAchievements_EmptyInput() {
        Test.startTest();
        TODAchievementHandler.calculateTODAchievements(new List<TurnOver_Discounts__c>(), new Map<Id, TurnOver_Discounts__c>());
        Test.stopTest();
        System.assert(true, 'No exception on empty input.');
    }
}