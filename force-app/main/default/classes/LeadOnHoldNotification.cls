public class LeadOnHoldNotification implements Database.Batchable<SObject>, Schedulable {
    
    private static final String ROLE_SUFFIX = '_Region_Head_Key_Account_Private';
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        RecordType rdType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' LIMIT 1];
        
        return Database.getQueryLocator([
            SELECT Id, Name, Status, City, State, On_Hold_Date__c, Region_Picklist__c,
            OwnerId, Owner.Name, Owner.Email, Owner.UserRole.DeveloperName
            FROM Lead
            WHERE RecordTypeId = :rdType.Id
            AND Status = 'On Hold'
            AND On_Hold_Date__c != NULL
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        Date today = Date.today();
        Date sixMonthPreDate = today.addDays(7).addMonths(-6); // One week before 6 months
        System.debug('sixMonthPreDate--> '+ sixMonthPreDate);
        Integer todayDay = today.day();
        System.debug('todayDay--> '+ todayDay);
        Date oneMonthAgo = today.addMonths(-1);
        System.debug('oneMonthAgo--> '+ oneMonthAgo);
        Date sixMonthsAgo = today.addMonths(-6);
        System.debug('sixMonthsAgo--> '+ sixMonthsAgo);
        
        // Separate leads based on which notification they qualify for
        Map<String, List<Lead>> preNotifyLeadsByEmail = new Map<String, List<Lead>>();
        Map<String, List<Lead>> monthlyReminderLeadsByEmail = new Map<String, List<Lead>>();
        
        // Prepare user email to region for email body customization
        Map<String, String> emailToRegionMap = new Map<String, String>();
        
        for (Lead ld : scope){
            System.debug('ld.On_Hold_Date__c--> '+ ld.On_Hold_Date__c);
        }
        
        for (Lead ld : scope) {
            if (ld.Owner == null || ld.Owner.UserRole == null || String.isBlank(ld.Region_Picklist__c)) continue;
            
            String region = ld.Region_Picklist__c.trim();
            String expectedRole = region + ROLE_SUFFIX;
            String ownerEmail = ld.Owner.Email;
            
            if (String.isBlank(ownerEmail)) continue;
            
            // ✅ Check if owner is a Region Head
            if (ld.Owner.UserRole.DeveloperName != expectedRole) continue;
            
            // Store region
            emailToRegionMap.put(ownerEmail, region);
            
            // 6-Month Pre-Notification
            if (ld.On_Hold_Date__c == sixMonthPreDate) {
                if (!preNotifyLeadsByEmail.containsKey(ownerEmail)) {
                    preNotifyLeadsByEmail.put(ownerEmail, new List<Lead>());
                }
                preNotifyLeadsByEmail.get(ownerEmail).add(ld);
            }
            System.debug('holdDate --> '+ ld.On_Hold_Date__c);
            
            // Monthly Reminder
            Date holdDate = ld.On_Hold_Date__c;
            
            if (holdDate.day() == todayDay &&
                holdDate <= oneMonthAgo &&
                holdDate > sixMonthsAgo) {
                    System.debug('Monthly Remainder--> ');
                    
                    if (!monthlyReminderLeadsByEmail.containsKey(ownerEmail)) {
                        monthlyReminderLeadsByEmail.put(ownerEmail, new List<Lead>());
                    }
                    monthlyReminderLeadsByEmail.get(ownerEmail).add(ld);
                }
        }
        
        // Fetch national head
        List<User> nationalHeadUser = [SELECT Email FROM User 
                                       WHERE UserRole.DeveloperName = 'National_Head_Key_Accounts_Private' 
                                       LIMIT 1];
        String nationalHeadEmail = !nationalHeadUser.isEmpty() ? nationalHeadUser[0].Email : null;
        
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        // Send Pre-Notification Emails
        for (String email : preNotifyLeadsByEmail.keySet()) {
            String region = emailToRegionMap.get(email);
            List<Lead> leads = preNotifyLeadsByEmail.get(email);
            String name = leads[0].Owner.Name;
            String subject = 'Leads on Hold – 6-Month Hold Period Notification';
            String body = buildEmailBody(leads, name,
                                         'The following leads will complete 6 months on hold in a week:');
            
            emailsToSend.add(createEmailMessage(email, subject, body, 
                                                new List<String>{email}, nationalHeadEmail));
        }
        
        // Send Monthly Reminder Emails
        for (String email : monthlyReminderLeadsByEmail.keySet()) {
            String region = emailToRegionMap.get(email);
            List<Lead> leads = monthlyReminderLeadsByEmail.get(email);
            String name = leads[0].Owner.Name;
            String subject = 'Monthly Reminder: Leads On Hold';
            String body = buildEmailBody(leads, name,
                                         'This is a monthly reminder for the following leads currently on hold:');
            
            emailsToSend.add(createEmailMessage(email, subject, body, 
                                                new List<String>{email}, nationalHeadEmail));
        }
        
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
    
    private String buildEmailBody(List<Lead> leads, String userName, String introText) {
        String rows = '';
        for (Lead ld : leads) {
            rows += '<tr><td>' + ld.Id + '</td><td>' + ld.Name + '</td><td>' + ld.Status + '</td>' +
                '<td>' + ld.State + '</td><td>' + ld.City + '</td>' +
                '<td>' + ld.Region_Picklist__c + '</td><td>' + ld.On_Hold_Date__c + '</td></tr>';
        }
        
        return '<p>Hi ' + userName + ',</p>' +
            '<p>' + introText + '</p>' +
            '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse;">' +
            '<tr><th>LeadId</th><th>Name</th><th>Status</th><th>State</th><th>City</th><th>Region</th><th>On Hold Date</th></tr>' +
            rows + '</table>' +
            '<p>Best Regards,<br/>Premier Energies</p>';
    }
    
    private Messaging.SingleEmailMessage createEmailMessage(String toEmail, String subject, String body,
                                                            List<String> toAddresses, String ccEmail) {
                                                                try {
                                                                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                                                    mail.setToAddresses(toAddresses);
                                                                    if (String.isNotBlank(ccEmail)) {
                                                                        mail.setCcAddresses(new List<String>{ccEmail});
                                                                    }
                                                                    mail.setSubject(subject);
                                                                    mail.setSenderDisplayName('Premier Energies');
                                                                    mail.setHTMLBody(body);
                                                                    return mail;
                                                                } catch (Exception e) {
                                                                    System.debug('Email creation error: ' + e.getMessage());
                                                                    return null;
                                                                }
                                                            }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Lead On Hold Notification Batch completed.');
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadOnHoldNotification());
    }
}