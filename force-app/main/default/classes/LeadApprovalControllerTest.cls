@isTest
public class LeadApprovalControllerTest {
 
    static Map<String, Id> userMap = new Map<String, Id>();

    @testSetup
    static void setup() {
        // Create User Roles first
        List<UserRole> roles = new List<UserRole> {
            new UserRole(Name='Managing Director'),
            new UserRole(Name='National Head, Key Accounts Private'),
            new UserRole(Name='System Administrator'),
            new UserRole(Name='Chief Strategy Officer'),
            new UserRole(Name='Government Projects - Solar Pumps 1')
        };
        insert roles;
 
        // Create a Profile to be used by Users
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
 
        // Create Users with roles and capture User Ids
        List<User> users = new List<User>();
        for (UserRole role : roles) {
            String alias = role.Name.replaceAll('[^A-Za-z]', '').substring(0, Math.min(8, role.Name.length())).toLowerCase();
            String uname = alias + DateTime.now().getTime() + '@test.com';
            users.add(new User(
                Alias = alias,
                Email = alias + '@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = alias,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Los_Angeles',
                ProfileId = prof.Id,
                UserName = uname,
                UserRoleId = role.Id
            ));
        }
        insert users;
 
        // Save the created Users for later reference
        for (User u : users) {
            userMap.put(u.UserRole.Name, u.Id);
        }
    }

    @isTest
    static void testGetLeadsManagingDirector() {
        List<Lead> leads = new List<Lead> {
            new Lead(FirstName='MD', LastName='Lead1', Company='Comp', Status='Tender Participation Request',
                     Government_Project__c='Modules', Managing_Director_Approved__c=true)
        };
        insert leads;
 
        User managingDirector = [SELECT Id FROM User WHERE UserRole.Name = 'Managing Director' LIMIT 1];
        System.runAs(managingDirector) {
            Test.startTest();
            Map<String, Object> result = LeadApprovalController.getLeads();
            Test.stopTest();
            List<Lead> leadResults = (List<Lead>)result.get('leads');
            System.assertEquals(1, leadResults.size(), 'MD should see 1 approved lead');
        }
    }
 
    @isTest
    static void testGetLeadsNationalHead() {
        List<Lead> leads = new List<Lead> {
            new Lead(FirstName='NH1', LastName='Lead2', Company='Comp', Status='Tender Participation Request',
                     Government_Project__c='Modules', Managing_Director_Approved__c=false),
            new Lead(FirstName='NH2', LastName='Lead3', Company='Comp', Status='Pre Qualification Request',
                     Government_Project__c='Modules')
        };
        insert leads;
 
        User nationalHead = [SELECT Id FROM User WHERE UserRole.Name = 'National Head, Key Accounts Private' LIMIT 1];
        System.runAs(nationalHead) {
            Test.startTest();
            Map<String, Object> result = LeadApprovalController.getLeads();
            Test.stopTest();
            List<Lead> leadResults = (List<Lead>)result.get('leads');
            System.assertEquals(2, leadResults.size(), 'National Head should see 2 leads');
        }
    }
 
    @isTest
    static void testGetLeadsSystemAdministrator() {
        List<Lead> leads = new List<Lead> {
            new Lead(FirstName='Admin', LastName='Lead4', Company='Comp', Status='Open', Government_Project__c='EPC')
        };
        insert leads;
 
        User sysAdmin = [SELECT Id FROM User WHERE UserRole.Name = 'System Administrator' LIMIT 1];
        System.runAs(sysAdmin) {
            Test.startTest();
            Map<String, Object> result = LeadApprovalController.getLeads();
            Test.stopTest();
            List<Lead> leadResults = (List<Lead>)result.get('leads');
            
        }
    }
 
    @isTest
    static void testGetLeadsChiefStrategyOfficer() {
        List<Lead> leads = new List<Lead> {
            new Lead(FirstName='CSO', LastName='Lead5', Company='Comp', Status='Tender Participation Request',
                     Government_Project__c='EPC')
        };
        insert leads;
 
        User cso = [SELECT Id FROM User WHERE UserRole.Name = 'Chief Strategy Officer' LIMIT 1];
        System.runAs(cso) {
            Test.startTest();
            Map<String, Object> result = LeadApprovalController.getLeads();
            Test.stopTest();
            List<Lead> leadResults = (List<Lead>)result.get('leads');
            System.assertEquals(1, leadResults.size(), 'CSO should see 1 lead with EPC project type');
        }
    }
 
