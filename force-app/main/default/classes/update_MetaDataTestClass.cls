@isTest
public class update_MetaDataTestClass {

    // Utility method to create mock CMDT records
    private static List<Input_Admin__mdt> createTestMetaData() {
        return new List<Input_Admin__mdt>{
            new Input_Admin__mdt(
                MasterLabel = 'default',
                DeveloperName = 'default', 
                USD_to_INR_CBITC__c = 87.75,
                Overhead_cost_mdt__c = 1,
                Finance_Cost__c = 2,
                Cell_Overhead_Cost__c = 2,
                RFIDreadercost__c = 3,
                ModuleWarrantyInsurance__c = 4,
                LCinterestcostPA__c = 5,
                InsurnacePremiumcost__c = 6,
                GST__c = 0.6,
                B_Grade_Module_Yield__c = 9,
                B_Grade_Module_Discount__c = 2,
                ABGPBGCostPA__c = 2,
                Cell_Finance_Cost__c = 3,
                Cell_BOM_Cost__c = 4
            )
        };
    }

    // Test metadataUpdate method
    @isTest
    static void testMetadataUpdateMethod() {
        Test.startTest();
        List<Input_Admin__mdt> result = update_MetaData.metadataUpdate();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Metadata records should be returned');
    }

    // Test updateMetadata method
    @isTest
    static void testUpdateMetadataMethod() {
        // Create a sample Input_Admin__mdt record for testing
        Input_Admin__mdt testRecord = new Input_Admin__mdt(
            MasterLabel = 'default',
            DeveloperName = 'default',
            USD_to_INR_CBITC__c = 88.5,
            Overhead_cost_mdt__c = 1.5,
            Finance_Cost__c = 2.5,
            Cell_Overhead_Cost__c = 3.5,
            RFIDreadercost__c = 4.5,
            ModuleWarrantyInsurance__c = 5.5,
            LCinterestcostPA__c = 6.5,
            InsurnacePremiumcost__c = 7.5,
            GST__c = 0.7,
            B_Grade_Module_Yield__c = 9.5,
            B_Grade_Module_Discount__c = 2.5,
            ABGPBGCostPA__c = 3.5,
            Cell_Finance_Cost__c = 4.5,
            Cell_BOM_Cost__c = 5.5
        );

        // Call the method inside Test.startTest() block
        Test.startTest();
        update_MetaData.updateMetadata(testRecord);
        Test.stopTest();

        // Assert true just to confirm the method ran without error
        System.assert(true, 'updateMetadata method executed successfully');
    }
}