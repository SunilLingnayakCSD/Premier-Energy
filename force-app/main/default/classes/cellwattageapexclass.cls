public class cellwattageapexclass {
    @AuraEnabled(cacheable=true)
    public static List<cellwattage__mdt> LightningStudio() {
        return [SELECT Cells_G12_TOPCON__c, Cells_G12R_TOPCON__c, 
                       Cells_M10_MonoPERC__c, Cells_M10_TOPCON__c, 
                       Cells_M10_TOPCONS__c 
                FROM cellwattage__mdt 
                WHERE MasterLabel = 'Cell Wattage Data'
                LIMIT 1];
    }

    @AuraEnabled
    public static void updateCellWattage(Decimal m10MonoPERC, Decimal m10Topcon,
                                        Decimal m10TopconPlus, Decimal g12rTopcon,
                                        Decimal g12Topcon) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'cellwattage__mdt.Cell_Wattage_Data';
        customMetadata.label = 'Cell Wattage Data';

        Map<String, Decimal> fieldMap = new Map<String, Decimal>{
            'Cells_M10_MonoPERC__c' => m10MonoPERC,
            'Cells_M10_TOPCON__c' => m10Topcon,
            'Cells_M10_TOPCONS__c' => m10TopconPlus,
            'Cells_G12R_TOPCON__c' => g12rTopcon,
            'Cells_G12_TOPCON__c' => g12Topcon
        };

        for(String field : fieldMap.keySet()) {
            Metadata.CustomMetadataValue value = new Metadata.CustomMetadataValue();
            value.field = field;
            value.value = fieldMap.get(field);
            customMetadata.values.add(value);
        }

        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        
        if(!Test.isRunningTest()) {
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, null);
        }
    }
}