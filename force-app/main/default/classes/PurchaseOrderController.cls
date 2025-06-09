public with sharing class PurchaseOrderController {
    // Get orders with filters
    @AuraEnabled(cacheable=true)
    public static List<Order> getOrders(String type, String region) {
        String query = 'SELECT Id, Name, Type__c, Region__c FROM Order';
        List<String> conditions = new List<String>();
        
        if (String.isNotBlank(type)) {
            conditions.add('Type__c = :type');
        }
        
        if (String.isNotBlank(region)) {
            conditions.add('Region__c = :region');
        }
        
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        return Database.query(query);
    }

    // Get picklist values
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistValues() {
        Map<String, List<String>> picklistValues = new Map<String, List<String>>();
        
        // Get Type picklist values
        List<String> typeValues = new List<String>();
        for (PicklistEntry entry : Order.Type__c.getDescribe().getPicklistValues()) {
            typeValues.add(entry.getValue());
        }
        picklistValues.put('type', typeValues);
        
        // Get Region picklist values
        List<String> regionValues = new List<String>();
        for (PicklistEntry entry : Order.Region__c.getDescribe().getPicklistValues()) {
            regionValues.add(entry.getValue());
        }
        picklistValues.put('region', regionValues);
        
        return picklistValues;
    }

    // Get purchase orders for approval
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPurchaseOrders() {
        Map<String, Object> result = new Map<String, Object>(); 
        
        try {
            User currentUser = [
                SELECT Id, UserRole.DeveloperName 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
            
            String userRoleName = currentUser.UserRole?.DeveloperName ?? '';
            
            Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
                .get('Purchase_Order').getRecordTypeId();
            
            List<Order> orders = new List<Order>();
            
            switch on userRoleName {
                when 'Managing_Director' {
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Approval_Status__c, Product_Type__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND Product_Type__c IN ('Modules', 'Water Pump')
                    ];
                }
                when 'National_Head_Key_Accounts_Private' {
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Approval_Status__c, Product_Type__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND Product_Type__c = 'Modules'
                    ];
                }
                when 'Chief_Strategy_Officer' {
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Approval_Status__c, Product_Type__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND Product_Type__c = 'EPC'
                    ];
                }
                when 'Government_Projects_Solar_Pumps_1' {
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Approval_Status__c, Product_Type__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND Product_Type__c = 'Water Pump'
                    ];
                }
                when 'CEO' {
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Approval_Status__c, Product_Type__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                    ];
                }
                when else {
                    orders = new List<Order>();
                }
            }
            
            result.put('orders', orders);
            result.put('userRoleName', userRoleName);
            return result;
            
        } catch(Exception e) {
            throw new AuraHandledException('Error fetching purchase orders: ' + e.getMessage());
        }
    }
    
    // Update approval status
    @AuraEnabled
    public static void updateApprovalStatus(Id orderId, String status) {
        try {
            Order ord = [SELECT Id, Approval_Status__c FROM Order WHERE Id = :orderId LIMIT 1];
            ord.Approval_Status__c = status;
            update ord;
        } catch(Exception e) {
            throw new AuraHandledException('Error updating approval status: ' + e.getMessage());
        }
    }

    // Fetch pending module orders
    @AuraEnabled(cacheable=true)
    public static List<Order> getPendingModuleOrders() {
        return [
            SELECT Id, Name, Product_Type__c, Approval_Status__c
            FROM Order
            WHERE Product_Type__c = 'Modules' AND Approval_Status__c = null
        ];
    }

    // Get users by role developer name
    @AuraEnabled(cacheable=true)
    public static List<User> getUsersByRoleDeveloperName(String roleDevName) {
        return [
            SELECT Id, Name, UserRole.DeveloperName
            FROM User
            WHERE UserRole.DeveloperName = :roleDevName AND IsActive = true 
        ];
    }

    // Approve order by National Head
    @AuraEnabled
    public static void approveOrderByNationalHead(Id orderId, Id approverId) {
        Order ord = [SELECT Id, Product_Type__c, Approval_Status__c FROM Order WHERE Id = :orderId LIMIT 1];
        
        if(ord.Product_Type__c == 'Modules' && ord.Approval_Status__c == null) {
            User approver = [SELECT Id, UserRole.DeveloperName FROM User WHERE Id = :approverId LIMIT 1];

            if(approver.UserRole != null && approver.UserRole.DeveloperName == 'National_Head_Key_Accounts_Private') {
                ord.Approval_Status__c = 'Approved';
                update ord;

                List<User> mds = getUsersByRoleDeveloperName('Managing_Director');
                if(!mds.isEmpty()) {
                    System.debug('Order assigned to MD: ' + mds[0].Name);
                }
            } else {
                throw new AuraHandledException('Approver is not authorized as National Head.');
            }
        } else {
            throw new AuraHandledException('Order not eligible for National Head approval.');
        }
    }

    // Final decision by MD
    @AuraEnabled
    public static void finalDecisionByMD(Id orderId, Id approverId, String decision) {
        if(decision != 'Approved' && decision != 'Rejected') {
            throw new AuraHandledException('Invalid decision. Must be Approved or Rejected.');
        }

        Order ord = [SELECT Id, Product_Type__c, Approval_Status__c FROM Order WHERE Id = :orderId LIMIT 1];

        if(ord.Product_Type__c == 'Modules' && ord.Approval_Status__c == 'Approved') {
            User approver = [SELECT Id, UserRole.DeveloperName FROM User WHERE Id = :approverId LIMIT 1];

            if(approver.UserRole != null && approver.UserRole.DeveloperName == 'Managing_Director') {
                ord.Approval_Status__c = decision;
                update ord;
            } else {
                throw new AuraHandledException('Approver not authorized as Managing Director.');
            }
        } else {
            throw new AuraHandledException('Order not eligible for MD decision.');
        }
    }
}