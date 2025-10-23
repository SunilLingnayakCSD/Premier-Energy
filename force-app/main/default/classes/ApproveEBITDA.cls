public without sharing class ApproveEBITDA {
	@AuraEnabled(cacheable=true)
    public static String getCurrentUserRole() {
        return [
            SELECT UserRole.Name 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ].UserRole.Name;
    }

    @AuraEnabled(cacheable=true)
	public static List<Opportunity> getDomesticOppforNH(){

		List<Opportunity> OppDomesticNHreturn = new List<Opportunity>();
           Set<String> regionalRoles = new Set<String>{
                'East Region Head, Key Account Private',
                'West Region Head, Key Account Private',
                'South Region Head, Key Account Private',
                'North Region Head, Key Account Private'
                            };
           
            Set<Id> ownerIds = new Set<Id>();
            List<User> uu = [SELECT Id FROM User WHERE UserRole.Name IN :regionalRoles];
            for (User u:uu) {
                ownerIds.add(u.Id);
            }
		List<Opportunity> OppDomesticNH = [Select Id, Name, StageName, Segment1__c, DCR_Non_DCR1__c,
           Manual_EBIDTA__c, Approval_Comments__c, Escalation_Comments__c,KAM_Proposed_Unit__c,
           Price_Rejection_Reason__c, MD_Approval_Comments__c, MD_Rejection_Reason__c,
           Discounted_Wp_Price__c, Final_Wp_price__c, New_EBITDA__c, Arrived_EBITDA_Per__c,AOP_Ebitda__c,
           National_Head_Approval__c, MD_Approval__c, Product_Category1__c, Domestic_Exports__c,
           Owner.UserRole.Name, Price_Validation__c
    FROM Opportunity Where StageName = 'Price Approval & Proposal Submission' AND Product_Category1__c = 'Module' AND Domestic_Exports__c = 'Domestic'
	 AND OwnerId In:ownerIds AND National_Head_Approval__c = 'Sent for Approval'] ;
		
		return OppDomesticNH;
	}

    @AuraEnabled(cacheable=true)
	public static List<Opportunity> getCellDomesticOppforNH(){
		List<Opportunity> OppCellExportNHreturn = new List<Opportunity>();
        Set<String> regionalRoles = new Set<String>{
                'East Region Head, Key Account Private',
                'West Region Head, Key Account Private',
                'South Region Head, Key Account Private',
                'North Region Head, Key Account Private'
                            };
           
            Set<Id> ownerIds = new Set<Id>();
            List<User> uu = [SELECT Id FROM User WHERE UserRole.Name IN :regionalRoles];
            for (User u:uu) {
                ownerIds.add(u.Id);
            }
		List<Opportunity> OppDomesticNH = [Select Id, Name, StageName, Segment1__c, DCR_Non_DCR1__c,
           Manual_EBIDTA__c, Approval_Comments__c, Escalation_Comments__c,KAM_Proposed_Unit__c,
           Price_Rejection_Reason__c, MD_Approval_Comments__c, MD_Rejection_Reason__c,
           Discounted_Wp_Price__c, Final_Wp_price__c, New_EBITDA__c, Arrived_EBITDA_Per__c,AOP_Ebitda__c,
           National_Head_Approval__c, MD_Approval__c, Product_Category1__c, Domestic_Exports__c,
           Owner.UserRole.Name, Price_Validation__c
    FROM Opportunity Where StageName = 'Price Approval & Proposal Submission' AND Product_Category1__c = 'Cell' AND Domestic_Exports__c = 'Domestic'
	AND Discounted_Wp_Price__c != NULL AND OwnerId In:ownerIds AND National_Head_Approval__c = 'Sent for Approval'];
		for(Opportunity o:OppDomesticNH){
				OppCellExportNHreturn.add(o);
		}
		return OppCellExportNHreturn;
	}

     @AuraEnabled(cacheable=true)
	public static List<Opportunity> getDomesticOppforMD(){

		List<Opportunity> OppDomesticMDreturn = new List<Opportunity>();
           Set<String> regionalRoles = new Set<String>{
                'East Region Head, Key Account Private',
                'West Region Head, Key Account Private',
                'South Region Head, Key Account Private',
                'North Region Head, Key Account Private'
                            };
           
            Set<Id> ownerIds = new Set<Id>();
            List<User> uu = [SELECT Id FROM User WHERE UserRole.Name IN :regionalRoles];
            for (User u:uu) {
                ownerIds.add(u.Id);
            }
		List<Opportunity> OppDomesticNH = [Select Id, Name, StageName, Segment1__c, DCR_Non_DCR1__c,
           Manual_EBIDTA__c, Approval_Comments__c, Escalation_Comments__c,KAM_Proposed_Unit__c,
           Price_Rejection_Reason__c, MD_Approval_Comments__c, MD_Rejection_Reason__c,
           Discounted_Wp_Price__c, Final_Wp_price__c, New_EBITDA__c, Arrived_EBITDA_Per__c,AOP_Ebitda__c,
           National_Head_Approval__c, MD_Approval__c, Product_Category1__c, Domestic_Exports__c,
           Owner.UserRole.Name, Price_Validation__c
    FROM Opportunity Where StageName = 'Price Approval & Proposal Submission' AND Product_Category1__c = 'Module' AND Domestic_Exports__c = 'Domestic'
	 AND OwnerId In:ownerIds AND National_Head_Approval__c = 'Escalated' AND MD_Approval__c = 'Sent for Approval'] ;
		
		return OppDomesticNH;
	}

     @AuraEnabled(cacheable=true)
	public static List<Opportunity> getModuleCellExportOppforMD(){
		List<Opportunity> OppModuleCellExportMDreturn = new List<Opportunity>();
        Set<String> regionalRoles = new Set<String>{
                'East Region Head, Key Account Private',
                'West Region Head, Key Account Private',
                'South Region Head, Key Account Private',
                'North Region Head, Key Account Private',
                'Key Account International Sales'
                            };
           
            Set<Id> ownerIds = new Set<Id>();
            List<User> uu = [SELECT Id FROM User WHERE UserRole.Name IN :regionalRoles];
            for (User u:uu) {
                ownerIds.add(u.Id);
            }
		List<Opportunity> OppDomesticNH = [
    SELECT Id, Name, StageName, Segment1__c, DCR_Non_DCR1__c,
           Manual_EBIDTA__c, Approval_Comments__c, Escalation_Comments__c, KAM_Proposed_Unit__c,
           Price_Rejection_Reason__c, MD_Approval_Comments__c, MD_Rejection_Reason__c,
           Discounted_Wp_Price__c, Final_Wp_price__c, New_EBITDA__c, Arrived_EBITDA_Per__c,AOP_Ebitda__c,
           National_Head_Approval__c, MD_Approval__c, Product_Category1__c, Domestic_Exports__c,
           Owner.UserRole.Name, Price_Validation__c
    FROM Opportunity
    WHERE StageName = 'Price Approval & Proposal Submission'
        AND ((Product_Category1__c = 'Cell' AND Domestic_Exports__c = 'Domestic')
        OR (Product_Category1__c = 'Cell' AND Domestic_Exports__c = 'Exports')
        OR (Product_Category1__c = 'Module' AND Domestic_Exports__c = 'Exports'))
        AND Discounted_Wp_Price__c != NULL AND National_Head_Approval__c = 'Escalated' AND OwnerId In:ownerIds AND MD_Approval__c = 'Sent for Approval'
];

		for(Opportunity o:OppDomesticNH){
				OppModuleCellExportMDreturn.add(o);
		}
		return OppModuleCellExportMDreturn;
	}

    @AuraEnabled(cacheable=true)
	public static List<Opportunity> getEportCellModuleInternational(){
		List<Opportunity> OppModuleCellExportInternationalreturn = new List<Opportunity>();
        Set<String> regionalRoles = new Set<String>{'Key Account International Sales'
                            };
           
            Set<Id> ownerIds = new Set<Id>();
            List<User> uu = [SELECT Id FROM User WHERE UserRole.Name IN :regionalRoles];
            for (User u:uu) {
                ownerIds.add(u.Id);
            }
		List<Opportunity> OppDomesticNH = [Select Id, Name, StageName, Segment1__c, DCR_Non_DCR1__c,
           Manual_EBIDTA__c, Approval_Comments__c, Escalation_Comments__c,KAM_Proposed_Unit__c,
           Price_Rejection_Reason__c, MD_Approval_Comments__c, MD_Rejection_Reason__c,
           Discounted_Wp_Price__c, Final_Wp_price__c, New_EBITDA__c, Arrived_EBITDA_Per__c,AOP_Ebitda__c,
           National_Head_Approval__c, MD_Approval__c, Product_Category1__c, Domestic_Exports__c,
           Owner.UserRole.Name, Price_Validation__c
    FROM Opportunity Where StageName = 'Price Approval & Proposal Submission' AND (Product_Category1__c = 'Cell' OR Product_Category1__c = 'Module') AND Domestic_Exports__c = 'Exports'
	AND Discounted_Wp_Price__c != NULL AND OwnerId In:ownerIds AND National_Head_Approval__c = 'Sent for Approval'];
		for(Opportunity o:OppDomesticNH){
				OppModuleCellExportInternationalreturn.add(o);
		}
		return OppModuleCellExportInternationalreturn;
	}

     @AuraEnabled
	public static String approveDomesticByNH(Id OppId){
	 Opportunity updateOpp = [Select Id, Name, StageName, Segment1__c, 
     DCR_Non_DCR1__c,National_Head_Approval__c,Manual_EBIDTA__c,Domestic_Exports__c,Product_Category1__c
      FROM Opportunity Where Id =: OppId];
      System.debug('manual ebitda-->'+updateOpp.Manual_EBIDTA__c);
     if(((updateOpp.Product_Category1__c == 'CELL' && updateOpp.Domestic_Exports__c == 'Exports') || (updateOpp.Product_Category1__c == 'CELL' && updateOpp.Domestic_Exports__c == 'Domestic') || (updateOpp.Product_Category1__c == 'Module' && updateOpp.Domestic_Exports__c == 'Exports')) && (updateOpp.Manual_EBIDTA__c == null)){
        return 'notapproved';
     }else{
        updateOpp.National_Head_Approval__c = 'Approved';
        update updateOpp;
        return 'approved';
     }
        
	}

     @AuraEnabled
	public static String approveDomesticByMD(Id OppId){
	 Opportunity updateOpp = [Select Id, Name, StageName, 
     Segment1__c, DCR_Non_DCR1__c,MD_Approval__c ,Manual_EBIDTA__c,Domestic_Exports__c,Product_Category1__c
     FROM Opportunity Where Id =: OppId];
     if(((updateOpp.Product_Category1__c == 'CELL' && updateOpp.Domestic_Exports__c == 'Exports') || (updateOpp.Product_Category1__c == 'CELL' && updateOpp.Domestic_Exports__c == 'Domestic') || (updateOpp.Product_Category1__c == 'Module' && updateOpp.Domestic_Exports__c == 'Exports')) && (updateOpp.Manual_EBIDTA__c == null)){
        return 'notapproved';
     }else{
        updateOpp.MD_Approval__c = 'Approved';
        update updateOpp;
        return 'approved';
     }
        
	}

     @AuraEnabled
	public static void rejectOpportunity(Id OppId, String comment){
	 Opportunity updateOpp = [Select Id, Name, StageName, Segment1__c, DCR_Non_DCR1__c,National_Head_Approval__c,Price_Rejection_Reason__c,PricingUpdatedByKAM__c FROM Opportunity Where Id =:OppId];
        updateOpp.National_Head_Approval__c = 'Rejected';
        updateOpp.Price_Rejection_Reason__c = comment;
        updateOpp.PricingUpdatedByKAM__c = true;
        update updateOpp;
	}

     @AuraEnabled
	public static void rejectOpportunitybyMD(Id OppId, String comment){
	 Opportunity updateOpp = [Select Id, Name, StageName, Segment1__c, DCR_Non_DCR1__c,MD_Approval__c,MD_Rejection_Reason__c,PricingUpdatedByKAM__c FROM Opportunity Where Id =:OppId];
        updateOpp.MD_Approval__c = 'Rejected';
        updateOpp.MD_Rejection_Reason__c = comment;
        updateOpp.PricingUpdatedByKAM__c = true;
        update updateOpp;
	}

     @AuraEnabled
	public static String escalateOpportunity(Id OppId, String comment){
	 Opportunity updateOpp = [Select Id, Name, StageName, Segment1__c, DCR_Non_DCR1__c,
     National_Head_Approval__c,Escalation_Comments__c,MD_Approval__c,Manual_EBIDTA__c,Domestic_Exports__c,Product_Category1__c
      FROM Opportunity Where Id =:OppId];
     if(((updateOpp.Product_Category1__c == 'CELL' && updateOpp.Domestic_Exports__c == 'Exports') || (updateOpp.Product_Category1__c == 'CELL' && updateOpp.Domestic_Exports__c == 'Domestic') || (updateOpp.Product_Category1__c == 'Module' && updateOpp.Domestic_Exports__c == 'Exports')) && (updateOpp.Manual_EBIDTA__c == null)){
        return 'notapproved';
     }else{
        updateOpp.National_Head_Approval__c = 'Escalated';
        updateOpp.MD_Approval__c = 'Sent for Approval';
        updateOpp.Escalation_Comments__c = comment;
        update updateOpp;
        return 'approved';
     }
       
	}

     @AuraEnabled
    public static void saveManualEbita(List<Opportunity> updatedOppList) {
        if (updatedOppList == null || updatedOppList.isEmpty()) {
            return;
        }
        try {
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Opportunity opp : updatedOppList) {
                Opportunity oppToUpdate = new Opportunity(
                    Id = opp.Id,
                    Manual_EBIDTA__c = opp.Manual_EBIDTA__c
                );
                oppsToUpdate.add(oppToUpdate);
            }
            update oppsToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating Manual EBITDA: ' + e.getMessage());
        }
    }
    
}