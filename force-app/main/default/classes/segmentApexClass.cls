// segmentApexClass.apxc
public class segmentApexClass {
    
    @AuraEnabled(cacheable=true)
    public static List<Segment__mdt> metadataUpdate() {
        return [
            SELECT Id, MasterLabel, DeveloperName, 
                   DCR__c, NDCR__c
            FROM Segment__mdt
            ORDER BY MasterLabel
        ];
    }

    @AuraEnabled
    public static void updateMetadata(String developerName, Decimal dcrValue, Decimal ndcrValue) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'Segment__mdt.' + developerName;
        customMetadata.label = developerName;

        List<Metadata.CustomMetadataValue> values = new List<Metadata.CustomMetadataValue>();
        
        // DCR Field
        Metadata.CustomMetadataValue dcrField = new Metadata.CustomMetadataValue();
        dcrField.field = 'DCR__c';
        dcrField.value = dcrValue;
        values.add(dcrField);

        // NDCR Field
        Metadata.CustomMetadataValue ndcrField = new Metadata.CustomMetadataValue();
        ndcrField.field = 'NDCR__c';
        ndcrField.value = ndcrValue;
        values.add(ndcrField);

        customMetadata.values = values;

        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        
        if(!Test.isRunningTest()) {
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, null);
        }
    }
}