public class PendingInvoiceReminderBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Status__c, Amount__c, Invoice_Date__c,Account__c, Account__r.Name, Account__r.Email__c,Invoice_Number__c,
            Order__c,Order__r.PoNumber,FTR_Request_Date__c,FTR_Re_Request_Date__c
            FROM Invoice__c
            WHERE (Status__c = 'Request' OR Status__c = 'Re-Request')
            AND Account__r.Email__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Invoice__c> invoices) {
        Set<String> emailSet = new Set<String>();
        
        System.debug('invoices--> '+ invoices);

        for (Invoice__c inv : invoices) {
            if (inv.Account__r != null && !String.isBlank(inv.Account__r.Email__c)) {
                emailSet.add(inv.Account__r.Email__c.trim().toLowerCase());
            }
            System.debug('inv.Account__r.Email__c--> '+ inv.Account__r.Email__c);
        }

        // Query Users by matching email to Account.Email__c
        Map<String, User> emailToUserMap = new Map<String, User>();
        for (User u : [
            SELECT Id, Email, Name, ManagerId,
                   Manager.Email, Manager.Name,
                   Manager.Manager.Email, Manager.Manager.Name
            FROM User
            WHERE IsActive = TRUE AND Email IN :emailSet AND UserRole.DeveloperName = 'ssrinPartnerPersonAccount'
        ]) {
            System.debug('u--> '+ u);
            emailToUserMap.put(u.Email.trim().toLowerCase(), u);
            System.debug('emailToUserMap--> '+ emailToUserMap);
        }

        // Group invoices by ZSM (manager’s manager)
        Map<String, List<Invoice__c>> zsmToInvoices = new Map<String, List<Invoice__c>>();
        Map<String, Set<String>> zsmToCCEmails = new Map<String, Set<String>>();

        for (Invoice__c inv : invoices) {
            String accEmail = inv.Account__r.Email__c != null ? inv.Account__r.Email__c.trim().toLowerCase() : null;
            System.debug('accEmail--> '+ accEmail);
            if (String.isBlank(accEmail)) continue;

            User u = emailToUserMap.get(accEmail);
            if (u == null || u.Manager == null || u.Manager.Manager == null) continue;

            String zsmEmail = u.Manager.Manager.Email;
            System.debug('zsmEmail--> '+zsmEmail);
            if (String.isBlank(zsmEmail)) continue;

            if (!zsmToInvoices.containsKey(zsmEmail)) {
                zsmToInvoices.put(zsmEmail, new List<Invoice__c>());
                zsmToCCEmails.put(zsmEmail, new Set<String>());
            }

            zsmToInvoices.get(zsmEmail).add(inv);

            // CC the RSM (user) and ASM (manager)
            if (!String.isBlank(u.Manager.Manager.Email)) zsmToCCEmails.get(zsmEmail).add(u.Manager.Manager.Email);
            if (!String.isBlank(u.Manager.Email)) zsmToCCEmails.get(zsmEmail).add(u.Manager.Email);
        }
        
        System.debug('zsmToInvoices--> '+zsmToInvoices);

        // Sales Operations users (To)
        List<User> salesOpsUsers = [
            SELECT Email FROM User WHERE IsActive = TRUE AND Profile.Name = 'Channel Sales -Sales Operation 1' AND UserRole.DeveloperName = 'Sales_Operation'
        ];
        List<String> toEmails = new List<String>();
        for (User u : salesOpsUsers) {
            toEmails.add(u.Email);
            System.debug('toEmails--> '+toEmails);
        }

        // Prepare and send emails
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

        for (String zsmEmail : zsmToInvoices.keySet()) {
            List<Invoice__c> invList = zsmToInvoices.get(zsmEmail);
            Set<String> ccSet = zsmToCCEmails.get(zsmEmail);

            String tableRows = '';
            Integer srNo = 1;
            for (Invoice__c inv : invList) {
                tableRows += '<tr>' +
                             '<td>' + srNo + '</td>' +
                             '<td>' + (inv.Status__c == 'Request' ? inv.FTR_Request_Date__c : inv.FTR_Re_Request_Date__c)+ '</td>' +
                             '<td>' + inv.Account__r.Name + '</td>' +
                             '<td>' + inv.Invoice_Number__c + '</td>' +
                             '<td>' + inv.Order__r.PoNumber + '</td>' +
                             '<td>' + inv.Order__c + '</td>' +
                             '</tr>';
                srNo++;
            }

            String body = '<html><body>' +
                          '<p>Dear Team,</p>' +
                          '<p>The following FTR reports are pending. Kindly upload the documents in the system.:</p>' +
                          '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse: collapse; width: 100%;">' +
                          '<tr>' +
                          '<th>S No.</th><th>Request Date</th><th>Distributor Name</th><th>Invoice Number</th><th>PO Name</th><th>SAP SO Number</th>' +
                          '</tr>' + tableRows +
                          '</table>' +
                          '<p>Kindly go through the below link to take further actions.</p>' +
                          '<p><a href="' + getInvoiceLink() + '">Link to Salesforce Page</a></p>' +
                          '<p>Thank you.</p>' +
                          '</body></html>';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toEmails);
            mail.setCcAddresses(new List<String>(ccSet));
            System.debug('ccSet--> '+ ccSet);
            mail.setSubject('Reminder: Pending FTR Request reminder');
            mail.setHtmlBody(body);
            mail.setSenderDisplayName('Premier Energies');

            emailMessages.add(mail);
        }

        if (!emailMessages.isEmpty()) {
            Messaging.sendEmail(emailMessages);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Pending Invoice Reminder Batch complete.');
    }
    
    private String getInvoiceLink() {
        return System.Url.getOrgDomainUrl().toExternalForm() + '/lightning/o/Invoice__c/list?filterName=__Recent';
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new PendingInvoiceReminderBatch(), 200);
    }
}