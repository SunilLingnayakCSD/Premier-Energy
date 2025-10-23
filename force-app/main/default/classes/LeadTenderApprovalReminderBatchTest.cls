@isTest
public class LeadTenderApprovalReminderBatchTest {

    static User u1;

    @testSetup
    static void testSetUp() {
        // Use a real existing role, since you can't create roles in test context
        UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = 'East_Government_Projects_Regional_Manager' LIMIT 1];
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        u1 = new User(
            FirstName = 'Test', LastName = 'User1',
            Email = 'test1@example.com', Username = 'testuserprod1@example.com',
            Alias = 'tusr1', TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US', ProfileId = p.Id,
            UserRoleId = role.Id,
            CommunityNickname = 'testuser1'
        );
        insert u1;
    }

    @isTest
    static void testBatchExecution() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuserprod1@example.com' LIMIT 1];
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Government' AND SObjectType = 'Lead' LIMIT 1];

        Lead lead1 = new Lead(
            LastName = 'Lead1',
            Company = 'Company1',
            Status = 'Tender Participation Request',
            Region_Picklist__c = 'East',
            RecordTypeId = rt.Id,
            Tender_Number__c = 'TN001'
        );

        Lead lead2 = new Lead(
            LastName = 'Lead2',
            Company = 'Company2',
            Status = 'Tender Participation Request',
            Region_Picklist__c = 'East',
            RecordTypeId = rt.Id,
            Tender_Number__c = 'TN002'
        );

        insert new List<Lead>{lead1, lead2};

        // 👇 Reassign owner after insert, in case logic changes it elsewhere
        List<Lead> leadsToUpdate = [
            SELECT Id FROM Lead WHERE Tender_Number__c IN ('TN001', 'TN002')
        ];

        for (Lead l : leadsToUpdate) {
            l.OwnerId = testUser.Id;
        }
        update leadsToUpdate;

        Test.startTest();
        LeadTenderApprovalReminderBatch batch = new LeadTenderApprovalReminderBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String jobID = System.schedule(
            'Lead Tender Approval Reminder',
            '0 0 0 15 8 ?',
            new LeadTenderApprovalReminderBatch()
        );
        Test.stopTest();

        CronTrigger ct = [SELECT Id FROM CronTrigger WHERE Id = :jobID];
        System.assertNotEquals(null, ct);
    }
}