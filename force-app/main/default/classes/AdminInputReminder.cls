global class AdminInputReminder implements Schedulable {

    global void execute(SchedulableContext sc) {
        List<User> admins = [
            SELECT Id, Name, Email 
            FROM User 
            WHERE IsActive = true AND Profile.Name = 'System Administrator'
        ];

        String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        String fullLink = baseUrl + '/lightning/n/Admin_Input';

        String subject = 'Salesforce | Admin Input Data update';
        String body = 'Dear Admin,\n\nKindly go through the below link to update the data in Salesforce.\n\n' +
                      'Click here to access: ' + fullLink + '\n\nThank You';

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (User u : admins) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { u.Email });
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}