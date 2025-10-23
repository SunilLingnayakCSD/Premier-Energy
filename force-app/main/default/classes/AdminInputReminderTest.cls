@isTest
public class AdminInputReminderTest {

    static User user1;
    
    @testSetup
    static void testSetUp(){
        Profile pf = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'];
        
        user1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'test2user1@example.com',
            ProfileId = UserInfo.getProfileId(), // Set user role
            Alias = 'tuser1',
            Username = 'test2u1ser21@example.com',
            CommunityNickname = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        insert user1;
    }
    
    @isTest
    static void testSchedulableExecution() {
        // Test the schedulable interface
        Test.startTest();
        
        String jobID = System.schedule('Opportunity So Reminder', '0 0 0 15 8 ?', new AdminInputReminder());
        
        // Wait for the scheduled job to be processed
        Test.stopTest();
        
        // Verify that the batch job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobID LIMIT 1];
        System.assertNotEquals(null, ct, 'The batch job should have been scheduled.');
    }
    
}