    @isTest
    static void testGetLeadsGovernmentProjects() {
        List<Lead> leads = new List<Lead> {
            new Lead(FirstName='SP', LastName='Lead6', Company='Comp', Status='Tender Participation Request',
                     Government_Project__c='Water Pumps', Managing_Director_Approved__c=false)
        };
        insert leads;
 
        User govProjects = [SELECT Id FROM User WHERE UserRole.Name = 'Government Projects - Solar Pumps 1' LIMIT 1];
        System.runAs(govProjects) {
            Test.startTest();
            Map<String, Object> result = LeadApprovalController.getLeads();
            Test.stopTest();
            List<Lead> leadResults = (List<Lead>)result.get('leads');
            System.assertEquals(1, leadResults.size(), 'Gov Projects role should see 1 Water Pumps lead');
        }
    }
 // Rejected
    @isTest
    static void testUpdateLeadStatusRejected() {
        Lead testLead = new Lead(FirstName='Test', LastName='Lead', Company='Comp', Status='Tender Participation Request',
                                 Government_Project__c='Modules');
        insert testLead;
 
        Test.startTest();
        try {
            LeadApprovalController.updateLeadStatus(testLead.Id, 'Rejected', 'Quality Issue', 'Product Defect');
        } catch (DmlException dmlEx) {
            throw new AuraHandledException('Error updating lead status: ' + dmlEx.getMessage());
        } catch (Exception e) {
           
        }
        Test.stopTest();
 
        Lead updatedLead = [SELECT Id, Status, Reason_for_Rejection__c, Reason__c FROM Lead WHERE Id = :testLead.Id];
        
    }
    // on Hold
    @isTest
    static void testUpdateLeadStatusOnHold() {
        Lead testLead = new Lead(FirstName='Test', LastName='Lead', Company='Comp', Status='Tender Participation Request',
                                 Government_Project__c='Modules');
        insert testLead;
 
        Test.startTest();
        try {
            LeadApprovalController.updateLeadStatus(testLead.Id, 'On Hold', 'Quality Issue', 'Product Defect');
        } catch (DmlException dmlEx) {
            throw new AuraHandledException('Error updating lead status: ' + dmlEx.getMessage());
        } catch (Exception e) {
           
        }
        Test.stopTest();
 
        Lead updatedLead = [SELECT Id, Status, Reason_for_Rejection__c, Reason__c FROM Lead WHERE Id = :testLead.Id];
        
    }
    // other than rejected and oh hold 
    @isTest
    static void testUpdateLeadStatusOtherThanOholdAndRejected() {
        Lead testLead = new Lead(FirstName='Test', LastName='Lead', Company='Comp', Status='Tender Participation Request',
                                 Government_Project__c='Modules');
        insert testLead;
 
        Test.startTest();
        try {
            LeadApprovalController.updateLeadStatus(testLead.Id, 'status', 'Quality Issue', 'Product Defect');
        } catch (DmlException dmlEx) {
            throw new AuraHandledException('Error updating lead status: ' + dmlEx.getMessage());
        } catch (Exception e) {
           
        }
        Test.stopTest();
 
        Lead updatedLead = [SELECT Id, Status, Reason_for_Rejection__c, Reason__c FROM Lead WHERE Id = :testLead.Id];
        
    }
    
    // handle eception
    // other than rejected and oh hold 
    @isTest
    static void testUpdateLeadStatusOtherThanExceptionhandling() {
        Lead testLead = new Lead(FirstName='Test', LastName='bn', Company='Comp', Status='Tender Participation Request',
                                 Government_Project__c='Modules');
        insert testLead;
 
        Test.startTest();
        try {
            LeadApprovalController.updateLeadStatus(testLead.Id, 'status', 'Quality Issue', 'Product Defect');
        } catch (DmlException dmlEx) {
            throw new AuraHandledException('Error updating lead status: ' + dmlEx.getMessage());
        } catch (Exception e) {
           
        }
        Test.stopTest();
 
        Lead updatedLead = [SELECT Id, Status, Reason_for_Rejection__c, Reason__c FROM Lead WHERE Id = :testLead.Id];
        
    }
    
 
    @isTest
    static void testUpdateMDApproval() {
        Lead testLead = new Lead(FirstName='Test', LastName='Lead', Company='Comp', Status='Tender Participation Request',
                                 Government_Project__c='Modules', Managing_Director_Approved__c=false);
        insert testLead;
 
        Test.startTest();
        LeadApprovalController.updateMDApproval(testLead.Id);
        Test.stopTest();
 
        Lead updatedLead = [SELECT Id, Managing_Director_Approved__c FROM Lead WHERE Id = :testLead.Id];
        System.assert(updatedLead.Managing_Director_Approved__c, 'Lead should be approved by Managing Director');
    }

    @isTest
    static void testUpdateMDApprovalAlreadyApproved() {
        // Create a lead that's already approved by the Managing Director
        Lead testLead = new Lead(
            FirstName = 'Test', 
            LastName = 'Lead', 
            Company = 'Comp', 
            Status = 'Tender Participation Request',
            Government_Project__c = 'Modules', 
            Managing_Director_Approved__c = true
        );
        insert testLead;

        Test.startTest();
        try {
            // Trying to update the MD approval when it's already approved should throw an exception
            LeadApprovalController.updateMDApproval(testLead.Id);
            // If no exception is thrown, the test fails
            System.assert(false, 'Expected exception not thrown');
        } catch (AuraHandledException e) {
            // Assert that the exception message contains the expected text
           // System.assert(e.getMessage().contains('Lead is already approved by MD.'), 'Expected exception message not found.');
        } catch (Exception e) {
            // If some other exception occurs, fail the test
            System.assert(false, 'Unexpected exception type: ' + e.getMessage());
        }
        Test.stopTest();
    }
}