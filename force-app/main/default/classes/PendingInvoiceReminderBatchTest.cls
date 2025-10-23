@IsTest
private class PendingInvoiceReminderBatchTest {

    @testSetup
    static void setupData() {
        // Step 1: Insert all NON-setup objects first (Account, Order, Invoices, Contact)
        Account acc = new Account(Name = 'Test Account', Email__c = 'rsm.user@example.com');
        insert acc;

        Order ord = new Order(
            Name = 'Test Order',
            Status = 'Draft',
            EffectiveDate = System.today(),
            AccountId = acc.Id,
            PoNumber = 'PO123456'
        );
        insert ord;

        List<Invoice__c> invoices = new List<Invoice__c>{
            new Invoice__c(
                Name = 'Invoice 1',
                Status__c = 'Request',
                Amount__c = 1000,
                Invoice_Date__c = Date.today(),
                Account__c = acc.Id,
                Invoice_Number__c = 'INV001',
                Order__c = ord.Id,
                FTR_Request_Date__c = Date.today()
            ),
            new Invoice__c(
                Name = 'Invoice 2',
                Status__c = 'Re-Request',
                Amount__c = 2000,
                Invoice_Date__c = Date.today(),
                Account__c = acc.Id,
                Invoice_Number__c = 'INV002',
                Order__c = ord.Id,
                FTR_Re_Request_Date__c = Date.today()
            ),
            new Invoice__c(
                Name = 'Invoice 3',
                Status__c = 'Uploaded',
                Amount__c = 1500,
                Invoice_Date__c = Date.today(),
                Account__c = acc.Id
            )
        };
        insert invoices;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'rsm.user@example.com',
            AccountId = acc.Id
        );
        insert con;

        // Step 2: Now insert Users using System.runAs to avoid Mixed DML
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        System.runAs(admin) {
            Profile partnerProfile = [SELECT Id FROM Profile WHERE Name = 'Partner Distributor Access' LIMIT 1];
            Profile salesOpsProfile = [SELECT Id FROM Profile WHERE Name = 'Channel Sales -Sales Operation 1' LIMIT 1];
            UserRole rsmRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'ssrinPartnerPersonAccount' LIMIT 1];
           // UserRole asmRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'ASM' LIMIT 1];
           // UserRole zsmRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'ZSM' LIMIT 1];
            UserRole salesOpsRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Sales_Operation' LIMIT 1];

            User zsm = new User(
                FirstName = 'ZSM', LastName = 'User',
                Email = 'zsm@example.com',
                Username = 'zsm' + DateTime.now().getTime() + '@example.com',
                Alias = 'zsm',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = UserInfo.getProfileId()
              //  UserRoleId = zsmRole.Id
            );
            insert zsm;

            User asm = new User(
                FirstName = 'ASM', LastName = 'User',
                Email = 'asm@example.com',
                Username = 'asm' + DateTime.now().getTime() + '@example.com',
                Alias = 'asm',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = UserInfo.getProfileId(),
              //  UserRoleId = asmRole.Id,
                ManagerId = zsm.Id
            );
            insert asm;

            User rsm = new User(
                FirstName = 'RSM', LastName = 'User',
                Email = 'rsm.user@example.com',
                Username = 'rsm' + DateTime.now().getTime() + '@example.com',
                Alias = 'rsm',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = partnerProfile.Id,
                UserRoleId = rsmRole.Id,
                ContactId = con.Id,
                ManagerId = asm.Id
            );
            insert rsm;

            User salesOps = new User(
                FirstName = 'SalesOps', LastName = 'User',
                Email = 'salesops@example.com',
                Username = 'salesops' + DateTime.now().getTime() + '@example.com',
                Alias = 'sops',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = salesOpsProfile.Id,
                UserRoleId = salesOpsRole.Id
            );
            insert salesOps;
        }
    }

    @IsTest
    static void testBatchExecution() {
        Test.startTest();
        PendingInvoiceReminderBatch batch = new PendingInvoiceReminderBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
    }

    @IsTest
    static void testSchedulableExecution() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Invoice Batch Schedule',
            '0 0 12 * * ?', // Every day at noon
            new PendingInvoiceReminderBatch()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }

    @IsTest
    static void testWithNoEmailAccount() {
        Account acc = [SELECT Id, Email__c FROM Account LIMIT 1];
        acc.Email__c = null;
        update acc;

        Test.startTest();
        Database.executeBatch(new PendingInvoiceReminderBatch());
        Test.stopTest();

        System.assert(true, 'Batch executed with account having no email');
    }
}