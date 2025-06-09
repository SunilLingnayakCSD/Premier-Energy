/**
* @File Name : pricingconfigurationApexClass.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : May 27, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 27, 2025 |   | Initial Version
**/

public class pricingconfigurationApexClass {
	@AuraEnabled(cacheable=true)
	public static List<Raw_Materials__c> get20FtAnd40Ft()
	{
		return [SELECT ID,Name,Qty_20_Ft__c,Qty_40_Ft__c,UOM__c,Sort__c FROM Raw_Materials__c ORDER BY Sort__c ASC];
	}
}