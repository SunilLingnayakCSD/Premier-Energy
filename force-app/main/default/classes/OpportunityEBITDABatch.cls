public class OpportunityEBITDABatch implements Database.Batchable<SObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Name, Segment__c, New_EBITDA_Margin__c, DCR_Non_DCR__c,
            Customer_Name__c, Product_Type__c, Product_Details__c,
            Capacity_in_MWp__c, Delivery_Required_By__c,
            Arrived_EBITDA__c, Final_WP__c, National_Head_Approval__c,
            MD_Approval__c
            FROM Opportunity
            WHERE (
                (New_EBITDA_Margin__c != null AND National_Head_Approval__c = null AND Segment__c != null AND DCR_Non_DCR__c != null)
                OR
                (National_Head_Approval__c = 'Approved' AND MD_Approval__c = null)
            )
            AND RecordType.DeveloperName = 'Key_Account_Private'
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        Map<String, Segment__mdt> segmentMap = Segment__mdt.getAll();
        Map<String, AOP_EBITDA__mdt> aopMap = AOP_EBITDA__mdt.getAll();
        
        List<Opportunity> nationalHeadAlertOpps = new List<Opportunity>();
        List<Opportunity> mdAlertOpps = new List<Opportunity>();
        Map<Id, Decimal> thresholdMap = new Map<Id, Decimal>();
        
        for (Opportunity opp : scope) {
            String devName = getDeveloperNameFromSegment(opp.Segment__c);
            if (String.isBlank(devName)) continue;
            
            if (opp.National_Head_Approval__c == null) {
                Segment__mdt seg = segmentMap.get(devName);
                if (seg == null) continue;
                
                Decimal threshold = (opp.DCR_Non_DCR__c == 'DCR') ? seg.DCR__c : seg.NDCR__c;
                if (threshold != null && opp.New_EBITDA_Margin__c < threshold) {
                    nationalHeadAlertOpps.add(opp);
                    thresholdMap.put(opp.Id, threshold);
                }
            } else if (opp.National_Head_Approval__c == 'Approved' && opp.MD_Approval__c == null) {
                AOP_EBITDA__mdt aopSeg = aopMap.get(devName);
                if (aopSeg == null) continue;
                
                Decimal aopThreshold = (opp.DCR_Non_DCR__c == 'DCR') ? aopSeg.DCR__c : aopSeg.NDCR__c;
                if (aopThreshold != null && opp.New_EBITDA_Margin__c < aopThreshold) {
                    mdAlertOpps.add(opp);
                    thresholdMap.put(opp.Id, aopThreshold);
                }
            }
        }
        
        User nationalHead = getNationalHeadUser();
        User mdUser = getMDUser();
        
        if (!nationalHeadAlertOpps.isEmpty()) {
            sendConsolidatedEmail(
                nationalHeadAlertOpps,
                thresholdMap,
                'Pending Price Change Request Reminder - National Head',
                nationalHead,
                new List<String>()
            );
        }
        
        if (!mdAlertOpps.isEmpty()) {
            sendConsolidatedEmail(
                mdAlertOpps,
                thresholdMap,
                'Pending Price Change Request Reminder - MD Approval',
                mdUser,
                new List<String>{ nationalHead.Email }
            );
        }
    }
    
    private void sendConsolidatedEmail(List<Opportunity> opps, Map<Id, Decimal> thresholdMap, String subject, User toUser, List<String> ccAddresses) {
        Integer serial = 1;
        String tableRows = '';
        
        for (Opportunity opp : opps) {
            Decimal threshold = thresholdMap.get(opp.Id);
            tableRows += '<tr>' +
                '<td>' + serial++ + '</td>' +
                '<td>' + opp.Name + '</td>' +
                '<td>' + opp.Product_Type__c + '</td>' +
                '<td>' + opp.Segment__c + '</td>' +
                '<td>' + opp.Product_Details__c + '</td>' +
                '<td>' + opp.DCR_Non_DCR__c + '</td>' +
                '<td>' + (opp.Capacity_in_MWp__c != null ? opp.Capacity_in_MWp__c + ' Wp' : '') + '</td>' +
                '<td>' + (opp.Delivery_Required_By__c != null ? opp.Delivery_Required_By__c.format() : '') + '</td>' +
                '<td>' + (opp.Final_WP__c != null ? '₹ ' + opp.Final_WP__c : '') + '</td>' +
                '<td>' + (opp.Arrived_EBITDA__c != null ? opp.Arrived_EBITDA__c + '%' : '') + '</td>' +
                '<td>' + (opp.Final_WP__c != null ? '₹ ' + opp.Final_WP__c : '') + '</td>' +
                '<td>' + (opp.New_EBITDA_Margin__c != null ? opp.New_EBITDA_Margin__c + '%' : '') + '</td>' +
                '</tr>';
        }
        
        String link = System.Url.getOrgDomainUrl().toExternalForm() + '/lightning/o/Opportunity/list';
        String body = '<html><body>' +
            '<p>Dear ' + toUser.Name + ',</p>' +
            '<p>The following price change approvals are pending.</p>' +
            '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">' +
            '<tr>' +
            '<th>S No.</th>' +
            '<th>Customer Name</th>' +
            '<th>Product Type</th>' +
            '<th>Segment</th>' +
            '<th>Product Details</th>' +
            '<th>DCR/Non-DCR</th>' +
            '<th>Total Capacity Wattage (Wp)</th>' +
            '<th>Delivery Required By</th>' +
            '<th>Existing Price*</th>' +
            '<th>Existing EBITDA%</th>' +
            '<th>New Price*</th>' +
            '<th>New EBITDA%</th>' +
            '</tr>' +
            tableRows +
            '</table>' +
            '<p>Kindly go through the below link to take further actions:<br>' +
            '<a href="' + link + '">Salesforce Opportunities</a></p>' +
            '<p>Thank you.</p>' +
            '</body></html>';
        
        Messaging.SingleEmailMessage mail = createEmailMessage(
            subject, body, new List<String>{ toUser.Email }, ccAddresses
        );
        
        if (mail != null) {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }
    
    private User getNationalHeadUser() {
        return [SELECT Name, Email FROM User 
                WHERE UserRole.DeveloperName = 'National_Head_Key_Accounts_Private' 
                AND IsActive = true LIMIT 1];
    }
    
    private User getMDUser() {
        return [SELECT Name, Email FROM User 
                WHERE UserRole.DeveloperName = 'Managing_Director' 
                AND IsActive = true LIMIT 1];
    }
    
    private String getDeveloperNameFromSegment(String segmentLabel) {
        if (segmentLabel == null) return null;
        
        Map<String, String> mapping = new Map<String, String>{
            'Cell / Domestic' => 'Cell_Domestic',
                'Cell / Export' => 'Cell_Export',
                'Module / Domestic / C&I' => 'Module_Domestic_C_I',
                'Module / Domestic / Govt. Scheme' => 'Module_Domestic_Govt_Scheme',
                'Module / Domestic / IPP-Utility' => 'Module_Domestic_IPP_Utility',
                'Module / Domestic / OEM' => 'Module_Domestic_OEM',
                'Module / Domestic / Residential_CH' => 'Module_Domestic_Residential_CH',
                'Module / Export / C&I' => 'Module_Export_C_I',
                'Module / Export / IPP-Utility' => 'Module_Export_IPP_Utility',
                'Module / Export / OEM' => 'Module_Export_OEM',
                'Module / Export / Residential' => 'Module_Export_Residential',
                'Module / Domestic / Others' => 'Module_Domestic_Others'
                };
                    
                    return mapping.get(segmentLabel);
    }
    
    private Messaging.SingleEmailMessage createEmailMessage(String subject, String body, List<String> toAddresses, List<String> ccAddresses) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toAddresses);
            if (!ccAddresses.isEmpty()) {
                email.setCcAddresses(ccAddresses);
            }
            email.setSubject(subject);
            email.setHtmlBody(body);
            email.setSenderDisplayName('Premier Energies');
            return email;
        } catch (Exception ex) {
            System.debug('Error creating email: ' + ex.getMessage());
            return null;
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('EBITDA Margin CMDT & AOP Alert Batch Completed');
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new OpportunityEBITDABatch(), 200);
    }
}