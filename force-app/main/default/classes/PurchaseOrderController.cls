public without sharing class PurchaseOrderController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPurchaseOrders() {
        Map<String, Object> result = new Map<String,Object>(); 
        try {
            User currentUser = [SELECT Id, UserRole.DeveloperName, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            String userRoleName = currentUser.UserRole?.Name ?? '';
            System.debug('Current User Role: ' + userRoleName);

            Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
                .get('Purchase_Order').getRecordTypeId();
            System.debug('Purchase Order RecordTypeId: ' + purchaseOrderRecordTypeId);

            List<Order> orders = new List<Order>();
            
            switch on userRoleName {
                when 'National Head, Key Accounts Private' {
                    System.debug('Fetching orders for National Head, Key Accounts Private');
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Type__c, Reason_For_Rejection__c, Status, Grand_Total__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND ((Type__c = 'Key Account Private' AND (BillingCountry = 'India' OR ShippingCountry = 'India'))
                            OR (Type__c = 'Key Account Government' AND Product_Type__c = 'Modules'))
                        AND Approval_Status__c = null
                        AND Status = 'Draft'
                    ];
                }
                when 'Key Accounts International Head Private' {
                    System.debug('Fetching orders for Key Accounts International Head Private');
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Type__c, Reason_For_Rejection__c, Status, Grand_Total__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND Type__c = 'Key Account Private'
                        AND (BillingCountry != 'India' AND ShippingCountry != 'India')
                        AND Approval_Status__c = null
                        AND Status = 'Draft'
                    ];
                }
                when 'East Region Head, Channel Sales' {
                    System.debug('Fetching orders for East Region Head, Channel Sales');
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Type__c, Reason_For_Rejection__c, Status, Grand_Total__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND Type__c = 'Channel Sales'
                        AND Region__c LIKE '%East%'
                        AND Approval_Status__c = null
                        AND Status = 'Draft'
                    ];
                }
                when 'North Region Head, Channel Sales' {
                    System.debug('Fetching orders for North Region Head, Channel Sales');
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Type__c, Reason_For_Rejection__c, Status, Grand_Total__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND Type__c = 'Channel Sales'
                        AND Region__c LIKE '%North%'
                        AND Approval_Status__c = null
                        AND Status = 'Draft'
                    ];
                }
                when 'South Region Head, Channel Sales' {
                    System.debug('Fetching orders for South Region Head, Channel Sales');
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Type__c, Reason_For_Rejection__c,Status, Grand_Total__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND Type__c = 'Channel Sales'
                        AND Region__c LIKE '%South%'
                        AND Approval_Status__c = null
                        AND Status = 'Draft'
                    ];
                }
                when 'West Region Head, Channel Sales' {
                    System.debug('Fetching orders for West Region Head, Channel Sales');
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Type__c, Reason_For_Rejection__c, Status, Grand_Total__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND Type__c = 'Channel Sales'
                        AND Region__c LIKE '%West%'
                        AND Approval_Status__c = null
                        AND Status = 'Draft'
                    ];
                }
                when 'Chief Strategy Officer' {
                    System.debug('Fetching orders for Chief Strategy Officer');
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Type__c, Reason_For_Rejection__c, Status, Grand_Total__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND Type__c = 'Key Account Government'
                        AND Product_Type__c = 'EPC'
                        AND Approval_Status__c = null
                        AND Status = 'Draft'
                    ];
                }
                when 'Government Projects - Solar Pumps 1' {
                    System.debug('Fetching orders for Government Projects - Solar Pumps 1');
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, Total_Capacity_in_MWp__c,
                               Account.Name, Type__c, Reason_For_Rejection__c, Status, Grand_Total__c
                        FROM Order
                        WHERE RecordTypeId = :purchaseOrderRecordTypeId
                        AND Type__c = 'Key Account Government'
                        AND Product_Type__c = 'Water Pump'
                        AND Approval_Status__c = null
                        AND Status = 'Draft'
                    ];
                }
                when else {
                    System.debug('No matching user role. Returning empty order list.');
                    orders = new List<Order>();
                }
            }

            System.debug('Number of orders fetched: ' + orders.size());
            result.put('orders', orders);
            result.put('userRoleName', userRoleName);
            return result;
            
        } catch(Exception e) {
            System.debug('Exception in getPurchaseOrders: ' + e.getMessage());
            throw new AuraHandledException('Error fetching purchase orders: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateApprovalStatus(Id orderId, String status, String rejectionReason) {
        try {
            System.debug('Updating approval status for Order ID: ' + orderId);
            System.debug('New status: ' + status);
            System.debug('Rejection reason: ' + rejectionReason);

            Order ord = [SELECT Id, Approval_Status__c, Reason_For_Rejection__c FROM Order WHERE Id = :orderId LIMIT 1];
            ord.Approval_Status__c = status;

            if (status == 'Rejected') {
                ord.Reason_For_Rejection__c = rejectionReason;
                System.debug('Setting rejection reason.');
            } else {
                ord.Reason_For_Rejection__c = null;
                System.debug('Clearing rejection reason.');
            }

            update ord;
            System.debug('Order updated successfully.');

        } catch(Exception e) {
            System.debug('Exception in updateApprovalStatus: ' + e.getMessage());
            throw new AuraHandledException('Error updating approval status: ' + e.getMessage());
        }
    }
}