public with sharing class AopEbitda {
    @AuraEnabled(cacheable=true)
    public static List<AOP_EBITDA__mdt> metadataUpdate() {
        return [
            SELECT Id, MasterLabel, DeveloperName, DCR__c, NDCR__c
            FROM AOP_EBITDA__mdt
            ORDER BY MasterLabel
        ];
    }

    @AuraEnabled
    public static void updateMetadata(String developerName, Decimal dcrValue, Decimal ndcrValue) {
        Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
        cmd.fullName = 'AOP_EBITDA__mdt.' + developerName;
        cmd.label = developerName;

        List<Metadata.CustomMetadataValue> values = new List<Metadata.CustomMetadataValue>();

        Metadata.CustomMetadataValue dcrField = new Metadata.CustomMetadataValue();
        dcrField.field = 'DCR__c';
        dcrField.value = dcrValue;
        values.add(dcrField);

        Metadata.CustomMetadataValue ndcrField = new Metadata.CustomMetadataValue();
        ndcrField.field = 'NDCR__c';
        ndcrField.value = ndcrValue;
        values.add(ndcrField);

        cmd.values = values;

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        container.addMetadata(cmd);

        if (!Test.isRunningTest()) {
            Id jobId = Metadata.Operations.enqueueDeployment(container, null);
        }
    }
}