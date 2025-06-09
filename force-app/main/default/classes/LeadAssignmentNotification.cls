public class LeadAssignmentNotification implements Database.Batchable<SObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all relevant leads
        return Database.getQueryLocator([
            SELECT Id, RecordType.DeveloperName, ASM__c, ASM__r.Id, Purchased_Module__c, 
                   OwnerId, Owner.Name, Owner.Email, ASM__r.Email, Distributor__c,
                   Distributor__r.Email, Status, Name, Region_Picklist__c, City, State,
                   CreatedDate, Total_Wattage_Wp__c, DCR_Non_DCR__c, Country,
                   Tender_Number__c, Government_Project__c, Scheme_Name__c
            FROM Lead 
            WHERE (RecordType.DeveloperName = 'Channel_Sales') 
               OR (RecordType.DeveloperName = 'Key_Account_Private' AND Status = 'Pre_Qualification_Request')
               OR (RecordType.DeveloperName = 'Key_Account_Government' AND Status = 'New')
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        // Separate leads by record type
        List<Lead> channelSalesLeads = new List<Lead>();
        List<Lead> keyAccountPrivateLeads = new List<Lead>();
        List<Lead> keyAccountGovtLeads = new List<Lead>();
        
        for (Lead ld : scope) {
            if (ld.RecordType.DeveloperName == 'Channel_Sales') {
                channelSalesLeads.add(ld);
            } else if (ld.RecordType.DeveloperName == 'Key_Account_Private' && ld.Status == 'Pre_Qualification_Request') {
                keyAccountPrivateLeads.add(ld);
            } else if (ld.RecordType.DeveloperName == 'Key_Account_Government' && ld.Status == 'New') {
                keyAccountGovtLeads.add(ld);
            }
        }
        
        // Process Channel Sales Leads
        if (!channelSalesLeads.isEmpty()) {
            processChannelSalesLeads(channelSalesLeads);
        }
        
        // Process Key Account Private Leads
        if (!keyAccountPrivateLeads.isEmpty()) {
            processKeyAccountPrivateLeads(keyAccountPrivateLeads);
        }
        
        // Process Key Account Government Leads
        if (!keyAccountGovtLeads.isEmpty()) {
            processKeyAccountGovtLeads(keyAccountGovtLeads);
        }
    }
    
    private void processChannelSalesLeads(List<Lead> leads) {
        // Maps to store grouped leads by Owner email and ASM email
        Map<String, List<Lead>> ownerLeads = new Map<String, List<Lead>>();
        Map<String, List<Lead>> asmLeads = new Map<String, List<Lead>>();
        Map<String, List<Lead>> distributorLeads = new Map<String, List<Lead>>();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for (Lead ld : leads) {
            // Case 1: If ASM is null, send to the Owner
            if (ld.ASM__c == null) {
                if (!ownerLeads.containsKey(ld.Owner.Email)) {
                    ownerLeads.put(ld.Owner.Email, new List<Lead>());
                }
                ownerLeads.get(ld.Owner.Email).add(ld);
            }
            
            // Case 2: If Distributor is null, send to the ASM
            if (ld.Distributor__c == null && ld.ASM__c != null) {
                if (!asmLeads.containsKey(ld.ASM__r.Email)) {
                    asmLeads.put(ld.ASM__r.Email, new List<Lead>());
                }
                asmLeads.get(ld.ASM__r.Email).add(ld);
            }
            
            if ((ld.Purchased_Module__c == null || ld.Purchased_Module__c == '') && ld.Distributor__c != null && ld.ASM__c != null) {
                if (!distributorLeads.containsKey(ld.Distributor__r.Email)) {
                    distributorLeads.put(ld.Distributor__r.Email, new List<Lead>());
                }
                distributorLeads.get(ld.Distributor__r.Email).add(ld);
            }
        }
        
        // Process owner leads
        for (String ownerEmail : ownerLeads.keySet()) {
            List<Lead> leadsForOwner = ownerLeads.get(ownerEmail);
            String leadDetails = '';
            
            for (Lead ld : leadsForOwner) {
                leadDetails += '<tr><td>' + ld.Id + '</td><td>' + ld.Name + '</td><td>' + ld.Status + '</td><td>' + ld.State + '</td><td>' + ld.City + '</td><td>' + ld.Region_Picklist__c + '</td></tr>';
            }
            
            String subject = 'ASM Assignment Notification';
            String RSMname = leadsForOwner[0].Owner.Name;
            
            String body = '<p>Hi ' + RSMname + ',</p>' +
                '<p>We noticed that the following leads have not yet been assigned an ASM:</p>';
            body += '<table border="1"><tr><th>LeadId</th><th>Name</th><th>Status</th><th>State</th><th>City</th><th>Region</th></tr>';
            body += leadDetails + '</table>' +
                '<p>Best Regards,<br/>Premier Energies</p>';
            
            emailsToSend.add(createEmailMessage(leadsForOwner[0], ownerEmail, subject, body, new List<String>{ownerEmail}));
        }
        
        // Process ASM leads
        for (String asmEmail : asmLeads.keySet()) {
            List<Lead> leadsForASM = asmLeads.get(asmEmail);
            String leadDetails = '';
            
            for (Lead ld : leadsForASM) {
                leadDetails += '<tr><td>' + ld.Id + '</td><td>' + ld.Name + '</td><td>' + ld.Status + '</td><td>' + ld.State + '</td><td>' + ld.City + '</td><td>' + ld.Region_Picklist__c + '</td></tr>';
            }
            
            String subject = 'Distributor Assignment Notification';
            String ASMname = leadsForASM[0].Owner.Name;
            
            String body = '<p>Hi ' + ASMname + ',</p>';
            body += '<p>We noticed these leads haven\'t been assigned to a distributor yet:</p>';
            body += '<table border="1"><tr><th>LeadId</th><th>Name</th><th>Status</th><th>State</th><th>City</th><th>Region</th></tr>';
            body += leadDetails + '</table>' +
            '<p>Best Regards,<br/>Premier Energies</p>';
            
            emailsToSend.add(createEmailMessage(leadsForASM[0], asmEmail, subject, body, new List<String>{asmEmail}));
        }
        
        // Process distributor leads
        for (String disEmail : distributorLeads.keySet()) {
            List<Lead> leadsForDis = distributorLeads.get(disEmail);
            String leadDetails = '';
            
            for (Lead ld : leadsForDis) {
                leadDetails += '<tr><td>' + ld.Id + '</td><td>' + ld.Name + '</td><td>' + ld.Status + '</td><td>' + ld.State + '</td><td>' + ld.City + '</td><td>' + ld.Region_Picklist__c + '</td></tr>';
            }
            
            String subject = 'Module Not Yet Purchased';
            String DistributorName = leadsForDis[0].Owner.Name;
            
            String body = '<p>Hi ' + DistributorName + ',</p>' ;
            body += '<p>We noticed you haven\'t yet purchased the required module for these leads:</p>';
            body += '<table border="1"><tr><th>LeadId</th><th>Name</th><th>Status</th><th>State</th><th>City</th><th>Region</th></tr>';
            body += leadDetails + '</table>' +
                '<p>Best Regards,<br/>Premier Energies</p>';
            
            emailsToSend.add(createEmailMessage(leadsForDis[0], disEmail, subject, body, new List<String>{disEmail}));
        }
        
        // Send all the emails
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
    
    private void processKeyAccountPrivateLeads(List<Lead> leads) {
        // Group leads by regional head (owner)
        Map<String, List<Lead>> regionalHeadLeads = new Map<String, List<Lead>>();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for (Lead ld : leads) {
            String regionalHeadEmail = ld.Owner.Email;
            if (!regionalHeadLeads.containsKey(regionalHeadEmail)) {
                regionalHeadLeads.put(regionalHeadEmail, new List<Lead>());
            }
            regionalHeadLeads.get(regionalHeadEmail).add(ld);
        }
        
        // Get national head email (you might need to query this from a custom setting or user record)
        String nationalHeadEmail = getNationalHeadEmail();
        
        // Process each regional head's leads
        for (String regionalHeadEmail : regionalHeadLeads.keySet()) {
            List<Lead> leadsForRegion = regionalHeadLeads.get(regionalHeadEmail);
            
            // Prepare email content for regional head
            String leadDetails = '';
            Integer serialNumber = 1;
            
            for (Lead ld : leadsForRegion) {
                leadDetails += '<tr><td>' + serialNumber + '</td><td>' + ld.CreatedDate.format() + '</td><td>' + 
                              ld.Name + '</td><td>' + ld.Total_Wattage_Wp__c + '</td><td>' + 
                              ld.DCR_Non_DCR__c + '</td><td>' + ld.Country + '</td><td>' + 
                              ld.State + '</td><td>' + ld.City + '</td></tr>';
                serialNumber++;
            }
            
            String todayDate = System.today().format();
            String subject = 'Pending Prequalification requests reminder || ' + todayDate;
            String regionalHeadName = leadsForRegion[0].Owner.Name;
            
            String body = '<p>Dear ' + regionalHeadName + ',</p>' +
                '<p>The following prequalification requests are pending.</p>' +
                '<table border="1"><tr><th>S No.</th><th>Lead Created on</th><th>Customer Name</th>' +
                '<th>Total Capacity Wattage Wp</th><th>DCR/NDCR</th><th>Country</th>' +
                '<th>State</th><th>City</th></tr>' +
                leadDetails + '</table>' +
                '<p>Kindly go through the below link to take further actions.</p>' +
                '<p><a href="' + getSalesforceLink() + '">Link to Salesforce Page</a></p>' +
                '<p>Thank you.</p>';
            
            // Send email to regional head with national head in CC
            emailsToSend.add(createEmailMessage(
                leadsForRegion[0], 
                regionalHeadEmail, 
                subject, 
                body, 
                new List<String>{regionalHeadEmail, nationalHeadEmail}
            ));
        }
        
        // Send all the emails
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
    
    private void processKeyAccountGovtLeads(List<Lead> leads) {
        System.debug('processKeyAccountGovtLeads--> ');
        // Group leads by regional head (owner)
        Map<String, List<Lead>> regionalHeadLeads = new Map<String, List<Lead>>();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for (Lead ld : leads) {
            String regionalHeadEmail = ld.Owner.Email;
            if (!regionalHeadLeads.containsKey(regionalHeadEmail)) {
                regionalHeadLeads.put(regionalHeadEmail, new List<Lead>());
            }
            regionalHeadLeads.get(regionalHeadEmail).add(ld);
        }
        
        // Process each regional head's leads
        for (String regionalHeadEmail : regionalHeadLeads.keySet()) {
            System.debug('regionalHeadEmail--> '+ regionalHeadEmail);
            List<Lead> leadsForRegion = regionalHeadLeads.get(regionalHeadEmail);
            
            // Prepare email content
            String leadDetails = '';
            Integer serialNumber = 1;
            
            for (Lead ld : leadsForRegion) {
                leadDetails += '<tr><td>' + serialNumber + '</td><td>' + 
                              (ld.Tender_Number__c != null ? ld.Tender_Number__c : '') + '</td><td>' + 
                              ld.Name + '</td><td>' + 
                              (ld.Government_Project__c != null ? ld.Government_Project__c : '') + '</td><td>' + 
                              (ld.Scheme_Name__c != null ? ld.Scheme_Name__c : '') + '</td></tr>';
                serialNumber++;
            }
            
            String subject = 'Reminder for Feasibility check for New Tenders';
            
            String body = '<p>Dear Team,</p>' +
                '<p>The following new Tenders are pending for necessary feasibility check.</p>' +
                '<table border="1"><tr><th>S No.</th><th>Tender Number</th><th>Customer Name</th>' +
                '<th>Product Type</th><th>Scheme Name</th></tr>' +
                leadDetails + '</table>' +
                '<p>Kindly go through the below link for more details about the Tender.</p>' +
                '<p><a href="' + getSalesforceGovtLink() + '">Salesforce Link</a></p>' +
                '<p>Thank you.</p>';
            
            // Send email to regional head
            emailsToSend.add(createEmailMessage(
                leadsForRegion[0], 
                regionalHeadEmail, 
                subject, 
                body, 
                new List<String>{regionalHeadEmail}
            ));
        }
        
        // Send all the emails
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
    
    // Helper method to get national head email for Key Account Private
    private String getNationalHeadEmail() {
        User nationalHead = [SELECT Email, UserRole.DeveloperName FROM User 
                            WHERE UserRole.DeveloperName = 'National_Head_Key_Accounts_Private' 
                            LIMIT 1];
        return nationalHead.Email;
    }
    
    // Helper method to get Salesforce page link for Key Account Private
    private String getSalesforceLink() {
        return System.Url.getOrgDomainUrl().toExternalForm() + '/lightning/o/Lead/list?filterName=Key_Account_Private';
    }
    
    // Helper method to get Salesforce page link for Key Account Government
    private String getSalesforceGovtLink() {
        return System.Url.getOrgDomainUrl().toExternalForm() + '/lightning/o/Lead/list?filterName=Key_Account_Government';
    }
    
    // Helper method to create an email message
    private Messaging.SingleEmailMessage createEmailMessage(Lead ld, String recipientEmail, 
                                                         String subject, String body, 
                                                         List<String> recipients) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(recipients);
            mail.setSubject(subject);
            mail.setHTMLBody(body);
            return mail;
        } catch (Exception e) {
            System.debug('Error creating email message: ' + e.getMessage());
            return null;
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch process completed');
    }
    
    public void execute(SchedulableContext SC) {
        LeadAssignmentNotification ldnotify = new LeadAssignmentNotification();
        Database.executeBatch(ldnotify, 200);
    }
}