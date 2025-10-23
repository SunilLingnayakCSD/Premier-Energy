public class LeadOnHoldNotification implements Database.Batchable<SObject>, Schedulable {
    
    private static final String ROLE_SUFFIX = '_Region_Head_Key_Account_Private';
    private static final String NATIONAL_HEAD_ROLE = 'National_Head_Key_Accounts_Private';
    private static final String INTERNATIONAL_HEAD_ROLE = 'Key_Accounts_International_Head_Private';
    private static final String RECORD_TYPE_DEV_NAME = 'Key_Account_Private';
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        RecordType rdType = [SELECT Id FROM RecordType WHERE DeveloperName = :RECORD_TYPE_DEV_NAME LIMIT 1];
        
        return Database.getQueryLocator([
            SELECT Id, Name, Status, City, State, On_Hold_Date__c, Region_Picklist__c, DCR_Non_DCR1__c, 
                   Product_Details_Technology_Type__c, Segment1__c, Product_Category__c, OwnerId, Owner.Name, Reason_for_On_Hold__c,
                   Owner.Email, Owner.UserRole.DeveloperName, Delivery_Due_Date__c, Project_Capacity__c
            FROM Lead
            WHERE RecordTypeId = :rdType.Id
            AND Status = 'On Hold'
            AND On_Hold_Date__c != NULL
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        // Date calculations
        Date today = Date.today();
        Date sixMonthPreDate = today.addDays(7).addMonths(-6); // One week before 6 months
        Integer todayDay = today.day();
        Date oneMonthAgo = today.addMonths(-1);
        Date sixMonthsAgo = today.addMonths(-6);
        
        // Maps to store leads by notification type and owner
        Map<String, List<Lead>> preNotifyLeadsByOwner = new Map<String, List<Lead>>();
        Map<String, List<Lead>> monthlyReminderLeadsByOwner = new Map<String, List<Lead>>();
        
        // Map to track all CC recipients for each owner
        Map<String, Set<String>> ownerToCCEmails = new Map<String, Set<String>>();
        
        // Fetch required heads
        List<User> heads = [SELECT Email, UserRole.DeveloperName FROM User 
                          WHERE UserRole.DeveloperName IN (:NATIONAL_HEAD_ROLE, :INTERNATIONAL_HEAD_ROLE)];
        
        String nationalHeadEmail = null;
        String internationalHeadEmail = null;
        
        for (User u : heads) {
            if (u.UserRole.DeveloperName == NATIONAL_HEAD_ROLE) {
                nationalHeadEmail = u.Email;
            } else if (u.UserRole.DeveloperName == INTERNATIONAL_HEAD_ROLE) {
                internationalHeadEmail = u.Email;
            }
        }
        
        // Process leads and determine recipients
        for (Lead ld : scope) {
          //  if (ld.Owner == null || String.isBlank(ld.Owner.Email)) continue;
            
            String ownerEmail = ld.Owner.Email;
            
            // Initialize maps if needed
            if (!ownerToCCEmails.containsKey(ownerEmail)) {
                ownerToCCEmails.put(ownerEmail, new Set<String>());
            }
            if (!preNotifyLeadsByOwner.containsKey(ownerEmail)) {
                preNotifyLeadsByOwner.put(ownerEmail, new List<Lead>());
            }
            if (!monthlyReminderLeadsByOwner.containsKey(ownerEmail)) {
                monthlyReminderLeadsByOwner.put(ownerEmail, new List<Lead>());
            }
            
            // Determine if owner is Region Head
            Boolean isRegionHead = false;
            if (ld.Owner.UserRole != null && String.isNotBlank(ld.Region_Picklist__c)) {
                String expectedRole = ld.Region_Picklist__c.trim() + ROLE_SUFFIX;
                isRegionHead = ld.Owner.UserRole.DeveloperName != null && 
                             ld.Owner.UserRole.DeveloperName.contains(ROLE_SUFFIX);
            }
            
            // Add appropriate CCs
            if (isRegionHead && nationalHeadEmail != null) {
                ownerToCCEmails.get(ownerEmail).add(nationalHeadEmail);
            } else if (!isRegionHead && internationalHeadEmail != null) {
                ownerToCCEmails.get(ownerEmail).add(internationalHeadEmail);
            }
            
            // Categorize leads by notification type
            if (ld.On_Hold_Date__c == sixMonthPreDate) {
                preNotifyLeadsByOwner.get(ownerEmail).add(ld);
            }
            
            Date holdDate = ld.On_Hold_Date__c;
            if (holdDate.day() == todayDay && holdDate <= oneMonthAgo && holdDate > sixMonthsAgo) {
                monthlyReminderLeadsByOwner.get(ownerEmail).add(ld);
            }
        }
        
        // Prepare emails
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        // Process pre-notification leads
        for (String ownerEmail : preNotifyLeadsByOwner.keySet()) {
            List<Lead> leads = preNotifyLeadsByOwner.get(ownerEmail);
            if (!leads.isEmpty()) {
                emailsToSend.add(createEmail(
                    ownerEmail,
                    'Leads on Hold – 6-Month Hold Period Notification',
                    buildEmailBody(leads, leads[0].Owner.Name, 
                                 'The following leads will complete 6 months on hold in a week:'),
                    ownerToCCEmails.get(ownerEmail)
                ));
            }
        }
        
        // Process monthly reminder leads
        for (String ownerEmail : monthlyReminderLeadsByOwner.keySet()) {
            List<Lead> leads = monthlyReminderLeadsByOwner.get(ownerEmail);
            if (!leads.isEmpty()) {
                emailsToSend.add(createEmail(
                    ownerEmail,
                    'Monthly Reminder: Leads On Hold',
                    buildEmailBody(leads, leads[0].Owner.Name,
                                 'This is a monthly reminder for the following leads currently on hold:'),
                    ownerToCCEmails.get(ownerEmail)
                ));
            }
        }
        
        // Send all emails
        if (!emailsToSend.isEmpty()) {
            try {
                Messaging.sendEmail(emailsToSend);
            } catch (Exception e) {
                System.debug('Error sending emails: ' + e.getMessage());
            }
        }
    }
    
    private Messaging.SingleEmailMessage createEmail(String toAddress, String subject, String body, Set<String> ccAddresses) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{toAddress});
        if (ccAddresses != null && !ccAddresses.isEmpty()) {
            mail.setCcAddresses(new List<String>(ccAddresses));
        }
        mail.setSubject(subject);
        mail.setSenderDisplayName('Premier Energies');
        mail.setHtmlBody(body);
        return mail;
    }
    
    private String buildEmailBody(List<Lead> leads, String userName, String introText) {
        String rows = '';
        for (Lead ld : leads) {
            rows += '<tr>' +
                   '<td>' + (String.isNotBlank(ld.Name) ? ld.Name : '') + '</td>' +
                   '<td>' + (String.isNotBlank(ld.Product_Category__c) ? ld.Product_Category__c : '') + '</td>' +
                   '<td>' + (String.isNotBlank(ld.Segment1__c) ? ld.Segment1__c : '') + '</td>' +
                   '<td>' + (String.isNotBlank(ld.Product_Details_Technology_Type__c) ? ld.Product_Details_Technology_Type__c : '') + '</td>' +
                   '<td>' + (String.isNotBlank(ld.DCR_Non_DCR1__c) ? ld.DCR_Non_DCR1__c : '') + '</td>' +
                   '<td>' + (ld.Project_Capacity__c != null ? String.valueOf(ld.Project_Capacity__c) : '') + '</td>' +
                   '<td>' + (ld.Delivery_Due_Date__c != null ? ld.Delivery_Due_Date__c.format() : '') + '</td>' +
                   '</tr>';
        }
        
        return '<html><body>' +
               '<p>Hi ' + userName + ',</p>' +
               '<p>' + introText + '</p>' +
               '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">' +
               '<thead><tr>' +
               '<th>Customer Name</th>' +
               '<th>Product Type</th>' +
               '<th>Segment</th>' +
               '<th>Product Details</th>' +
               '<th>DCR/Non-DCR</th>' +
               '<th>Capacity (Wp)</th>' +
               '<th>Delivery Due Date</th>' +
               '</tr></thead>' +
               '<tbody>' + rows + '</tbody>' +
               '</table>' +
               '<p>Best Regards,<br/>Premier Energies</p>' +
               '</body></html>';
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Lead On Hold Notification Batch completed successfully.');
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadOnHoldNotification());
    }
}