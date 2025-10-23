public class OpportunitySOReminderBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Name, Customer_Name__c,StageName,Tender_Name__c, Product_Type__c,RecordType.Developername, Scheme_Name__c, Region_Head_Email__c
            FROM Opportunity
            WHERE Id NOT IN (SELECT OpportunityId FROM Order)
            AND Region_Head_Email__c != null
            AND StageName = 'Closed Won'
            AND RecordType.Developername = 'Key_Account_Government'
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        Map<String, List<Opportunity>> regionalHeadOpps = new Map<String, List<Opportunity>>();

        for (Opportunity opp : scope) {
            String emailKey = opp.Region_Head_Email__c.trim();
            if (!regionalHeadOpps.containsKey(emailKey)) {
                regionalHeadOpps.put(emailKey, new List<Opportunity>());
            }
            regionalHeadOpps.get(emailKey).add(opp);
        }

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (String regionalEmails : regionalHeadOpps.keySet()) {
            List<Opportunity> opps = regionalHeadOpps.get(regionalEmails);
            Integer serial = 1;
            String tableRows = '';

            for (Opportunity opp : opps) {
                String link = System.Url.getOrgDomainUrl().toExternalForm() + '/' + opp.Id;
                tableRows += '<tr>' +
                             '<td>' + serial + '</td>' +
                             '<td>' + opp.Tender_Name__c + '</td>' +
                             '<td>' + (opp.Customer_Name__c != null ? opp.Customer_Name__c : '') + '</td>' +
                             '<td>' + (opp.Product_Type__c != null ? opp.Product_Type__c : '') + '</td>' +
                             '<td>' + (opp.Scheme_Name__c != null ? opp.Scheme_Name__c : '') + '</td>' +
                             '<td><a href="' + link + '">View</a></td>' +
                             '</tr>';
                serial++;
            }

            String body = '<html><body>' +
                          '<p>Dear Team,</p>' +
                          '<p>The following Tenders are pending for SO Creation.</p>' +
                          '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">' +
                          '<tr>' +
                          '<th>S No.</th>' +
                          '<th>Tender Number</th>' +
                          '<th>Customer Name</th>' +
                          '<th>Product Type</th>' +
                          '<th>Scheme Name</th>' +
                          '<th>Link</th>' +
                          '</tr>' +
                          tableRows +
                          '</table>' +
                          '<p>Kindly go through the above link(s) for more details about the Tender.</p>' +
                          '<p>Thank you.</p>' +
                          '</body></html>';

            Messaging.SingleEmailMessage mail = createEmailMessage(
                'Reminder for Sending for SO Creation',
                body,
                regionalEmails.split(',')
            );

            if (mail != null) {
                emailsToSend.add(mail);
            }
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }

    private Messaging.SingleEmailMessage createEmailMessage(String subject, String body, List<String> toAddresses) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toAddresses);
            email.setSubject(subject);
            email.setHtmlBody(body);
            email.setSenderDisplayName('Premier Energies');
            return email;
        } catch (Exception ex) {
            System.debug('Error while creating email: ' + ex.getMessage());
            return null;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Opportunity SO Reminder Batch Completed');
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new OpportunitySOReminderBatch(), 200);
    }
}