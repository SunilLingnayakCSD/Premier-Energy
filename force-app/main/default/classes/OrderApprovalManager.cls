public class OrderApprovalManager {

    // Method to fetch Orders needing approval
    public static List<Order> getPendingModuleOrders() {
        return [
            SELECT Id, Name, Product_Type__c, Approval_Status__c
            FROM Order
            WHERE Product_Type__c = 'Modules' AND Approval_Status__c = null
        ];
    }

    // Method to get Users by Role DeveloperName
    public static List<User> getUsersByRoleDeveloperName(String roleDevName) {
        return [
            SELECT Id, Name, UserRole.DeveloperName
            FROM User
            WHERE UserRole.DeveloperName = :roleDevName AND IsActive = true 
        ];
    }

    // Method to approve an Order by a National Head
    public static void approveOrderByNationalHead(Id orderId, Id approverId) {
        Order ord = [SELECT Id, Product_Type__c, Approval_Status__c FROM Order WHERE Id = :orderId LIMIT 1];
		
        // Check if it's a module order and pending
        if(ord.Product_Type__c == 'Modules' && ord.Approval_Status__c == null) {
            // Validate approver is a National Head
            User approver = [SELECT Id, Name, UserRole.DeveloperName FROM User WHERE Id = :approverId LIMIT 1];

            if(approver.UserRole != null && approver.UserRole.DeveloperName == 'National_Head_Key_Accounts_Private') {
                // Approve the order
                ord.Approval_Status__c = 'Approved';
                update ord;

                // Now assign to MD — fetch MD users
                List<User> mds = getUsersByRoleDeveloperName('Managing_Director');
                if(!mds.isEmpty()) {
                    // Future implementation — notify MD
                    System.debug('Order assigned to MD for final approval: ' + mds[0].Name);
                }
            } else {
                throw new AuraHandledException('Approver is not authorized as National Head.');
            }
        } else {
            throw new AuraHandledException('Order is not eligible for National Head approval.');
        }
    }

    // Method for MD to give final approval or rejection
    public static void finalDecisionByMD(Id orderId, Id approverId, String decision) {
        if(decision != 'Approved' && decision != 'Rejected') {
            throw new AuraHandledException('Invalid decision. Must be Approved or Rejected.');
        }

        Order ord = [SELECT Id, Product_Type__c, Approval_Status__c FROM Order WHERE Id = :orderId LIMIT 1];

        // Check if order is eligible
        if(ord.Product_Type__c == 'Modules' && ord.Approval_Status__c == 'Approved') {
            // Validate approver is an MD
            User approver = [SELECT Id, Name, UserRole.DeveloperName FROM User WHERE Id = :approverId LIMIT 1];

            if(approver.UserRole != null && approver.UserRole.DeveloperName == 'Managing_Director') {
                // MD gives final decision
                ord.Approval_Status__c = decision;
                update ord;
            } else {
                throw new AuraHandledException('Approver is not authorized as Managing Director.');
            }
        } else {
            throw new AuraHandledException('Order is not eligible for MD decision.');
        }
    }
}