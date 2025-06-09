public without sharing class LeadConvertion {
    @InvocableMethod
    public static void convertLeads(List<Id> leadIds) {
        List<Lead> leads = [
            SELECT Id, Company, FirstName, LastName, Email, OwnerId,LeadSource,Product_Type_KAPOrChannelSales__c,
                   Customer_Registered_Country__c, Customer_Registered_State__c,Project_Capacity__c,
                   Customer_Registered_City__c, Customer_Registered_Pincode__c,Lead_Capacity__c,
                   DCR_Non_DCR__c, Delivery_required_by__c, Domestic_Exports__c,Wattage_Wp_Cell_Module__c,
                   Plant_Name__c, Premier_Business_Entity__c, product__c, Street,Enquiry_or_RFQ_Documents__c,
                   Total_Capacity_in_MWp__c, RecordType.DeveloperName, City, Country, PostalCode,
                   Lead_Regional_Head_Email__c, Region_Picklist__c, Segment__c, State, Phone,Region_Customer_Operation__c
            FROM Lead WHERE Id IN :leadIds
        ];
 
        List<Database.LeadConvert> conversions = new List<Database.LeadConvert>();
        Map<Id, Opportunity> leadIdToOpportunity = new Map<Id, Opportunity>();
 
        List<Account> accountsToInsert = new List<Account>();
        Map<Id, Id> leadToNewAccountId = new Map<Id, Id>();
 
        List<Contact> contactsToInsert = new List<Contact>();
        Map<Id, Id> leadToNewContactId = new Map<Id, Id>();
 
        // Opportunity RecordTypes
        Map<String, Id> oppRecordTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Opportunity']) {
            oppRecordTypeMap.put(rt.DeveloperName, rt.Id);
        }
 
        // Account RecordType - 'Customer'
        Id customerAccRT = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Account' AND DeveloperName = 'Customer' LIMIT 1
        ].Id;
 
        // Get existing Accounts and Contacts
        Set<String> companyNames = new Set<String>();
        for (Lead ld : leads) {
            if (String.isNotBlank(ld.Company)) {
                companyNames.add(ld.Company);
            }
        }
        System.debug('companyNames--> '+ companyNames);
 
        Map<String, Account> companyToAccount = new Map<String, Account>();
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
 
        if (!companyNames.isEmpty()) {
            for (Account acc : [
                SELECT Id, Name, (SELECT Id, Email FROM Contacts ORDER BY CreatedDate DESC LIMIT 1) 
                FROM Account WHERE Name IN :companyNames
            ]) {
                companyToAccount.put(acc.Name, acc);
                System.debug('companyToAccount-->'+companyToAccount);
                if (!acc.Contacts.isEmpty()) {
                    accountIdToContact.put(acc.Id, acc.Contacts[0]);
                }
            }
        }
 
        // Step 1: Build new Accounts and Contacts where needed
        for (Lead ld : leads) {
            if (String.isNotBlank(ld.Company) && !companyToAccount.containsKey(ld.Company)) {
                System.debug('Acc insertion check');
                Account newAcc = new Account(
                    Name = ld.Company,
                    OwnerId = ld.OwnerId,
                    Plant_Name__c = ld.Plant_Name__c,
                    BillingCity = ld.City,
                    BillingCountry = ld.Country,
                    BillingPostalCode = ld.PostalCode,
                    BillingState = ld.State,
                    BillingStreet = ld.Street,
                    Phone = ld.Phone,
                    AccountSource = ld.LeadSource,
                    Premier_Business_Entity__c = ld.Premier_Business_Entity__c,
                    RecordTypeId = customerAccRT,
                    Total_Capacity_in_MWp__c = ld.Total_Capacity_in_MWp__c
                );
                accountsToInsert.add(newAcc);
                leadToNewAccountId.put(ld.Id, null); // Will assign after insert
            }
        }
 
        // Step 2: Insert Accounts
        if (!accountsToInsert.isEmpty()) {
            insert accountsToInsert;
 
            Integer i = 0;
            for (Lead ld : leads) {
                if (leadToNewAccountId.containsKey(ld.Id)) {
                    leadToNewAccountId.put(ld.Id, accountsToInsert[i].Id);
                    companyToAccount.put(ld.Company, accountsToInsert[i]);
                    i++;
                }
            }
        }
 
        // Step 3: Create missing Contacts
        for (Lead ld : leads) {
            Account acc = companyToAccount.get(ld.Company);
            if (acc != null && !accountIdToContact.containsKey(acc.Id)) {
                Contact con = new Contact(
                    FirstName = ld.FirstName,
                    LastName = ld.LastName,
                    Email = ld.Email,
                    MailingCity = ld.Customer_Registered_City__c,
                    AccountId = acc.Id,
                    OwnerId = ld.OwnerId,
                    LeadSource = ld.LeadSource
                );
                contactsToInsert.add(con);
                leadToNewContactId.put(ld.Id, null); // Placeholder
            }
        }
 
        // Step 4: Insert Contacts
        if (!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
            System.debug('contactsToInsert--> '+ contactsToInsert);
 
            Integer j = 0;
            for (Lead ld : leads) {
                if (leadToNewContactId.containsKey(ld.Id)) {
                    leadToNewContactId.put(ld.Id, contactsToInsert[j].Id);
                    System.debug('LeadSource in Contact--> '+ contactsToInsert[j].LeadSource);
                    j++;
                }
            }
        }
 
        // Step 5: Prepare LeadConversion and Opportunities
        for (Lead ld : leads) {
            Account acc = companyToAccount.get(ld.Company);
            Contact con = null;
            if (acc != null && accountIdToContact.containsKey(acc.Id)) {
                con = accountIdToContact.get(acc.Id);
            } else if (leadToNewContactId.containsKey(ld.Id)) {
                con = [SELECT Id,LeadSource FROM Contact WHERE Id = :leadToNewContactId.get(ld.Id) LIMIT 1];
            }
 
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(ld.Id);
            lc.setConvertedStatus('Converted');
            lc.setDoNotCreateOpportunity(true);
 
            if (acc != null) lc.setAccountId(acc.Id);
            if (con != null) lc.setContactId(con.Id);
 
            conversions.add(lc);
            //System.debug('LeadSource--> Contact -- '+ con.LeadSource);
 
            // Opportunity
            Opportunity opp = new Opportunity(
                Name = ld.Lead_Capacity__c,
                AccountId = acc != null ? acc.Id : null,
                ContactId = con != null ? con.Id : null,
                Customer_Name__c = ld.Lead_Capacity__c,
                CloseDate = Date.today().addDays(30),
                StageName = ld.RecordType.DeveloperName == 'Key_Account_Government'? 'Contract Agreement': 'RFQ/Enquiry',
                Customer_Registered_Address__c = String.join(new List<String>{
                    ld.Customer_Registered_Country__c, ld.Customer_Registered_State__c,
                    ld.Customer_Registered_City__c, ld.Customer_Registered_Pincode__c
                }, ' ').trim(),
                DCR_Non_DCR__c = ld.DCR_Non_DCR__c,
                LeadSource = ld.LeadSource,
                Enquiry_or_RFQ_Documents__c = ld.Enquiry_or_RFQ_Documents__c,
                Delivery_Required_by__c = ld.Delivery_required_by__c,
                Domestic_Exports__c = ld.Domestic_Exports__c,
                OwnerId = ld.OwnerId,
                Plant_Name__c = ld.Plant_Name__c,
                Premier_Business_Entity__c = ld.Premier_Business_Entity__c,
                Product_Details__c = ld.product__c,
                Project_capacity_in_MWp_including_Spare__c = ld.Project_Capacity__c,
                RecordTypeId = oppRecordTypeMap.get(ld.RecordType.DeveloperName),
                Region_Head_Email__c = ld.Lead_Regional_Head_Email__c,
                Region__c = ld.Region_Picklist__c,
                Segment__c = ld.Segment__c,
                Product_Category__c = ld.Product_Type_KAPOrChannelSales__c,
                Region_Customer_Operation__c = ld.Region_Customer_Operation__c,
                Wattage_Wp_Cell_Module_UAT__c = ld.Wattage_Wp_Cell_Module__c,
                Project_Capacity_in_MWp__c = ld.Project_Capacity__c,
                Product_Details_Technology_Type__c = ld.Product__c,
                Customer_Type__c = 'New'
            );
            System.debug('AccountId--> '+ opp.AccountId);
 
            leadIdToOpportunity.put(ld.Id, opp);
            System.debug('Opp Stage--> '+ opp.StageName);
        }
 
        // Step 6: Convert leads
        List<Database.LeadConvertResult> results = Database.convertLead(conversions);
 
        // Step 7: Insert Opportunities
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        for (Database.LeadConvertResult result : results) {
            if (result.isSuccess() && leadIdToOpportunity.containsKey(result.getLeadId())) {
                Opportunity opp = leadIdToOpportunity.get(result.getLeadId());
                opp.AccountId = result.getAccountId();
                opp.ContactId = result.getContactId();
                oppsToInsert.add(opp);
            }
        }
 
        if (!oppsToInsert.isEmpty()) {
            insert oppsToInsert;
        }
    }
}