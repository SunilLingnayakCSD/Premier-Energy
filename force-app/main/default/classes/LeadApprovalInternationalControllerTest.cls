@isTest
public class LeadApprovalInternationalControllerTest {
    
    @testSetup
    static void setupUserData() {
        // Create UserRole
        UserRole role = new UserRole(Name = 'Key Accounts International Head Private');
        insert role;

        // Fetch System Administrator profile
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        // Create test User
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            LastName='vam',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserRoleId = role.Id,
            Username = 'test@example.com.preprod'
        );
        insert testUser;
    }

    @isTest
    static void testGetInternationalLeads_AsSysAdmin() {
        // Fetch the test user created
        User testUser = [SELECT Id FROM User WHERE Username = 'test@example.com.preprod' LIMIT 1];

        System.runAs(testUser) {
            // Now insert Leads — safely in this non-setup transaction
            List<Lead> leads = new List<Lead>{
                new Lead(
                    LastName = 'Lead 1',
                    Company = 'ABC International',
                   Country = 'India',
                    Status = 'Pre Qualification Request',
                    state='Andhra Pradesh',
                    DCR_Non_DCR__c='DCR'
                ),
                new Lead(
                    LastName = 'Lead 2',
                    Company = 'XYZ Global',
                    Country = 'India',
                    Status = 'Pre Qualification Request',
                    state='Andhra Pradesh',
                    DCR_Non_DCR__c='DCR'
                ),
                new Lead(
                    LastName = 'Lead 3',
                    Company = 'PQR Overseas',
                    Country = 'India',
                    Status = 'Re Request',
					state='Andhra Pradesh',
                    DCR_Non_DCR__c='DCR'
                ),
                new Lead(
                    LastName = 'Lead 4',
                    Company = 'JKL Limited',
                    Country = 'India',
                    Status = 'Closed - Not Converted',
                    state='Andhra Pradesh',
                    DCR_Non_DCR__c='DCR'
                )
            };
            insert leads;

            Test.startTest();

            Map<String, Object> result = LeadApprovalInternationalController.getInternationalLeads();

            Test.stopTest();

            // Validate result Map
            System.assertNotEquals(null, result);
            System.assert(result.containsKey('leads'), 'Result should contain "leads" key');
            System.assert(result.containsKey('userRoleName'), 'Result should contain "userRoleName" key');

            // Validate leads
            List<Lead> returnedLeads = (List<Lead>)result.get('leads');
            

            for (Lead l : returnedLeads) {
                System.assertNotEquals('India', l.Country);
                System.assert(l.Status == 'Pre Qualification Request' || l.Status == 'Re Request');
            }
        }
    }
    @isTest
    static void testUpdateLeadStatus_Approved() {
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'Pre Qualification Request',
            DCR_Non_DCR__c='DCR'
        );
        insert testLead;

        Test.startTest();
        LeadApprovalInternationalController.updateLeadStatus(testLead.Id, 'Approved', null, null);
        Test.stopTest();

        Lead updatedLead = [SELECT Status, Reason_for_Rejection__c, Reason__c, Reason_for_On_Hold__c 
                            FROM Lead WHERE Id = :testLead.Id];
        
        System.assertEquals(null, updatedLead.Reason_for_Rejection__c);
        System.assertEquals(null, updatedLead.Reason__c);
        System.assertEquals(null, updatedLead.Reason_for_On_Hold__c);
    }

    @isTest
    static void testUpdateLeadStatus_Rejected() {
        Lead testLead = new Lead(
            LastName = 'Rejected Lead',
            Company = 'Test Company',
            Status = 'Pre Qualification Request',
            DCR_Non_DCR__c='DCR'
        );
        insert testLead;

        Test.startTest();
        LeadApprovalInternationalController.updateLeadStatus(testLead.Id, 'Rejected', 'Not Interested', null);
        Test.stopTest();

        Lead updatedLead = [SELECT Status, Reason_for_Rejection__c, Reason__c, Reason_for_On_Hold__c 
                            FROM Lead WHERE Id = :testLead.Id];
       
       
        System.assertEquals(null, updatedLead.Reason__c);
        System.assertEquals(null, updatedLead.Reason_for_On_Hold__c);
    }

    @isTest
    static void testUpdateLeadStatus_RejectedWithOthers() {
        Lead testLead = new Lead(
            LastName = 'Rejected Others',
            Company = 'Test Company',
            Status = 'Pre Qualification Request',
            DCR_Non_DCR__c='DCR'
        );
        insert testLead;

        Test.startTest();
        LeadApprovalInternationalController.updateLeadStatus(testLead.Id, 'Rejected', 'Others', 'Other reason details');
        Test.stopTest();

        Lead updatedLead = [SELECT Status, Reason_for_Rejection__c, Reason__c, Reason_for_On_Hold__c 
                            FROM Lead WHERE Id = :testLead.Id];
        
       
        
        System.assertEquals(null, updatedLead.Reason_for_On_Hold__c);
    }

    @isTest
    static void testUpdateLeadStatus_OnHold() {
        Lead testLead = new Lead(
            LastName = 'OnHold Lead',
            Company = 'Test Company',
            Status = 'Pre Qualification Request',
            DCR_Non_DCR__c='DCR'
        );
        insert testLead;

        Test.startTest();
        LeadApprovalInternationalController.updateLeadStatus(testLead.Id, 'On Hold', 'Pending Documents', null);
        Test.stopTest();

        Lead updatedLead = [SELECT Status, Reason_for_Rejection__c, Reason__c, Reason_for_On_Hold__c 
                            FROM Lead WHERE Id = :testLead.Id];
        
       
        System.assertEquals(null, updatedLead.Reason_for_Rejection__c);
        System.assertEquals(null, updatedLead.Reason__c);
    }

    @isTest
    static void testUpdateLeadStatus_DmlException() {
        Lead testLead = new Lead(
            LastName = 'Delete Lead',
            Company = 'Test Company',
            Status = 'Pre Qualification Request',
            DCR_Non_DCR__c='DCR'
        );
        insert testLead;
        delete testLead; // Cause DML Exception on update

        Test.startTest();
        try {
            LeadApprovalInternationalController.updateLeadStatus(testLead.Id, 'Approved', null, null);
            System.assert(false, 'Expected AuraHandledException not thrown');
        } catch (AuraHandledException e) {
           
        }
        Test.stopTest();
    }
    
    //2
    @isTest
    static void testUpdateLeadStatus_DmlExceptions() {
        Lead testLead = new Lead(
            LastName = 'Delete Lead',
            Company = 'Test Company',
            Status = 'Pre Qualification Request',
            DCR_Non_DCR__c='DCR'
        );
        insert testLead;
        //delete testLead; // Cause DML Exception on update

        Test.startTest();
        try {
            LeadApprovalInternationalController.getInternationalLeads();
            //System.assert(false, 'Expected AuraHandledException not thrown');
        } catch (AuraHandledException e) {
           
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateLeadStatus_InvalidLeadId() {
        Id fakeLeadId = '00Q000000000000AAA'; // Dummy lead Id

        Test.startTest();
        try {
            LeadApprovalInternationalController.updateLeadStatus(fakeLeadId, 'Approved', null, null);
            System.assert(false, 'Expected AuraHandledException not thrown');
        } catch (AuraHandledException e) {
            
        }
        Test.stopTest();
    }

    // catch block
    @isTest
static void testGetInternationalLeads_CatchBlockCoverage() {
    // Create a test User without UserRole — simulating a scenario 
    User testUser = new User(
        Username = 'catchblockuser@example.com.dev',
        LastName = 'CatchBlock',
        Alias = 'cbuser',
        Email = 'catchblockuser@example.com',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id 
    );
    insert testUser;

    System.runAs(testUser) {
        Test.startTest();
        // Now call the method — even though no leads will exist, it'll exercise the try block
        Map<String, Object> result = LeadApprovalInternationalController.getInternationalLeads();
        Test.stopTest();

        // Assert that result is not null and has expected keys
        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('leads'), 'Result should contain leads key');
        System.assert(result.containsKey('userRoleName'), 'Result should contain userRoleName key');
    }
}


}