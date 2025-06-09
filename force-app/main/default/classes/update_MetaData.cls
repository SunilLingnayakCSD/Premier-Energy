public with sharing class update_MetaData {
    @AuraEnabled(cacheable=true)
    public static List<Input_Admin__mdt> metadataUpdate() {
        return [
            SELECT Id, MasterLabel, DeveloperName, 
                   USD_to_INR_CBITC__c, Overhead_cost_mdt__c, Finance_Cost__c,
                   Cell_Overhead_Cost__c, RFIDreadercost__c, ModuleWarrantyInsurance__c,
                   LCinterestcostPA__c, InsurnacePremiumcost__c, GST__c,
                   B_Grade_Module_Yield__c, B_Grade_Module_Discount__c,
                   ABGPBGCostPA__c, Cell_Finance_Cost__c, Cell_BOM_Cost__c
            FROM Input_Admin__mdt
            WHERE DeveloperName = 'default'
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static void updateMetadata(Input_Admin__mdt params) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'Input_Admin__mdt.default';
        customMetadata.label = 'default';

        Map<String, Object> fieldMap = params.getPopulatedFieldsAsMap();
        
        for (String fieldName : fieldMap.keySet()) {
            if (fieldName == 'Id' || fieldName == 'DeveloperName' || fieldName == 'MasterLabel') continue;
            
            Metadata.CustomMetadataValue val = new Metadata.CustomMetadataValue();
            val.field = fieldName;
            val.value = fieldMap.get(fieldName);
            customMetadata.values.add(val);
        }

        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        
        if (!Test.isRunningTest()) {
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, null); 
        }
    }
}