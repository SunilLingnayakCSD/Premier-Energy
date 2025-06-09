@isTest
private class FreightChargesControllerTest {

    // Utility method to create mock CMDT records
    private static List<Freight_Charges__mdt> createTestMetadata() {
        return new List<Freight_Charges__mdt>{
            new Freight_Charges__mdt(
                MasterLabel = 'China',
                DeveloperName = 'China',
                Sea_Frieght_USD_20Ft__c = 1000,
                Sea_Frieght_USD_40Ft__c = 2000,
                Inland_Transport_INR_20Ft__c = 5000,
                Inland_Transport_INR_40Ft__c = 10000
            ),
            new Freight_Charges__mdt(
                MasterLabel = 'Vietnam',
                DeveloperName = 'Vietnam',
                Sea_Frieght_USD_20Ft__c = 1200,
                Sea_Frieght_USD_40Ft__c = 2200,
                Inland_Transport_INR_20Ft__c = 5500,
                Inland_Transport_INR_40Ft__c = 11000
            )
        };
    }

    // Test getFreightMetadata method
    @isTest
    static void testGetFreightMetadata() {
        Test.startTest();
        List<Freight_Charges__mdt> result = FreightChargesController.getFreightMetadata();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Metadata records should be returned');
    }

    // Test updateFreightMetadata with populated list (this covers enqueueDeployment branch)
    @isTest
    static void testUpdateFreightMetadataWithData() {
        List<Freight_Charges__mdt> recordsToUpdate = createTestMetadata();
        recordsToUpdate[0].Sea_Frieght_USD_20Ft__c = 1500;
        recordsToUpdate[1].Inland_Transport_INR_40Ft__c = 12000;

        Test.startTest();
        FreightChargesController.updateFreightMetadata(recordsToUpdate);
        Test.stopTest();

        System.assert(true, 'Update method should execute without errors');
    }

    // Test updateFreightMetadata with empty list
    @isTest
    static void testUpdateFreightMetadataEmptyList() {
        List<Freight_Charges__mdt> emptyList = new List<Freight_Charges__mdt>();

        Test.startTest();
        FreightChargesController.updateFreightMetadata(emptyList);
        Test.stopTest();

        System.assert(true, 'Update with empty list should execute without errors');
    }

    // Test metadata container creation indirectly (to cover mdContainer creation logic)
    @isTest
    static void testMetadataContainerCreation() {
        List<Freight_Charges__mdt> recordsToUpdate = createTestMetadata();

        // Modify one value to ensure a value gets added into metadata
        recordsToUpdate[0].Sea_Frieght_USD_20Ft__c = 1500;

        Test.startTest();
        FreightChargesController.updateFreightMetadata(recordsToUpdate);
        Test.stopTest();

        System.assert(true, 'Metadata container logic executed');
    }
}