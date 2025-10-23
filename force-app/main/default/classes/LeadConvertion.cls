public without sharing class LeadConvertion {
    @InvocableMethod
    public static void convertLeads(List<Id> leadIds) {
        List<Lead> leads = [
            SELECT Id, Company, FirstName, LastName, Email, OwnerId,LeadSource,Product_Category__c,Government_Project__c,Owner.Email,
                   Customer_Registered_Country__c, Customer_Registered_State__c,Project_Capacity__c,Other_Product_if_applicable__c,Location_of_the_project_site__c,
                   Customer_Registered_City__c, Customer_Registered_Pincode__c,Lead_Capacity__c,Quantity1__c,Scheme_Name__c,Payment_Terms__c,
                   DCR_Non_DCR1__c, Delivery_required_by__c, Domestic_Exports__c,Wattage_Wp_Cell_Module2__c,Segment_KAG__c,Installation_Completion_Date__c,
                   Plant_Store_Name1__c, Premier_Business_Entity1__c, Product_Details_Technology_Type__c, Street,Enquiry_or_RFQ_Documents__c,Tender_Number__c,EMD_Amounts__c,
                   Total_Capacity_in_MWp__c, RecordType.DeveloperName, City, Country, PostalCode,Delivery_Due_Date__c,Tender_Document__c,
                   Lead_Regional_Head_Email__c,Scope_of_Supply__c,Region_Picklist__c, Segment1__c, State, Phone,Region_Customer_Operation__c,Credit_rating_of_Tenderer__c,
                   Controller_Type__c,Pump_Type_AC_DC__c,Pump_Position__c,Water_Pumping_Systems_Quantity__c,Pump_Capacity_HP_1_HP_2HP_3_HP_5__c,
                   Location_of_the_project_site__Street__s,Location_of_the_project_site__CountryCode__s,Location_of_the_project_site__PostalCode__s,Location_of_the_project_site__StateCode__s,
                   Location_of_the_project_site__City__s
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
                    Email__c = ld.Email,
                    Plant_Name__c = ld.Plant_Store_Name1__c,
                    BillingCity = ld.City,
                    BillingCountry = ld.Country,
                    BillingPostalCode = ld.PostalCode,
                    BillingState = ld.State,
                    BillingStreet = ld.Street,
                    Phone = ld.Phone,
                    AccountSource = ld.LeadSource,
                    Premier_Business_Entity__c = ld.Premier_Business_Entity1__c,
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
                //Customer_Name__c = ld.Lead_Capacity__c,
                CloseDate = Date.today().addDays(30),
                StageName = ld.RecordType.DeveloperName == 'Key_Account_Government'? 'Price Approval & Proposal Submission' : 'RFQ/Enquiry',
                Customer_Registered_Address__c = String.join(new List<String>{
                    ld.Customer_Registered_Country__c, ld.Customer_Registered_State__c,
                    ld.Customer_Registered_City__c, ld.Customer_Registered_Pincode__c
                }, ' ').trim(),
                DCR_Non_DCR1__c = ld.DCR_Non_DCR1__c,
                LeadSource = ld.LeadSource,
                Enquiry_or_RFQ_Documents__c = ld.Enquiry_or_RFQ_Documents__c,
                Delivery_Required_by__c = ld.Delivery_Due_Date__c,
                Domestic_Exports__c = ld.Domestic_Exports__c,
                OwnerId = ld.OwnerId,
                Scheme_Name__c = ld.Scheme_Name__c,
                Plant_Store_Name__c = ld.Plant_Store_Name1__c,
                TotalOpportunityQuantity = ld.Quantity1__c,
                Premier_Business_Entity1__c = ld.Premier_Business_Entity1__c,
                Product_Details_Technology_Type1__c = ld.Product_Details_Technology_Type__c,
                Project_capacity_in_MWp_including_Spare__c = ld.Project_Capacity__c,
                RecordTypeId = oppRecordTypeMap.get(ld.RecordType.DeveloperName),
                Region_Head_Email__c = ld.Owner.Email,
                Region__c = ld.Region_Picklist__c,
                Product_Type__c = ld.Government_Project__c,
                Segment1__c = ld.RecordType.DeveloperName == 'Key_Account_Government'? ld.Segment_KAG__c:ld.Segment1__c,
                Delivery_To_Date__c = ld.Delivery_Due_Date__c,
                Product_Category1__c = ld.Product_Category__c,
                Region_Customer_Operation__c = ld.Region_Customer_Operation__c,
                Wattage_Wp_Cell_Module1__c = ld.Wattage_Wp_Cell_Module2__c,
                Project_Capacity_in_MWp__c = ld.Project_Capacity__c,
                Tender_Number__c = ld.Tender_Number__c,
                Tender_Document__c = ld.Tender_Document__c,
                Credit_rating_of_Tenderer__c = ld.Credit_rating_of_Tenderer__c,
                Installation_Completion_Due_Date__c = ld.Installation_Completion_Date__c,
                EMD_Amounts__c = ld.EMD_Amounts__c,
                Payment_Terms1__c = ld.Payment_Terms__c,
                Pump_Capacity_HP__c = ld.Pump_Capacity_HP_1_HP_2HP_3_HP_5__c,
                Pump_Position__c = ld.Pump_Position__c,
                Pump_Type__c = ld.Pump_Type_AC_DC__c,
                Water_Pumping_Systems_Quantity__c = ld.Water_Pumping_Systems_Quantity__c,
                Controller_Type__c = ld.Controller_Type__c,
                Scope_of_Supply__c = ld.Scope_of_Supply__c,
                Location_of_the_project_site__Street__s  = ld.Location_of_the_project_site__Street__s,
                Location_of_the_project_site__City__s    = ld.Location_of_the_project_site__City__s,
                Location_of_the_project_site__StateCode__s   = ld.Location_of_the_project_site__StateCode__s,
                Location_of_the_project_site__PostalCode__s = ld.Location_of_the_project_site__PostalCode__s,
                Location_of_the_project_site__CountryCode__s = ld.Location_of_the_project_site__CountryCode__s,
                //O_M_Period__c = ld.O_M_Period__c,
                Customer_Type__c = 'New'
            );
            System.debug('AccountId--> '+ opp.AccountId);
 
            leadIdToOpportunity.put(ld.Id, opp);
            System.debug('Opp Stage--> '+ opp.StageName);
            System.debug('opp wattage--> '+ opp.Wattage_Wp_Cell_Module1__c);
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