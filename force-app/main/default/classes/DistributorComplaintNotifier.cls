public without sharing class DistributorComplaintNotifier {
    
    @InvocableMethod
    public static void sendComplaintNotification(List<ComplaintRequest> requests) {
        System.debug('>>> Start: sendComplaintNotification');
        
        for (ComplaintRequest req : requests) {
            System.debug('>>> Processing request: ' + req);
            
            if (req.DistributorId == null || String.isBlank(req.InvoiceNumber)) {
                System.debug('>>> Skipping due to missing DistributorId or InvoiceNumber.');
                continue;
            }
            
            List<String> toAddresses = new List<String>();
            List<String> ccAddresses = new List<String>();
            
            User distributor;
            try {
                distributor = [
                    SELECT Id, Email, Name, Region1__c
                    FROM User
                    WHERE Id = :req.DistributorId
                    LIMIT 1
                ];
            } catch (Exception e) {
                System.debug('>>> Error fetching distributor: ' + e.getMessage());
                continue;
            }
            
            System.debug('>>> Distributor Region(s): ' + distributor.Region1__c);
            
            if (!String.isBlank(distributor.Email)) {
                ccAddresses.add(distributor.Email);
                System.debug('>>> Added distributor to CC: ' + distributor.Email);
            }
            
            // Fetch Sales Operation User
            List<User> salesOpUsers = [
                SELECT Email
                FROM User
                WHERE Profile.Name = 'Channel Sales-Sales Operation 2' AND IsActive = true
                LIMIT 1
            ];
            
            if (!salesOpUsers.isEmpty() && !String.isBlank(salesOpUsers[0].Email)) {
                toAddresses.add(salesOpUsers[0].Email);
                System.debug('>>> Added Sales Operation user to TO: ' + salesOpUsers[0].Email);
            } else {
                System.debug('>>> No Sales Operation user found.');
            }

            // Handle multi-picklist Region1__c
            List<String> roleNames = new List<String>();

            if (!String.isBlank(distributor.Region1__c)) {
                List<String> selectedRegions = distributor.Region1__c.split(';');
                for (String region : selectedRegions) {
                    region = region.trim();
                    if (!String.isBlank(region)) {
                        roleNames.add(region + ' Region Head, Channel Sales');
                        roleNames.add(region + ' Region Channel Sales - Area Sales Manager');
                    }
                }
            }

            System.debug('>>> Role Names to search: ' + roleNames);

            List<User> regionUsers = new List<User>();
            if (!roleNames.isEmpty()) {
                regionUsers = [
                    SELECT Email
                    FROM User
                    WHERE UserRole.Name IN :roleNames
                ];
            }

            for (User u : regionUsers) {
                if (!String.isBlank(u.Email) && !ccAddresses.contains(u.Email)) {
                    ccAddresses.add(u.Email);
                    System.debug('>>> Added region user to CC: ' + u.Email);
                }
            }

            // Build Email Content
            String subject = 'New Distributor Complaint || Invoice #: ' + req.InvoiceNumber;
            String htmlBody = ''
                + '<p>Dear Team,</p>'
                + '<p>A new complaint has been submitted by <strong>' + distributor.Name + '</strong>, for which the details are mentioned below.</p>'
                + '<table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse;">'
                + '<tr><td><strong>Distributor Name:</strong></td><td>' + distributor.Name + '</td></tr>'
                + '<tr><td><strong>Invoice Number:</strong></td><td>' + req.InvoiceNumber + '</td></tr>'
                + '<tr><td><strong>Invoice Date:</strong></td><td>' + req.InvoiceDate + '</td></tr>'
                + '<tr><td><strong>Submitted Date:</strong></td><td>' + req.SubmittedDate + '</td></tr>'
                + '<tr><td><strong>Issue Description:</strong></td><td>' + req.IssueDescription + '</td></tr>'
                + '</table>'
                + '<p>Kindly go through the below link to take further action.</p>'
                + '<p><a href="' + req.RecordLink + '">Open the Invoice Record</a></p>'
                + '<p>Premier Energies Team</p>'
                + '<p>Thank you.</p>';
            
            System.debug('>>> Email Subject: ' + subject);
            System.debug('>>> To: ' + toAddresses);
            System.debug('>>> CC: ' + ccAddresses);
            
            // Send Email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject(subject);
            email.setHtmlBody(htmlBody);
            email.setToAddresses(toAddresses);
            email.setCcAddresses(ccAddresses);
            email.setSaveAsActivity(false);
            
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                System.debug('>>> Email sent successfully.');
            } catch (Exception ex) {
                System.debug('>>> Error sending email: ' + ex.getMessage());
            }
        }
        
        System.debug('>>> End: sendComplaintNotification');
    }
    
    public class ComplaintRequest {
        @InvocableVariable(required=true)
        public Id DistributorId;
        
        @InvocableVariable(required=true)
        public String InvoiceNumber;
        
        @InvocableVariable
        public String InvoiceDate;
        
        @InvocableVariable
        public String SubmittedDate;
        
        @InvocableVariable
        public String IssueDescription;
        
        @InvocableVariable
        public String RecordLink;
    }
}