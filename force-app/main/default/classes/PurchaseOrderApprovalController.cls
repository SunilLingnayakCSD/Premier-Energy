public without sharing class PurchaseOrderApprovalController {
    public class OrderApproverWrapper {
        @AuraEnabled public List<Order> orders { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static OrderApproverWrapper getOrdersForCurrentApprover() {
        OrderApproverWrapper response = new OrderApproverWrapper();
        response.orders = new List<Order>();
        
        try {
            User currentUser = [SELECT Id, Username, UserRole.DeveloperName FROM User WHERE Id = :UserInfo.getUserId()];
            
            if (currentUser.UserRole == null) {
                return response;
            }
            
            String userRole = currentUser.UserRole.DeveloperName;
            
            // 1. National Head for Key Account Private (India)
            if (userRole == 'National_Head_Key_Accounts_Private') {
                response.orders = [
                    SELECT Id, OwnerId, Owner.Name, Owner.UserRole.Name, OrderNumber, TotalAmount,
                    Total_Capacity_in_MWp__c, Account.Name, Type__c, Reason_For_Rejection__c, Status,
                    Grand_Total__c, Rsm_Role__c, RSM_Name__c,Name
                    FROM Order
                    WHERE RecordType__c = 'Purchase Order'
                    AND Type__c = 'Key Account Private'
                    AND Approval_Status__c = null
                    AND (BillingCountry = 'India' OR ShippingCountry = 'India')
                    AND Status = 'Draft'
                    AND Owner.UserRole.DeveloperName IN (
                        'East_Region_Head_Key_Account_Private',
                        'North_Region_Head_Key_Account_Private',
                        'South_Region_Head_Key_Account_Private',
                        'West_Region_Head_Key_Account_Private'
                    )
                ];
            }
            // 2. International Head for Key Account Private
            else if (userRole == 'Key_Accounts_International_Head_Private') {
                response.orders = [
                    SELECT Id, OwnerId, Owner.Name, Owner.UserRole.Name, OrderNumber, TotalAmount,
                    Total_Capacity_in_MWp__c, Account.Name, Type__c, Reason_For_Rejection__c, Status,
                    Grand_Total__c, Rsm_Role__c, RSM_Name__c,Name
                    FROM Order
                    WHERE RecordType__c = 'Purchase Order'
                    AND Type__c = 'Key Account Private'
                    AND Approval_Status__c = null
                    AND (BillingCountry != 'India' AND ShippingCountry != 'India')
                    AND Status = 'Draft'
                    AND Owner.UserRole.DeveloperName = 'Key_Account_International_Sales'
                ];
            }
            // 3. Regional Heads for Channel Sales
            else if (userRole.endsWith('_Head_Channel_Sales')) {
                response.orders = [
                    SELECT Id, OwnerId, Owner.Name, Owner.UserRole.Name, OrderNumber, TotalAmount,
                    Total_Capacity_in_MWp__c, Account.Name, Type__c, Reason_For_Rejection__c, Status,
                    Grand_Total__c, Rsm_Role__c, RSM_Name__c,Name
                    FROM Order
                    WHERE RecordType__c = 'Purchase Order'
                    AND Type__c = 'Channel Sales'
                    AND Approval_Status__c = null
                    AND Status = 'Draft'
                    AND RSM_Name__c = :currentUser.Username
                    AND Rsm_Role__c = :userRole
                ];
            }
            
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching orders: ' + ex.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static void updateApprovalStatus(Id orderId, String status, String rejectionReason) {
        try {
            Order ord = [SELECT Id, Approval_Status__c, Reason_For_Rejection__c FROM Order WHERE Id = :orderId LIMIT 1];
            ord.Approval_Status__c = status;
            
            if (status == 'Rejected') {
                ord.Reason_For_Rejection__c = rejectionReason;
            } else {
                ord.Reason_For_Rejection__c = null;
            }
            
            update ord;
            
        } catch (Exception e) {
            System.debug('Error in updateApprovalStatus: ' + e.getMessage());
            throw new AuraHandledException('Error updating approval status: ' + e.getMessage());
        }
    }
}