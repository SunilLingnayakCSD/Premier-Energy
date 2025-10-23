public class LeadTenderApprovalReminderBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Status, OwnerId, Government_Project__c, Scheme_Name__c,
                   Company, Region_Picklist__c, RecordType.DeveloperName, Owner.Email, 
                   Owner.UserRole.DeveloperName, Tender_Number__c
            FROM Lead
            WHERE Status = 'Tender Participation Request'
            AND RecordType.DeveloperName = 'Key_Account_Government'
            AND Region_Picklist__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        System.debug('scope--> '+ scope);
        Map<Id, List<Lead>> ownerToLeadsMap = new Map<Id, List<Lead>>();

        for (Lead lead : scope) {
            String region = lead.Region_Picklist__c;
            String expectedRoleName = region + '_Government_Projects_Regional_Manager';
            System.debug('expectedRoleName--> '+ expectedRoleName);
            String actualRoleName = lead.Owner.UserRole != null ? lead.Owner.UserRole.DeveloperName : null;
            System.debug('lead.Owner --> '+ lead);
            System.debug('Lead Owner--> '+ lead.Owner.UserRole);
            System.debug('actualRoleName--> '+actualRoleName);

            if (actualRoleName != null && actualRoleName.equalsIgnoreCase(expectedRoleName)) {
                if (!ownerToLeadsMap.containsKey(lead.OwnerId)) {
                    ownerToLeadsMap.put(lead.OwnerId, new List<Lead>());
                    System.debug('lead.OwnerId--> '+ lead.OwnerId);
                }
                ownerToLeadsMap.get(lead.OwnerId).add(lead);
            }
        }

        if (!ownerToLeadsMap.isEmpty()) {
            List<User> owners = [SELECT Id, Email, Name FROM User WHERE IsActive = TRUE AND Id IN :ownerToLeadsMap.keySet()];
            Map<Id, User> userMap = new Map<Id, User>(owners);
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for (Id ownerId : ownerToLeadsMap.keySet()) {
                User owner = userMap.get(ownerId);
                if (owner == null || String.isBlank(owner.Email)) continue;

                List<Lead> leads = ownerToLeadsMap.get(ownerId);
                System.debug('leads--> '+ leads);
                String tableRows = '';
                Integer serial = 1;

                for (Lead l : leads) {
                    String link = System.Url.getOrgDomainUrl().toExternalForm() + '/' + l.Id;
                    tableRows += '<tr>' +
                        '<td>' + serial + '</td>' +
                        '<td>' + l.Tender_Number__c + '</td>' +
                        '<td>' + l.Name + '</td>' +
                        '<td>' + (l.Government_Project__c != null ? l.Government_Project__c : '') + '</td>' +
                        '<td>' + (l.Scheme_Name__c != null ? l.Scheme_Name__c : '') + '</td>' +
                        '<td><a href="' + link + '">View</a></td>' +
                        '</tr>';
                    serial++;
                }

                String body = '<html><body>' +
                    '<p>Dear Team,</p>' +
                    '<p>The following new Tender are pending for necessary feasibility check.</p>' +
                    '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">' +
                    '<tr><th>S No.</th><th>Tender Number</th><th>Customer Name</th><th>Product Type</th><th>Scheme Name</th><th>Link</th></tr>' +
                    tableRows +
                    '</table>' +
                    '<p>Kindly go through the above link(s) for more details about the Tender.</p>' +
                    '<p>Thank you.</p>' +
                    '</body></html>';

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{owner.Email});
                System.debug('owner.Email--> '+ owner.Email);
                email.setSubject('Reminder for getting Management Approval for New Tenders');
                email.setHtmlBody(body);
                email.setSenderDisplayName('Premier Energies');
                emails.add(email);
            }

            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Lead Tender Approval Reminder Batch Completed');
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadTenderApprovalReminderBatch(), 200);
    }
}