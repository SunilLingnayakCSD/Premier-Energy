public class PurchaseOrderApprovalEmailNotification implements Database.Batchable<SObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Name, Status, OwnerId, Owner.Name, Owner.Email,
            Approval_Status__c, Type__c, Account.Name, 
            Total_Capacity_in_MWp__c, TotalAmount,
            Account.BillingStreet, Account.BillingCity, Account.BillingState,
            Account.BillingPostalCode, Account.BillingCountry,Schema_Name__c,
            Product_type__c, Product_Category__c, Segment1__c, Product_Details_Technology_Type__c,
            DCR_Non_DCR1__c, Account.Phone, Account.Email__c,Tender_Number__c,
            Delivery_Required_By__c, Regional_Head_Email__c,Owner.UserRoleId,Owner.UserRole.DeveloperName
            FROM Order
            WHERE (Approval_Status__c = '' OR Approval_Status__c = null) AND RecordType.DeveloperName = 'Purchase_Order'
            AND (Type__c = 'Channel Sales' OR Type__c = 'Key Account Private' OR Type__c = 'Key Account Government')
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Order> scope) {
        List<Order> channelSalesOrders = new List<Order>();
        List<Order> keyAccountPrivateOrders = new List<Order>();
        List<Order> keyAccountGovernmentOrders = new List<Order>();
        
        for (Order o : scope) {
            if (o.Type__c == 'Channel Sales') {
                channelSalesOrders.add(o);
            } else if (o.Type__c == 'Key Account Private') {
                keyAccountPrivateOrders.add(o);
                // System.debug('keyAccountPrivateOrders--> '+ keyAccountPrivateOrders);
            } else if (o.Type__c == 'Key Account Government') {
                keyAccountGovernmentOrders.add(o);
            }
        }
        
        if (!channelSalesOrders.isEmpty()) {
            processChannelSalesOrders(channelSalesOrders);
        }
        
        if (!keyAccountPrivateOrders.isEmpty()) {
            processKeyAccountPrivateOrders(keyAccountPrivateOrders);
        }
        
        if (!keyAccountGovernmentOrders.isEmpty()) {
            processKeyAccountGovernmentOrders(keyAccountGovernmentOrders);
        }
    }
    
    private void processKeyAccountGovernmentOrders(List<Order> orders) {
        // Group orders by Regional Head Email
        Map<String, List<Order>> regionalHeadOrders = new Map<String, List<Order>>();
        
        for (Order o : orders) {
            if (String.isBlank(o.Regional_Head_Email__c)) continue;
            
            if (!regionalHeadOrders.containsKey(o.Regional_Head_Email__c)) {
                regionalHeadOrders.put(o.Regional_Head_Email__c, new List<Order>());
            }
            regionalHeadOrders.get(o.Regional_Head_Email__c).add(o);
        }
        
        // Prepare and send emails
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for (String regionalHeadEmail : regionalHeadOrders.keySet()) {
            List<Order> ordersForRegionalHead = regionalHeadOrders.get(regionalHeadEmail);
            
            String subject = 'Reminder for Sending for SO Creation';
            
            // Create table format for the email body with all orders
            String orderDetails = '';
            Integer serialNumber = 1;
            
            for (Order o : ordersForRegionalHead) {
                orderDetails += '<tr>' +
                    '<td>' + serialNumber + '</td>' +
                    '<td>' + o.Tender_Number__c + '</td>' + // Tender Number
                    '<td>' + (o.Account != null ? o.Account.Name : '') + '</td>' + // Customer Name
                    '<td>' + o.Product_type__c+ '</td>' + // Product Category
                    '<td>' +  o.Schema_Name__c + '</td>' + // Scheme Name
                    '</tr>';
                serialNumber++;
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
                '</tr>' +
                orderDetails + 
                '</table>' +
                '<p>Kindly go through the below link for more details about the Tender.</p>' +
                '<p><a href="' + getOrderLink() + '">Link to Salesforce page</a></p>' +
                '<p>Thank you.</p>' +
                '</body></html>';
            
            // Send email directly to the regional head
            emailsToSend.add(createEmailMessage(
                subject, 
                body, 
                new List<String>{regionalHeadEmail},
                new List<String>() // No CC for government orders
            ));
        }
        
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
    
    private void processChannelSalesOrders(List<Order> orders) {
        // First get all owner IDs
        Set<Id> ownerIds = new Set<Id>();
        for (Order o : orders) {
            ownerIds.add(o.OwnerId);
        }
        
        // Query users with their full manager hierarchy
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Email, Name, 
            Manager.Id, Manager.Name, Manager.Email,
            Manager.Manager.Id, Manager.Manager.Name, Manager.Manager.Email
            FROM User
            WHERE Id IN :ownerIds
        ]);
        
        // Get Channel Sales National Head email
        User nationalHead = [SELECT Email FROM User 
                             WHERE UserRole.DeveloperName = 'Channel_Sales_National_Head' 
                             LIMIT 1];
        String nationalHeadEmail = nationalHead.Email;
        
        // Group orders by Manager's Manager
        Map<String, List<Order>> managerManagerOrders = new Map<String, List<Order>>();
        
        for (Order o : orders) {
            User owner = userMap.get(o.OwnerId);
            if (owner == null || owner.Manager == null || owner.Manager.Manager == null) continue;
            
            String managerManagerEmail = owner.Manager.Manager.Email;
            if (String.isBlank(managerManagerEmail)) continue;
            
            if (!managerManagerOrders.containsKey(managerManagerEmail)) {
                managerManagerOrders.put(managerManagerEmail, new List<Order>());
            }
            managerManagerOrders.get(managerManagerEmail).add(o);
        }
        
        // Prepare and send emails with new template
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for (String managerManagerEmail : managerManagerOrders.keySet()) {
            List<Order> ordersForManager = managerManagerOrders.get(managerManagerEmail);
            String orderDetails = '';
            Integer serialNumber = 1;
            
            for (Order o : ordersForManager) {
                orderDetails += '<tr><td>' + serialNumber + '</td><td>' + 
                    (o.Account != null ? o.Account.Name : '') + '</td><td>' + 
                    (o.Total_Capacity_in_MWp__c != null ? o.Total_Capacity_in_MWp__c : 0) + '</td><td>' + 
                    (o.TotalAmount != null ? o.TotalAmount : 0) + '</td></tr>';
                serialNumber++;
            }
            
            String subject = 'Pending Distributor PO Request reminder';
            String managerName = userMap.get(ordersForManager[0].OwnerId).Manager.Manager.Name;
            
            String body = '<p>Dear ' + managerName + ',</p>' +
                '<p>The following customer PO\'s are pending for approval for SO creation.</p>' +
                '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse;">' +
                '<tr><th>S No.</th><th>Distributor Name</th><th>Total Capacity Wattage Wp</th>' +
                '<th>Total Value</th><th>Ledger Balance</th></tr>' +
                orderDetails + '</table>' +
                '<p>Kindly go through the below link to take further actions.</p>' +
                '<p><a href="' + getOrderLink() + '">Link to Salesforce Page</a></p>' +
                '<p>Thank you.</p>';
            
            emailsToSend.add(createEmailMessage(
                subject, 
                body, 
                new List<String>{managerManagerEmail},
                new List<String>{nationalHeadEmail}
            ));
        }
        
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
    
    private void processKeyAccountPrivateOrders(List<Order> orders) {
        // Query both National and International Heads
        Map<String, User> roleToHeadUser = new Map<String, User>();
        for (User u : [
            SELECT Id, Name, Email, UserRole.DeveloperName 
            FROM User 
            WHERE UserRole.DeveloperName IN ('National_Head_Key_Accounts_Private', 'Key_Accounts_International_Head_Private')
        ]) {
            roleToHeadUser.put(u.UserRole.DeveloperName, u);
        }
        System.debug('roleToHeadUser--> ' + roleToHeadUser);
        
        // Map to group orders for each Head (Key: Head Email + Regional Head Email)
        Map<String, List<Order>> headAndRegionalOrders = new Map<String, List<Order>>();
        
        for (Order o : orders) {
            if (String.isBlank(o.Regional_Head_Email__c) || o.Owner == null || o.Owner.UserRole == null) continue;
            
            String ownerRole = o.Owner.UserRole.DeveloperName;
            String headRole = ownerRole == 'Key_Account_International_Sales' 
                ? 'Key_Accounts_International_Head_Private' 
                : 'National_Head_Key_Accounts_Private';
            
            User headUser = roleToHeadUser.get(headRole);
            if (headUser == null) continue;
            
            String key = headUser.Email + '|' + o.Regional_Head_Email__c;
            
            if (!headAndRegionalOrders.containsKey(key)) {
                headAndRegionalOrders.put(key, new List<Order>());
            }
            headAndRegionalOrders.get(key).add(o);
        }
        
        System.debug('headAndRegionalOrders--> ' + headAndRegionalOrders);
        
        // Prepare and send emails
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for (String key : headAndRegionalOrders.keySet()) {
            List<Order> ordersGroup = headAndRegionalOrders.get(key);
            String[] parts = key.split('\\|');
            String headEmail = parts[0];
            String regionalHeadEmail = parts[1];
            String headName = '';
            
            // Get head name from roleToHeadUser map
            for (User u : roleToHeadUser.values()) {
                if (u.Email == headEmail) {
                    headName = u.Name;
                    break;
                }
            }
            
            String subject = 'Pending Customer PO Requests - Key Account Private';
            String orderDetails = '';
            Integer serialNumber = 1;
            
            for (Order o : ordersGroup) {
                orderDetails += '<tr>' +
                    '<td>' + serialNumber + '</td>' +
                    '<td>' + o.Name + '</td>' +
                    '<td>' + (o.Account != null ? o.Account.Name : '') + '</td>' +
                    '<td>' + formatAddress(o) + '</td>' +
                    '<td>' + safeValue(o.Product_Category__c) + '</td>' +
                    '<td>' + safeValue(o.Segment1__c) + '</td>' +
                    '<td>' + (o.Total_Capacity_in_MWp__c != null ? o.Total_Capacity_in_MWp__c + ' MWp' : '0') + '</td>' +
                    '<td>' + (o.Delivery_Required_By__c != null ? o.Delivery_Required_By__c.format() : '') + '</td>' +
                    '<td>' + o.Owner.Name + '</td>' +
                    '</tr>';
                serialNumber++;
            }
            
            String body = '<html><body>' +
                '<p>Dear ' + headName + ',</p>' +
                '<p>The following customer PO requests are pending for approval for SO creation:</p>' +
                '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">' +
                '<tr>' +
                '<th>S No.</th>' +
                '<th>PO Number</th>' +
                '<th>Customer Name</th>' +
                '<th>Address</th>' +
                '<th>Product Type</th>' +
                '<th>Segment</th>' +
                '<th>Total Capacity</th>' +
                '<th>Delivery Required By</th>' +
                '<th>Requested By</th>' +
                '</tr>' +
                orderDetails + 
                '</table>' +
                '<p>Kindly go through the below link to take further actions.</p>' +
                '<p><a href="' + getOrderLink() + '">Link to Salesforce Page</a></p>' +
                '<p>Thank you.</p>' +
                '</body></html>';
            
            emailsToSend.add(createEmailMessage(
                subject, 
                body, 
                new List<String>{headEmail},
                new List<String>{}
            ));
        }
        
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
            System.debug('emailsToSend--> '+ emailsToSend);
        }
    }
    
    
    private String formatAddress(Order o) {
        List<String> addressParts = new List<String>();
        if (o.Account.BillingStreet != null) addressParts.add(o.Account.BillingStreet);
        if (o.Account.BillingCity != null) addressParts.add(o.Account.BillingCity);
        if (o.Account.BillingState != null) addressParts.add(o.Account.BillingState);
        if (o.Account.BillingPostalCode != null) addressParts.add(o.Account.BillingPostalCode);
        if (o.Account.BillingCountry != null) addressParts.add(o.Account.BillingCountry);
        
        return String.join(addressParts, ' - ');
    }
    
    private String safeValue(Object value) {
        return value != null ? String.valueOf(value) : '';
    }
    
    private String getOrderLink() {
        return System.Url.getOrgDomainUrl().toExternalForm() + '/lightning/o/Order/list?filterName=__Recent';
    }
    
    private Messaging.SingleEmailMessage createEmailMessage(String subject, 
                                                            String body, 
                                                            List<String> toAddresses, 
                                                            List<String> ccAddresses) {
                                                                try {
                                                                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                                                    mail.setToAddresses(toAddresses);
                                                                    if (!ccAddresses.isEmpty()) {
                                                                        mail.setCcAddresses(ccAddresses);
                                                                    }
                                                                    mail.setSubject(subject);
                                                                    mail.setSenderDisplayName('Premier Energies');
                                                                    mail.setHTMLBody(body);
                                                                    return mail;
                                                                } catch (Exception e) {
                                                                    System.debug('Error creating email: ' + e.getMessage());
                                                                    return null;
                                                                }
                                                            }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch process completed');
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new PurchaseOrderApprovalEmailNotification(), 200);
    }
}