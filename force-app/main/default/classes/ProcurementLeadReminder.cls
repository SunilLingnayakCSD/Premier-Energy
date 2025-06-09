public class ProcurementLeadReminder implements Schedulable {

    public void sendProcurementEmails() {
        List<User> users = [
            SELECT Id, Name, Email, UserRole.DeveloperName 
            FROM User 
            WHERE IsActive = true AND UserRole.DeveloperName IN ('Procurement', 'Inbound_Logistics', 'Outbound_Logistics')
        ];

        // Define URLs
        Map<String, String> roleToUrl = new Map<String, String>{
            'Procurement' => '/lightning/n/Procurement_Input',
            'Inbound_Logistics' => '/lightning/n/Admin_Input',
            'Outbound_Logistics' => '/lightning/n/Admin_Input'
        };

        // Define Subjects
        Map<String, String> roleToSubject = new Map<String, String>{
            'Procurement' => 'Salesforce | Procurement Price & Data update',
            'Inbound_Logistics' => 'Salesforce | Inbound Logistics Price & Data update',
            'Outbound_Logistics' => 'Salesforce | Outbound Logistics Price & Data update'
        };

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (User u : users) {
            String role = u.UserRole.DeveloperName;
            String link = roleToUrl.get(role);
            String subject = roleToSubject.get(role);

            if (String.isNotEmpty(link)) {
                String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
                String fullLink = baseUrl + link;

                String body = 'Dear Team,\n\nKindly go through the below link to update the data in Salesforce.\n\n' +
                    'Click here to access: ' + fullLink + '\n\nThank You';

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { u.Email });
                mail.setSubject(subject);
                mail.setPlainTextBody(body);
                emails.add(mail);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    public void execute(SchedulableContext sc) {
        sendProcurementEmails();
    }
}