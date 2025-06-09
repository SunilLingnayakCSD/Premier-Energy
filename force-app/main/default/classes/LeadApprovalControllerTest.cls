@IsTest
public class LeadApprovalControllerTest {
    
    @TestSetup
    static void setupData() {
        // Create test Profiles
        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name IN (
            'Managing Director',
            'Government Projects Head -Modules',
            'System Administrator',
            'Chief Strategy Officer',
            'Government Projects - Solar Pumps 1',
            'Key Accounts National Head'
        )];
        
        Map<String, Id> profileMap = new Map<String, Id>();
        for (Profile prof : profiles) {
            profileMap.put(prof.Name, prof.Id);
        }
        
        // Create test Leads for various scenarios
        List<Lead> leads = new List<Lead>{
            new Lead(LastName='Lead MD', Company='Company A', Status='Tender Participation Request', Government_Project__c='Modules', Managing_Director_Approved__c=false, DCR_Non_DCR__c='DCR'),
            new Lead(LastName='Lead GPH Modules', Company='Company B', Status='Tender Participation Request', Government_Project__c='Modules', Managing_Director_Approved__c=true, DCR_Non_DCR__c='DCR'),
            new Lead(LastName='Lead CSO', Company='Company C', Status='Tender Participation Request', Government_Project__c='EPC', DCR_Non_DCR__c='DCR'),
            new Lead(LastName='Lead Solar Pumps', Company='Company D', Status='Tender Participation Request', Government_Project__c='Water Pumps', DCR_Non_DCR__c='DCR'),
            new Lead(LastName='Lead KA National', Company='Company E', Status='Pre_Qualification_Request', DCR_Non_DCR__c='DCR')
        };
        insert leads;
    }
    
    @IsTest
    static void testGetLeadsForManagingDirector() {
        Profile prof = [SELECT Id FROM Profile WHERE Name='Managing Director' LIMIT 1];
        User u = createTestUser(prof.Id);

        System.runAs(u) {
            Map<String, Object> result = LeadApprovalController.getLeads();
            System.assert(result.containsKey('leads'));
            System.assertEquals('Managing Director', result.get('userProfileName'));
        }
    }
    
    @IsTest
    static void testGetLeadsForGovtProjectsHeadModules() {
        Profile prof = [SELECT Id FROM Profile WHERE Name='Government Projects Head -Modules' LIMIT 1];
        User u = createTestUser(prof.Id);

        System.runAs(u) {
            Map<String, Object> result = LeadApprovalController.getLeads();
            System.assert(result.containsKey('leads'));
            System.assertEquals('Government Projects Head -Modules', result.get('userProfileName'));
        }
    }
    
    @IsTest
    static void testGetLeadsForSystemAdmin() {
        Profile prof = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User u = createTestUser(prof.Id);

        System.runAs(u) {
            Map<String, Object> result = LeadApprovalController.getLeads();
            System.assert(result.containsKey('leads'));
            System.assertEquals('System Administrator', result.get('userProfileName'));
        }
    }
    
    @IsTest
    static void testGetLeadsForCSO() {
        Profile prof = [SELECT Id FROM Profile WHERE Name='Chief Strategy Officer' LIMIT 1];
        User u = createTestUser(prof.Id);

        System.runAs(u) {
            Map<String, Object> result = LeadApprovalController.getLeads();
            System.assert(result.containsKey('leads'));
            System.assertEquals('Chief Strategy Officer', result.get('userProfileName'));
        }
    }
    
    @IsTest
    static void testGetLeadsForGovtProjectsSolarPumps() {
        Profile prof = [SELECT Id FROM Profile WHERE Name='Government Projects - Solar Pumps 1' LIMIT 1];
        User u = createTestUser(prof.Id);

        System.runAs(u) {
            Map<String, Object> result = LeadApprovalController.getLeads();
            System.assert(result.containsKey('leads'));
            System.assertEquals('Government Projects - Solar Pumps 1', result.get('userProfileName'));
        }
    }
    
    @IsTest
    static void testGetLeadsForKANationalHead() {
        Profile prof = [SELECT Id FROM Profile WHERE Name='Key Accounts National Head' LIMIT 1];
        User u = createTestUser(prof.Id);

        System.runAs(u) {
            Map<String, Object> result = LeadApprovalController.getLeads();
            System.assert(result.containsKey('leads'));
            System.assertEquals('Key Accounts National Head', result.get('userProfileName'));
        }
    }

    // Test method for updateLeadStatus method
    @IsTest
    static void testUpdateLeadStatusMethod() {
        // Create a lead for testing
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'Tender Participation Request',
            Government_Project__c = 'Modules',
            Managing_Director_Approved__c = false,
            DCR_Non_DCR__c = 'DCR'
        );
        insert testLead;

        Test.startTest();
        // Call method to set status as 'Rejected' with reason 'High Price'
        LeadApprovalController.updateLeadStatus(testLead.Id, 'Rejected', 'High Price', null);

        Lead updatedLead = [SELECT Id, Status, Reason_for_Rejection__c, Reason__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Rejected', updatedLead.Status);
        System.assertEquals('High Price', updatedLead.Reason_for_Rejection__c);
        System.assertEquals(null, updatedLead.Reason__c);

        // Call method again with 'Others' reason, and custom reason text
        LeadApprovalController.updateLeadStatus(testLead.Id, 'Rejected', 'Others', 'Competitor Offered Better Terms');

        updatedLead = [SELECT Id, Status, Reason_for_Rejection__c, Reason__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Others', updatedLead.Reason_for_Rejection__c);
        System.assertEquals('Competitor Offered Better Terms', updatedLead.Reason__c);

        // Call method to change status to 'Approved' and verify rejection reasons are cleared
        LeadApprovalController.updateLeadStatus(testLead.Id, 'Approved', null, null);

        updatedLead = [SELECT Id, Status, Reason_for_Rejection__c, Reason__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Approved', updatedLead.Status);
        System.assertEquals(null, updatedLead.Reason_for_Rejection__c);
        System.assertEquals(null, updatedLead.Reason__c);
        Test.stopTest();
    }

    // Utility method to create test User with unique username
    private static User createTestUser(Id profileId) {
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser' + String.valueOf(Datetime.now().getTime()) + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'testuser' + String.valueOf(Datetime.now().getTime()) + '@unique.com'
        );
        insert u;
        return u;
    }
}