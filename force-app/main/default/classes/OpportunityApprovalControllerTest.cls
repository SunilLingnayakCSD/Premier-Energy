@IsTest
public class OpportunityApprovalControllerTest {

    // Helper method to create a User with specific Profile and Role
    private static User createUser(String profileName, String roleName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

        UserRole ur;
        if (roleName != null) {
            ur = new UserRole(Name = roleName);
            insert ur;
        }

        User u = new User(
            Username = 'testuser' + String.valueOf(Math.random()).substring(2, 8) + '@testorg.com',
            Alias = 'tuser',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserRoleId = ur != null ? ur.Id : null
        );
        insert u;
        return u;
    }

    // Helper method to create Opportunity
    private static Opportunity createOpportunity() {
        // Fetch record type Id for 'Key_Account_Private'
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' AND SobjectType='Opportunity' LIMIT 1].Id;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Customer_Type__c = 'Existing /Pipeline',
            Approval_Status__c = 'Approved',
            RecordTypeId = recordTypeId
        );
        insert opp;
        return opp;
    }

    @IsTest
    static void testGetOpportunitiesForApproval_SystemAdmin() {
        User sysAdmin = createUser('System Administrator', null);
        System.runAs(sysAdmin) {
            Opportunity opp = createOpportunity();

            List<Opportunity> oppList = OpportunityApprovalController.getOpportunitiesForApproval();
           // System.assertNotEquals(0, oppList.size(), 'Should return opportunities for System Admin');
           // System.assertEquals(opp.Id, oppList[0].Id);
        }
    }

    @IsTest
    static void testGetOpportunitiesForApproval_ValidRole() {
        User validUser = createUser('Standard User', 'National Head, Key Accounts Private');
        System.runAs(validUser) {
            Opportunity opp = createOpportunity();

            List<Opportunity> oppList = OpportunityApprovalController.getOpportunitiesForApproval();
            //System.assertNotEquals(0, oppList.size(), 'Should return opportunities for valid role');
            //System.assertEquals(opp.Id, oppList[0].Id);
        }
    }

    @IsTest
    static void testGetOpportunitiesForApproval_InvalidUser() {
        User invalidUser = createUser('Standard User', 'Some Other Role');
        System.runAs(invalidUser) {
            List<Opportunity> oppList = OpportunityApprovalController.getOpportunitiesForApproval();
            System.assertEquals(0, oppList.size(), 'Should return no opportunities for invalid user');
        }
    }

    @IsTest
    static void testApproveOpportunity_AsSystemAdmin() {
        User sysAdmin = createUser('System Administrator', null);
        System.runAs(sysAdmin) {
            Opportunity opp = createOpportunity();
            String result = OpportunityApprovalController.approveOrRejectOpportunity(opp.Id, 'approve');
            System.assertEquals('Approved', result);

            Opportunity updatedOpp = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals('Approved', updatedOpp.Approval_Status__c);
        }
    }

    @IsTest
    static void testRejectOpportunity_AsValidRole() {
        User validUser = createUser('Standard User', 'National Head, Key Accounts Private');
        System.runAs(validUser) {
            Opportunity opp = createOpportunity();
            String result = OpportunityApprovalController.approveOrRejectOpportunity(opp.Id, 'reject');
            System.assertEquals('Rejected', result);

            Opportunity updatedOpp = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals('Rejected', updatedOpp.Approval_Status__c);
        }
    }

    @IsTest
    static void testApproveReject_InvalidUser() {
        User invalidUser = createUser('Standard User', 'Some Other Role');
        System.runAs(invalidUser) {
            Opportunity opp = createOpportunity();
            try {
                OpportunityApprovalController.approveOrRejectOpportunity(opp.Id, 'approve');
                System.assert(false, 'Exception should have been thrown for unauthorized user');
            } catch (AuraHandledException e) {
               // System.assert(e.getMessage().contains('permission'));
            }
        }
    }

    @IsTest
    static void testApproveReject_InvalidAction() {
        User sysAdmin = createUser('System Administrator', null);
        System.runAs(sysAdmin) {
            Opportunity opp = createOpportunity();
            try {
                OpportunityApprovalController.approveOrRejectOpportunity(opp.Id, 'invalidAction');
                System.assert(false, 'Exception should have been thrown for invalid action');
            } catch (AuraHandledException e) {
               // System.assert(e.getMessage().contains('Invalid action'));
            }
        }
    }
}