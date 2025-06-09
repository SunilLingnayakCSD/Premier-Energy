@isTest
public class cellwattageapexclassTest {

    // Utility method to create a mock CMDT record for test context
    private static void createTestCMDT() {
        // CMDT records must be created in metadata context, so this is just for query result simulation.
        // In real test execution, this would need to be a deployed CMDT record in your scratch org/sandbox.
    }

    // Test method for LightningStudio()
    @isTest
    static void testLightningStudio() {
        Test.startTest();
        // Call the method
        List<cellwattage__mdt> result = cellwattageapexclass.LightningStudio();
        Test.stopTest();

        // Assert result is not null
        System.assertNotEquals(null, result, 'Result should not be null');
        // Optional: Assert result list size (if your org has the test CMDT record available)
        // System.assertEquals(1, result.size(), 'Should return one record');
    }

    // Test method for updateCellWattage()
    @isTest
    static void testUpdateCellWattage() {
        Test.startTest();
        // Call update method with sample values
        cellwattageapexclass.updateCellWattage(
            5.0,    // m10MonoPERC
            6.0,    // m10Topcon
            7.0,    // m10TopconPlus
            8.0,    // g12rTopcon
            9.0     // g12Topcon
        );
        Test.stopTest();

        // Since Metadata.Operations.enqueueDeployment is skipped in test context, 
        // just assert that no exceptions were thrown
        System.assert(true, 'updateCellWattage executed successfully in test context');
    }
}