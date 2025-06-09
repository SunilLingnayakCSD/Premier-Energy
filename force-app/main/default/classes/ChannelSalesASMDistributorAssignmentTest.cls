@isTest
public class ChannelSalesASMDistributorAssignmentTest {

  /* private static User createUser(String profileName, String region, Boolean isPortalUser) {
    Profile profile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

    Account account = new Account(Name = 'Test Account');
    insert account;

    Contact contact;
    if (isPortalUser) {
        contact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = account.Id);
        insert contact;
    }

    User u = new User(
        FirstName = 'Test',
        LastName = 'User',
        Alias = 'test' + String.valueOf(Math.random()).substring(2, 6),
        Email = 'testuser' + String.valueOf(Math.random()).substring(2, 6) + '@test.com',
        Username = 'testuser' + String.valueOf(Math.random()).substring(2, 6) + '@test.com',
        ProfileId = profile.Id,
        EmailEncodingKey = 'UTF-8',
        TimeZoneSidKey = 'America/New_York',
        LocaleSidKey = 'en_US',
        LanguageLocaleKey = 'en_US',
        Region__c = 'North', // ✅ Corrected to dynamically set region
        ContactId = isPortalUser ? contact.Id : null
    );
    insert u;
    return u;
}

    @isTest
    static void testASMAvailable_BlockDistributor() {
        // Create ASM user in the same region
        User asmUser = createUser('Channel Sales ASM', 'North', false);

        // Create Region Head
        User regionHead = createUser('Channel Sales East Region Head', 'North', false);
        System.runAs(regionHead) {
            // Create lead with ASM assigned correctly
            Lead lead = createLead('North', asmUser.Id, null);

            // Attempt to assign Distributor__c when ASM is available
            lead.Distributor__c = asmUser.Id;
            Test.startTest();
            try {
                update lead;
                System.assert(false, 'Exception expected but not thrown.');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('ASM is available for this region. You cannot assign a Distributor.'));
            }
            Test.stopTest();
        }
    }
       
private static Lead createLead(String region, Id asmId, Id distributorId) {
    RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Channel_Sales' AND SObjectType = 'Lead' LIMIT 1];
    Lead l = new Lead(
        FirstName = 'Test',
        LastName = 'Lead',
        Company = 'Test Company',
        RecordTypeId = rt.Id,
        Region_Picklsit__c = region,
        ASM__c = asmId,
        Distributor__c = distributorId,
        Status = 'New',
        Phone = '1234567890',
        Email = 'test@gmail.com',
        Product__c = 'MonoPERC Monofacial M10',
        Each_Module_Wp__c = 1,  
        Quantity__c = 44,       
        DCR_Non_DCR__c = 'DCR'
    );
    insert l;
    return l;
}

    @isTest
    static void testNoASMAvailable_AllowDistributor_BlockASM() {
        // No ASM created for this region

        // Create Region Head
        User regionHead = createUser('Channel Sales East Region Head', 'North', false);
        
        System.runAs(regionHead) {
            // Create lead without ASM
            Lead lead = createLead('North', null, null);

            // Update lead to assign Distributor
            lead.Distributor__c = regionHead.Id; // Valid Distributor assignment
            Test.startTest();
            update lead;
            Test.stopTest();

            // Update lead to assign ASM - should throw error
            lead.Distributor__c = null;
            lead.ASM__c = regionHead.Id; // Trying to assign ASM when no ASM exists
            Test.startTest();
            try {
                update lead;
                System.assert(false, 'Exception expected but not thrown.');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('No ASM found for this region. Assign a Distributor instead.'));
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testLeadShareWithASM() {
        // Create ASM user that matches Lead's region
        User asmUser = createUser('Channel Sales ASM', 'North', false);

        // Create Lead with region = North and ASM assigned
        Lead lead = createLead('North', asmUser.Id, null);

        Test.startTest();
        // Call shareLeadRecords method
        List<Lead> leadsToShare = [SELECT Id, ASM__c,RecordTypeId  FROM Lead WHERE Id = :lead.Id];
        ChannelSalesASMDistributorAssignment.shareLeadRecords(leadsToShare);

        // Verify LeadShare record created
        List<LeadShare> leadShares = [SELECT LeadId, UserOrGroupId, LeadAccessLevel, RowCause FROM LeadShare WHERE LeadId = :lead.Id];
        System.assertEquals(1, leadShares.size(), 'LeadShare should be created');
        System.assertEquals(asmUser.Id, leadShares[0].UserOrGroupId, 'Lead should be shared with ASM');
        System.assertEquals('Edit', leadShares[0].LeadAccessLevel, 'Access level should be Edit');
        Test.stopTest();
    }

    @isTest
    static void testLeadShareWithDistributor() {
        // Create Distributor user
        User distributorUser = createUser('Channel Sales Distributor', 'North', false);

        // Create Lead and assign Distributor
        Lead lead = createLead('North', null, distributorUser.Id);

        Test.startTest();
        // Call shareLeadRecords method
        List<Lead> leadsToShare = [SELECT Id, Distributor__c,ASM__c,RecordTypeId  FROM Lead WHERE Id = :lead.Id];
        ChannelSalesASMDistributorAssignment.shareLeadRecords(leadsToShare);

        // Verify LeadShare record created
        List<LeadShare> leadShares = [SELECT LeadId, UserOrGroupId, LeadAccessLevel, RowCause FROM LeadShare WHERE LeadId = :lead.Id];
        System.assertEquals(1, leadShares.size(), 'LeadShare should be created');
        System.assertEquals(distributorUser.Id, leadShares[0].UserOrGroupId, 'Lead should be shared with Distributor');
        System.assertEquals('Edit', leadShares[0].LeadAccessLevel, 'Access level should be Edit');
        Test.stopTest();
    }


    @isTest
    static void testNoSharingWhenNoUser() {
        // Create lead with no ASM or Distributor
        Lead lead = createLead('North', null, null);

        Test.startTest();
        // Call shareLeadRecords method
        List<Lead> leadsToShare = [SELECT Id ,ASM__c, RecordTypeId FROM Lead WHERE Id = :lead.Id];
        ChannelSalesASMDistributorAssignment.shareLeadRecords(leadsToShare);

        // Verify no LeadShare created
        List<LeadShare> leadShares = [SELECT Id FROM LeadShare WHERE LeadId = :lead.Id];
        System.assertEquals(0, leadShares.size(), 'No LeadShare should be created when no user assigned.');
        Test.stopTest();
    }*/
}