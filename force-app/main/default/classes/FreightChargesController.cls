// FreightChargesController.cls
public with sharing class FreightChargesController {
    @AuraEnabled(cacheable=true)
    public static List<Freight_Charges__mdt> getFreightMetadata() {
        return [
            SELECT Id, MasterLabel, DeveloperName,
                Sea_Frieght_USD_20Ft__c, Sea_Frieght_USD_40Ft__c,
                Inland_Transport_INR_20Ft__c, Inland_Transport_INR_40Ft__c
            FROM Freight_Charges__mdt
            WHERE MasterLabel IN ('China', 'Vietnam', 'Malaysia')
            ORDER BY MasterLabel
        ];
    }

    @AuraEnabled
    public static void updateFreightMetadata(List<Freight_Charges__mdt> updatedRecords) {
        List<Metadata.CustomMetadata> mdList = new List<Metadata.CustomMetadata>();
        
        for(Freight_Charges__mdt record : updatedRecords) {
            Metadata.CustomMetadata cmdt = new Metadata.CustomMetadata();
            cmdt.fullName = 'Freight_Charges__mdt.' + record.DeveloperName;
            cmdt.label = record.MasterLabel;
            cmdt.values = new List<Metadata.CustomMetadataValue>();

            Map<String, Object> fields = record.getPopulatedFieldsAsMap();
            for(String fieldName : fields.keySet()) {
                if(fieldName.endsWith('__c') && fields.get(fieldName) != null) {
                    cmdt.values.add(createCMDTValue(fieldName, fields.get(fieldName)));
                }
            }
            
            if(!cmdt.values.isEmpty()) {
                mdList.add(cmdt);
            }
        }

        if(!mdList.isEmpty()) {
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            for(Metadata.CustomMetadata md : mdList) {
                mdContainer.addMetadata(md);
            }
            
            if(!Test.isRunningTest()) {
                Metadata.Operations.enqueueDeployment(mdContainer, null);
            }
        }
    }

    private static Metadata.CustomMetadataValue createCMDTValue(String fieldName, Object value) {
        Metadata.CustomMetadataValue val = new Metadata.CustomMetadataValue();
        val.field = fieldName;
        val.value = value;
        return val;
    }
}