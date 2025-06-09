/**
* @File Name : inputInboundApex.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : April 17, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 17, 2025 |   | Initial Version
**/

public class inputInboundApex {
	@AuraEnabled(cacheable=true)
	public static List<Raw_Materials__c> inboundInput()
	{
		return [SELECT Sort__C,Name,China_ADD__c,China_AIDC__c,China_BCD__c,China_CVD__c,China_SWS__c,Malaysia_CVD__c,
				 Malaysia_BCD__c,Malaysia_AIDC__c,Malaysia_ADD__c,Vietnam_AIDC__c,Vietnam_Bcd__c,Vietnam_CVD__c,
				 Vietnam_ADD__c FROM Raw_Materials__c order by Sort__c ASC]; 
	}
	@AuraEnabled
    public static void updateInboundInput(List<Raw_Materials__c> recordsToUpdate) {
        try {
            update recordsToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating records: ' + e.getMessage());
        }
    }
}