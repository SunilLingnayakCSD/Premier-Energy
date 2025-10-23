@isTest
public class OpportunitySOReminderBatchTest {
    
    static Opportunity opp;
    
    @testSetup
    static void testSetUp() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        opp = new Opportunity(
            Name = 'Test Opportunity Record',
            CloseDate = Date.newInstance(2025, 4, 9),
            StageName = 'Closed Won',
            AccountId = acc.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Government' AND SObjectType = 'Opportunity' LIMIT 1].Id,
            Region_Head_Email__c = 'test@gmail.com'
        );
        insert opp;
        
    }
    
    @isTest
    static void testBatchExecution(){
        
        Test.startTest();
        
        // Execute the batch
        Database.executeBatch(new OpportunitySOReminderBatch(), 200);
        
        // Stop Test context
        Test.stopTest();
    }
    
    @isTest
    static void testSchedulableExecution() {
        // Test the schedulable interface
        Test.startTest();
        
        String jobID = System.schedule('Opportunity So Reminder', '0 0 0 15 8 ?', new OpportunitySOReminderBatch());
        
        // Wait for the scheduled job to be processed
        Test.stopTest();
        
        // Verify that the batch job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobID LIMIT 1];
        System.assertNotEquals(null, ct, 'The batch job should have been scheduled.');
    }
    
}