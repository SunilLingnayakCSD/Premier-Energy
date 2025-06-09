public with sharing class EBITDAApprovalController {
  
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserRole() {
        User u = [SELECT UserRole.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.debug('### Current User Role: ' + u.UserRole != null ? u.UserRole.Name : 'No UserRole');
        return u.UserRole != null ? u.UserRole.Name : null;
    }

   
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunitiesForApproval(String userRole) {
        try {
            System.debug('### User Role Passed: ' + userRole);
            if (userRole == null) {
                throw new AuraHandledException('User role not provided');
            }

            List<Opportunity> allOpps = [
                SELECT Id, Name, Segment__c, DCR_Non_DCR__c, New_EBITDA_Margin__c,
                       Arrived_EBITDA__c, National_Head_Approval__c, MD_Approval__c,
                       RecordType.Name
                FROM Opportunity
                WHERE RecordType.Name = 'Key Account Private'
                AND (New_EBITDA_Margin__c != NULL OR Arrived_EBITDA__c != NULL)
            ];

            System.debug('### Total Opportunities Fetched: ' + allOpps.size());
            return filterOpportunities(allOpps, userRole);
        } catch (Exception e) {
            throw new AuraHandledException('Error getting opportunities: ' + e.getMessage());
        }
    }

    
    @AuraEnabled
    public static void updateApprovalStatus(Id opportunityId, String userRole, String status) {
        try {
            System.debug('### Updating Opportunity ID: ' + opportunityId + ' with Status: ' + status);
            Opportunity opp = [SELECT Id, National_Head_Approval__c, MD_Approval__c 
                               FROM Opportunity 
                               WHERE Id = :opportunityId];

            if (isNationalHead(userRole)) {
                opp.National_Head_Approval__c = status;
                System.debug('### National Head Approval updated for Opportunity: ' + opp.Id);
            } else if (userRole == 'Managing Director') {
                opp.MD_Approval__c = status;
                System.debug('### Managing Director Approval updated for Opportunity: ' + opp.Id);
            }

            update opp;
            System.debug('### Opportunity updated: ' + opp.Id);
        } catch (Exception e) {
            throw new AuraHandledException('Error updating approval status: ' + e.getMessage());
        }
    }

    // Helper: filter opportunities by role and thresholds
    private static List<Opportunity> filterOpportunities(List<Opportunity> allOpps, String userRole) {
        System.debug('### Filtering Opportunities based on role: ' + userRole);
        List<Opportunity> filteredOpps = new List<Opportunity>();

        for (Opportunity opp : allOpps) {
            Decimal margin = opp.New_EBITDA_Margin__c != null ? opp.New_EBITDA_Margin__c : opp.Arrived_EBITDA__c;
            String type = opp.DCR_Non_DCR__c;
            String segment = opp.Segment__c;
            System.debug('### Checking Opportunity: ' + opp.Name + ', Margin: ' + margin);

            if (isRegionalHead(userRole)) {
                Map<String, Decimal> thresholds = getSegmentThresholds(segment);
                if (thresholds.containsKey(type) && margin < thresholds.get(type)) {
                    filteredOpps.add(opp);
                    System.debug('### Opportunity added for Regional Head: ' + opp.Name);
                }
            } else if (isNationalHead(userRole) && opp.National_Head_Approval__c == null) {
                Map<String, Decimal> thresholds = getSegmentThresholds(segment);
                if (thresholds.containsKey(type) && margin < thresholds.get(type)) {
                    filteredOpps.add(opp);
                    System.debug('### Opportunity added for National Head: ' + opp.Name);
                }
            } else if (userRole == 'Managing Director' && opp.National_Head_Approval__c == 'Approved' && opp.MD_Approval__c == null) {
                Map<String, Decimal> thresholds = getAopThresholds(segment);
                if (thresholds.containsKey(type) && margin < thresholds.get(type)) {
                    filteredOpps.add(opp);
                    System.debug('### Opportunity added for Managing Director: ' + opp.Name);
                }
            }
        }

        System.debug('### Total Filtered Opportunities: ' + filteredOpps.size());
        return filteredOpps;
    }

    private static Boolean isRegionalHead(String role) {
        System.debug('### Checking if user is Regional Head: ' + role);
        return role != null && new Set<String>{
            'East Region Head, Key Account Private',
            'West Region Head, Key Account Private',
            'South Region Head, Key Account Private',
            'North Region Head, Key Account Private'
        }.contains(role);
    }

    private static Boolean isNationalHead(String role) {
        System.debug('### Checking if user is National Head: ' + role);
        return role != null && role == 'National Head, Key Accounts Private';
    }

    private static Map<String, Decimal> getSegmentThresholds(String segment) {
        System.debug('### Getting Segment Thresholds for Segment: ' + segment);
        Map<String, Decimal> thresholds = new Map<String, Decimal>{ 'DCR' => 0, 'NDCR' => 0 };

        if (segment != null) {
            for (Segment__mdt seg : Segment__mdt.getAll().values()) {
                if (seg.Label == segment) {
                    if (seg.DCR__c != null) thresholds.put('DCR', seg.DCR__c);
                    if (seg.NDCR__c != null) thresholds.put('NDCR', seg.NDCR__c);
                    break;
                }
            }
        }
        System.debug('### Segment Thresholds: ' + thresholds);
        return thresholds;
    }

    private static Map<String, Decimal> getAopThresholds(String segment) {
        System.debug('### Getting AOP Thresholds for Segment: ' + segment);
        Map<String, Decimal> thresholds = new Map<String, Decimal>{ 'DCR' => 0, 'NDCR' => 0 };

        if (segment != null) {
            for (AOP_EBITDA__mdt aop : AOP_EBITDA__mdt.getAll().values()) {
                if (aop.Label == segment) {
                    if (aop.DCR__c != null) thresholds.put('DCR', aop.DCR__c);
                    if (aop.NDCR__c != null) thresholds.put('NDCR', aop.NDCR__c);
                    break;
                }
            }
        }
        System.debug('### AOP Thresholds: ' + thresholds);
        return thresholds;
    }
}