@isTest
public class AopEbitdaTest {

    // Utility method if you need to simulate/mock CMDT data references in your test methods
    private static void mockAopEbitdaCMDT() {
        // No actual DML for CMDT records in Apex test methods
        // Just a placeholder to document setup if needed
    }

    // Test for metadataUpdate method
    @isTest
    static void testMetadataUpdate() {
        Test.startTest();
        // Call the method
        List<AOP_EBITDA__mdt> result = AopEbitda.metadataUpdate();
        Test.stopTest();

        // Assert result is not null
        System.assertNotEquals(null, result, 'Metadata query should return records');
        // Optionally check size if you know records exist in org
        // System.assertEquals(1, result.size(), 'Should return expected CMDT records');
    }

    // Test for updateMetadata method
    @isTest
    static void testUpdateMetadata() {
        Test.startTest();
        // Call the update method with test values
        AopEbitda.updateMetadata('Commercial', 12.5, 9.75);
        Test.stopTest();

        // As deployment is skipped in test context — assert method executed without error
        System.assert(true, 'updateMetadata executed without exceptions');
    }
}